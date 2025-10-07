package NES::Test;

use strict;
use warnings;
use Test::More;
use JSON::PP qw(decode_json encode_json);
use Carp qw(croak);
use IPC::Open2;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use Exporter 'import';

our @EXPORT = qw(
    load_rom
    at_frame
    after_nmi
    press_button
    release_button
    run_frames
    set_verbosity
    assert_ram
    assert_cpu_pc
    assert_cpu_a
    assert_cpu_x
    assert_cpu_y
    assert_cpu_sp
    assert_sprite
    assert_ppu_ctrl
    assert_ppu_mask
    assert_ppu_status
    assert_palette
    assert_nmi_counter
    assert_audio_playing
    assert_silence
    assert_frequency_near
);

our $VERSION = '0.01';

# Module state
my $harness_pid;
my $harness_in;
my $harness_out;
my $current_rom;
my $current_frame = 0;
my $emulator_state;

# Button mapping for parsing button strings
my %BUTTON_MAP = (
    'A' => 'A',
    'B' => 'B',
    'SELECT' => 'SELECT',
    'START' => 'START',
    'UP' => 'UP',
    'DOWN' => 'DOWN',
    'LEFT' => 'LEFT',
    'RIGHT' => 'RIGHT'
);

sub load_rom {
    my ($rom_path) = @_;

    croak "ROM path required" unless $rom_path;
    croak "ROM file not found: $rom_path" unless -f $rom_path;

    # Make ROM path absolute
    $rom_path = abs_path($rom_path);

    # Start harness if not running
    _start_harness() unless $harness_pid;

    # Send loadRom command
    my $response = _send_command('loadRom', { path => $rom_path });

    if ($response->{status} ne 'ok') {
        croak "Failed to load ROM: $response->{message}";
    }

    $current_rom = $rom_path;
    $current_frame = 0;
    $emulator_state = undef;

    note "Loaded ROM: $rom_path";
}

sub at_frame {
    my ($target_frame, $assertions) = @_;

    croak "No ROM loaded (call load_rom first)" unless $current_rom;
    croak "Target frame must be >= current frame ($current_frame)"
        if $target_frame < $current_frame;

    # Advance emulator to target frame
    if ($target_frame > $current_frame) {
        my $frames_to_advance = $target_frame - $current_frame;
        my $response = _send_command('frame', { count => $frames_to_advance });

        if ($response->{status} ne 'ok') {
            croak "Failed to advance frames: $response->{message}";
        }

        $current_frame = $target_frame;
    }

    # Fetch current state
    _update_state();

    # Run assertions (support CODE ref or HASH ref)
    if (ref $assertions eq 'CODE') {
        $assertions->();
    } elsif (ref $assertions eq 'HASH') {
        # Hash syntax: { ram => { addr => val, ... }, sprite => [...], ... }
        if (exists $assertions->{ram}) {
            for my $addr (keys %{$assertions->{ram}}) {
                assert_ram($addr, $assertions->{ram}{$addr});
            }
        }
    }
}

sub after_nmi {
    my ($nmi_count, $assertions) = @_;

    croak "NMI count must be positive" unless $nmi_count > 0;

    # NMI fires at frame 4, 5, 6, ... (3 + N pattern from toy4/5)
    # after_nmi(1) => frame 4 (first NMI has fired)
    # after_nmi(2) => frame 5 (second NMI has fired)
    # Formula: frame = 3 + nmi_count
    my $frame = 3 + $nmi_count;

    at_frame($frame, $assertions);
}

sub press_button {
    my ($buttons) = @_;

    croak "No ROM loaded" unless $current_rom;

    # Parse button string (e.g., 'A', 'A+B', 'Up+A')
    my @button_names = split(/\+/, uc($buttons));

    # Press all buttons
    for my $btn (@button_names) {
        $btn =~ s/^\s+|\s+$//g;  # trim whitespace

        unless (exists $BUTTON_MAP{$btn}) {
            croak "Unknown button: $btn (valid: " . join(', ', keys %BUTTON_MAP) . ")";
        }

        my $response = _send_command('buttonDown', {
            controller => 1,
            button => $BUTTON_MAP{$btn}
        });

        if ($response->{status} ne 'ok') {
            croak "Failed to press button $btn: $response->{message}";
        }
    }

    # Advance one frame with buttons held
    $current_frame++;
    my $response = _send_command('frame', { count => 1 });

    if ($response->{status} ne 'ok') {
        croak "Failed to advance frame: $response->{message}";
    }

    # Release all buttons
    for my $btn (@button_names) {
        _send_command('buttonUp', {
            controller => 1,
            button => $BUTTON_MAP{$btn}
        });
    }

    # Update state after button press
    _update_state();
}

sub release_button {
    my ($buttons) = @_;

    croak "No ROM loaded" unless $current_rom;

    my @button_names = split(/\+/, uc($buttons));

    for my $btn (@button_names) {
        $btn =~ s/^\s+|\s+$//g;

        unless (exists $BUTTON_MAP{$btn}) {
            croak "Unknown button: $btn";
        }

        my $response = _send_command('buttonUp', {
            controller => 1,
            button => $BUTTON_MAP{$btn}
        });

        if ($response->{status} ne 'ok') {
            croak "Failed to release button $btn: $response->{message}";
        }
    }
}

sub run_frames {
    my ($count) = @_;

    croak "No ROM loaded" unless $current_rom;

    $current_frame += $count;

    my $response = _send_command('frame', { count => $count });

    if ($response->{status} ne 'ok') {
        croak "Failed to run frames: $response->{message}";
    }

    # Don't update state (lazy evaluation)
}

sub set_verbosity {
    my ($level) = @_;

    croak "No ROM loaded (call load_rom first)" unless $current_rom;

    my $response = _send_command('setVerbosity', { level => $level });

    if ($response->{status} ne 'ok') {
        croak "Failed to set verbosity: $response->{message}";
    }

    note "Verbosity set to $level";
}

# Assertion helpers

sub assert_ram {
    my ($addr, $expected) = @_;

    croak "No emulator state (call at_frame first)" unless $emulator_state;

    my $actual = $emulator_state->{cpu}{mem}[$addr];

    if (ref $expected eq 'CODE') {
        # Allow code ref for flexible assertions
        local $_ = $actual;
        ok($expected->(), sprintf("RAM[0x%04X] matches condition", $addr));
    } else {
        is($actual, $expected, sprintf("RAM[0x%04X] = 0x%02X", $addr, $expected));
    }
}

sub assert_cpu_pc {
    my ($expected) = @_;

    croak "No emulator state" unless $emulator_state;

    my $actual = $emulator_state->{cpu}{pc};
    is($actual, $expected, sprintf("CPU PC = 0x%04X", $expected));
}

sub assert_cpu_a {
    my ($expected) = @_;

    croak "No emulator state" unless $emulator_state;

    my $actual = $emulator_state->{cpu}{a};
    is($actual, $expected, sprintf("CPU A = 0x%02X", $expected));
}

sub assert_cpu_x {
    my ($expected) = @_;

    croak "No emulator state" unless $emulator_state;

    my $actual = $emulator_state->{cpu}{x};
    is($actual, $expected, sprintf("CPU X = 0x%02X", $expected));
}

sub assert_cpu_y {
    my ($expected) = @_;

    croak "No emulator state" unless $emulator_state;

    my $actual = $emulator_state->{cpu}{y};
    is($actual, $expected, sprintf("CPU Y = 0x%02X", $expected));
}

sub assert_cpu_sp {
    my ($expected) = @_;

    croak "No emulator state" unless $emulator_state;

    my $actual = $emulator_state->{cpu}{sp};
    is($actual, $expected, sprintf("CPU SP = 0x%02X", $expected));
}

sub assert_sprite {
    my ($sprite_num, %attrs) = @_;

    croak "No emulator state" unless $emulator_state;

    my $base = $sprite_num * 4;  # Each sprite = 4 bytes in OAM
    my $oam = $emulator_state->{oam};

    if (exists $attrs{y}) {
        my $actual_y = $oam->[$base];
        is($actual_y, $attrs{y}, sprintf("Sprite %d Y = %d", $sprite_num, $attrs{y}));
    }

    if (exists $attrs{tile}) {
        my $actual_tile = $oam->[$base + 1];
        is($actual_tile, $attrs{tile}, sprintf("Sprite %d tile = 0x%02X", $sprite_num, $attrs{tile}));
    }

    if (exists $attrs{attr}) {
        my $actual_attr = $oam->[$base + 2];
        is($actual_attr, $attrs{attr}, sprintf("Sprite %d attr = 0x%02X", $sprite_num, $attrs{attr}));
    }

    if (exists $attrs{x}) {
        my $actual_x = $oam->[$base + 3];
        is($actual_x, $attrs{x}, sprintf("Sprite %d X = %d", $sprite_num, $attrs{x}));
    }
}

sub assert_ppu_ctrl {
    my ($expected) = @_;

    croak "No emulator state" unless $emulator_state;

    my $actual = $emulator_state->{ppu}{ctrl};
    is($actual, $expected, sprintf("PPU CTRL = 0x%02X", $expected));
}

sub assert_ppu_mask {
    my ($expected) = @_;

    croak "No emulator state" unless $emulator_state;

    my $actual = $emulator_state->{ppu}{mask};
    is($actual, $expected, sprintf("PPU MASK = 0x%02X", $expected));
}

sub assert_ppu_status {
    my ($expected) = @_;

    croak "No emulator state" unless $emulator_state;

    my $actual = $emulator_state->{ppu}{status};
    is($actual, $expected, sprintf("PPU STATUS = 0x%02X", $expected));
}

sub assert_palette {
    my ($addr, $expected) = @_;

    croak "No emulator state" unless $emulator_state;

    # Convert PPU address to palette array index
    # $3F00-$3F1F maps to indices 0-31
    # $3F20-$3FFF mirrors to 0-31 (wrap using & 0x1F)
    my $index = ($addr - 0x3F00) & 0x1F;
    my $actual = $emulator_state->{palette}->[$index];  # Use -> for array ref

    if (ref $expected eq 'CODE') {
        # Allow code ref for flexible assertions
        local $_ = $actual;
        ok($expected->(), sprintf("Palette[0x%04X] matches condition", $addr));
    } else {
        is($actual, $expected, sprintf("Palette[0x%04X] = 0x%02X", $addr, $expected));
    }
}

sub assert_nmi_counter {
    my ($addr, %opts) = @_;

    croak "at_nmis parameter required" unless exists $opts{at_nmis};
    croak "at_nmis must be array ref" unless ref $opts{at_nmis} eq 'ARRAY';

    my @nmi_counts = @{$opts{at_nmis}};

    for my $nmi_count (@nmi_counts) {
        after_nmi $nmi_count => sub {
            assert_ram($addr, $nmi_count);
        };
    }
}

# Audio assertions

sub assert_audio_playing {
    croak "No ROM loaded" unless $current_rom;

    my $wav_path = _capture_audio(10);
    my $analysis = _analyze_audio($wav_path);

    ok($analysis->{is_playing}, sprintf("Audio is playing (RMS=%.4f)", $analysis->{rms}));
}

sub assert_silence {
    croak "No ROM loaded" unless $current_rom;

    my $wav_path = _capture_audio(10);
    my $analysis = _analyze_audio($wav_path);

    ok($analysis->{is_silence}, sprintf("Audio is silent (RMS=%.4f)", $analysis->{rms}));
}

sub assert_frequency_near {
    my ($target_hz, $tolerance) = @_;
    $tolerance //= 5;

    croak "No ROM loaded" unless $current_rom;

    my $wav_path = _capture_audio(10);
    my $analysis = _analyze_audio($wav_path);

    my $actual_freq = $analysis->{frequency};
    my $diff = abs($actual_freq - $target_hz);

    ok($diff <= $tolerance,
       sprintf("Frequency %.1f Hz within %d Hz of %d Hz (diff=%.1f)",
               $actual_freq, $tolerance, $target_hz, $diff));
}

sub _capture_audio {
    my ($frames) = @_;
    $frames //= 10;

    my $response = _send_command('captureAudio', { frames => $frames });

    if ($response->{status} ne 'ok') {
        croak "Failed to capture audio: $response->{message}";
    }

    # Decode base64 WAV and write to temp file
    require MIME::Base64;
    my $wav_data = MIME::Base64::decode_base64($response->{wav});
    my $temp_path = "/tmp/nes_audio_$$.wav";

    open my $fh, '>', $temp_path or croak "Failed to write $temp_path: $!";
    binmode $fh;
    print $fh $wav_data;
    close $fh;

    return $temp_path;
}

sub _analyze_audio {
    my ($wav_path) = @_;

    # Find analyze-audio.py script
    my $module_dir = dirname(abs_path(__FILE__));
    my $analyze_script = "$module_dir/../../tools/analyze-audio.py";

    unless (-f $analyze_script) {
        croak "Audio analysis script not found: $analyze_script";
    }

    # Run Python analysis
    my $json_output = `python3 $analyze_script $wav_path 2>&1`;
    my $exit_code = $? >> 8;

    if ($exit_code != 0) {
        croak "Audio analysis failed: $json_output";
    }

    my $analysis = decode_json($json_output);

    if (exists $analysis->{error}) {
        croak "Audio analysis error: $analysis->{error}";
    }

    return $analysis;
}

# Internal helpers

sub _start_harness {
    # Find harness script (relative to this module)
    my $module_dir = dirname(abs_path(__FILE__));
    my $harness_script = "$module_dir/../nes-test-harness.js";

    unless (-f $harness_script) {
        croak "Test harness not found: $harness_script";
    }

    # Start Node.js process
    $harness_pid = open2($harness_out, $harness_in, 'node', $harness_script)
        or croak "Failed to start test harness: $!";

    # Wait for ready signal
    my $ready_line = <$harness_out>;
    my $ready = decode_json($ready_line);

    unless ($ready->{status} eq 'ready') {
        croak "Test harness failed to start: $ready->{message}";
    }

    note "Test harness started (PID: $harness_pid)";

    # Register cleanup handler
    $SIG{__DIE__} = \&_cleanup_harness;
}

sub _send_command {
    my ($cmd, $args) = @_;

    $args ||= {};

    my $command = {
        cmd => $cmd,
        args => $args
    };

    my $json = encode_json($command);

    # Send command
    print $harness_in "$json\n";
    $harness_in->flush();

    # Read response
    my $response_line = <$harness_out>;
    my $response = decode_json($response_line);

    return $response;
}

sub _update_state {
    my $response = _send_command('getState');

    if ($response->{status} ne 'ok') {
        croak "Failed to get state: $response->{message}";
    }

    $emulator_state = $response->{data};

    # Debug: Check if palette data exists
    if ($ENV{DEBUG}) {
        my $pal = $emulator_state->{palette};
        my $pal_len = $pal ? scalar(@{$pal}) : 0;
        if ($pal_len > 0) {
            warn "[DEBUG-PERL] palette array length: $pal_len, palette[0]=" . (defined $pal->[0] ? $pal->[0] : 'undef') . "\n";
        }
    }
}

sub _cleanup_harness {
    return unless $harness_pid;

    # Send quit command
    eval {
        _send_command('quit');
    };

    # Close handles
    close $harness_in if $harness_in;
    close $harness_out if $harness_out;

    # Kill process if still running
    kill 'TERM', $harness_pid;
    waitpid($harness_pid, 0);

    $harness_pid = undef;
}

END {
    _cleanup_harness();
}

1;

__END__

=head1 NAME

NES::Test - Test DSL for NES ROM validation (Phase 1)

=head1 SYNOPSIS

    use NES::Test;

    load_rom "game.nes";

    at_frame 0 => sub {
        assert_cpu_pc 0x8000;
    };

    press_button 'A';

    at_frame 1 => sub {
        assert_ram 0x00 => 1;
        assert_sprite 0, y => 100;
    };

    # Multiple buttons
    press_button 'A+B';
    press_button 'Up+A';

=head1 DESCRIPTION

NES::Test provides a Perl DSL for writing automated tests for NES ROMs.
Phase 1 uses jsnes backend with persistent Node.js process.

=head1 ARCHITECTURE

- Persistent Node.js process running nes-test-harness.js
- JSON command protocol via stdin/stdout
- jsnes emulator for execution
- Test::More for assertions (TAP output)

=head1 PHASE 1 CAPABILITIES

- State assertions: CPU registers, RAM, OAM sprites, PPU registers
- Frame control: Advance to specific frame, step N frames
- Controller input: Press/release buttons (A, B, Start, Select, D-pad)
- Lazy evaluation: Only fetches state when assertions run

=head1 PHASE 1 LIMITATIONS

- No cycle counting (jsnes doesn't expose it)
- No frame buffer access (not yet implemented)
- No nametable/tile assertions (need VRAM access)

=head1 FUNCTIONS

=head2 load_rom($path)

Load NES ROM file for testing. Starts persistent test harness.

=head2 at_frame($frame, $coderef_or_hashref)

Advance emulator to specified frame and run assertions.

Supports code ref or hash ref syntax:

    at_frame 10 => sub {
        assert_ram 0x10 => 0x42;
    };

    at_frame 10 => {
        ram => { 0x10 => 0x42, 0x11 => 0x00 }
    };

=head2 after_nmi($nmi_count, $coderef_or_hashref)

Advance to frame where Nth NMI has fired and run assertions.

Automatically calculates frame from NMI count (frame = 3 + N).
First NMI fires at frame 4 due to init sequence (2 vblank waits + NMI enable).

    after_nmi 1 => sub {         # Frame 4 - first NMI
        assert_ram 0x10 => 0x01;
    };

    after_nmi 10 => {            # Frame 13 - 10th NMI
        ram => { 0x10 => 0x0A }
    };

=head2 press_button($buttons)

Press controller buttons and advance one frame.
Examples: 'A', 'A+B', 'Start', 'Up+A'

=head2 release_button($buttons)

Release controller buttons (without advancing frame).

=head2 run_frames($count)

Advance N frames without assertions (lazy evaluation).

=head2 assert_ram($addr, $expected)

Assert memory value at address. $expected can be value or coderef.

    assert_ram 0x00 => 42;
    assert_ram 0x00 => { $_ > 0 };  # Flexible condition

=head2 assert_cpu_pc($expected), assert_cpu_a($expected), etc.

Assert CPU register values.

=head2 assert_sprite($num, %attrs)

Assert sprite OAM attributes (y, tile, attr, x).

    assert_sprite 0, y => 100, x => 50;
    assert_sprite 1, tile => 0x42;

=head2 assert_ppu_ctrl($expected), assert_ppu_mask($expected), etc.

Assert PPU register values.

=head2 assert_nmi_counter($addr, at_nmis => \@counts)

Assert that memory address increments with each NMI (common pattern).

    # Assert RAM[0x10] increments per NMI, sample at NMI counts 1, 2, 10, 64
    assert_nmi_counter 0x10, at_nmis => [1, 2, 10, 64];

Generates multiple assertions automatically (1 per NMI count in list).
Equivalent to:

    after_nmi 1 => sub { assert_ram 0x10 => 1 };
    after_nmi 2 => sub { assert_ram 0x10 => 2 };
    after_nmi 10 => sub { assert_ram 0x10 => 10 };
    after_nmi 64 => sub { assert_ram 0x10 => 64 };

=head1 IMPLEMENTATION NOTES

- Test harness is automatically started on first load_rom
- Process is cleaned up on exit (END block + signal handler)
- All button names are case-insensitive
- Frame advancement is cumulative (at_frame 10 then at_frame 20 advances 10 frames total)

=head1 AUTHOR

Claude (Sonnet 4.5) with human guidance

=head1 SEE ALSO

TESTING.md - Complete testing strategy
toys/PLAN.md - Toy development plan
lib/nes-test-harness.js - Node.js backend

=cut
