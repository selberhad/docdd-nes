package NES::Test;

use strict;
use warnings;
use Test::More;
use JSON::PP qw(decode_json);
use Carp qw(croak);
use Exporter 'import';

our @EXPORT = qw(
    load_rom
    at_frame
    press_button
    run_frames
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
);

our $VERSION = '0.01';

# Module state
my $current_rom;
my $current_frame = 0;
my $jsnes_wrapper = 'toys/debug/1_jsnes_wrapper/nes-headless.js';
my @input_sequence;  # Track controller inputs
my $emulator_state;  # Cached state from last jsnes call

sub load_rom {
    my ($rom_path) = @_;

    croak "ROM path required" unless $rom_path;
    croak "ROM file not found: $rom_path" unless -f $rom_path;

    $current_rom = $rom_path;
    $current_frame = 0;
    @input_sequence = ();
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
        _run_to_frame($target_frame);
    }

    # Fetch current state from jsnes
    _update_state();

    # Run assertions
    if (ref $assertions eq 'CODE') {
        $assertions->();
    }
}

sub press_button {
    my ($buttons) = @_;

    croak "No ROM loaded" unless $current_rom;

    # Parse button string (e.g., 'A', 'A+B', 'Start')
    push @input_sequence, $buttons;

    # Advance one frame with this input
    $current_frame++;
    _update_state();
}

sub run_frames {
    my ($count) = @_;

    croak "No ROM loaded" unless $current_rom;

    $current_frame += $count;
    # Don't update state (lazy evaluation - only on assertions)
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

    my $actual = $emulator_state->{cpu}{a};
    is($actual, $expected, sprintf("CPU A = 0x%02X", $expected));
}

sub assert_cpu_x {
    my ($expected) = @_;

    my $actual = $emulator_state->{cpu}{x};
    is($actual, $expected, sprintf("CPU X = 0x%02X", $expected));
}

sub assert_cpu_y {
    my ($expected) = @_;

    my $actual = $emulator_state->{cpu}{y};
    is($actual, $expected, sprintf("CPU Y = 0x%02X", $expected));
}

sub assert_cpu_sp {
    my ($expected) = @_;

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

    my $actual = $emulator_state->{ppu}{ctrl};
    is($actual, $expected, sprintf("PPU CTRL = 0x%02X", $expected));
}

sub assert_ppu_mask {
    my ($expected) = @_;

    my $actual = $emulator_state->{ppu}{mask};
    is($actual, $expected, sprintf("PPU MASK = 0x%02X", $expected));
}

sub assert_ppu_status {
    my ($expected) = @_;

    my $actual = $emulator_state->{ppu}{status};
    is($actual, $expected, sprintf("PPU STATUS = 0x%02X", $expected));
}

# Internal helpers

sub _run_to_frame {
    my ($target_frame) = @_;

    # For now, just update current frame counter
    # Actual jsnes execution happens in _update_state
    $current_frame = $target_frame;
}

sub _update_state {
    # Call jsnes wrapper to get current state
    my $cmd = "node $jsnes_wrapper $current_rom --frames=$current_frame";

    # TODO: Handle controller input sequence
    # Need to pass input to jsnes wrapper (not yet implemented)

    my $json_output = `$cmd 2>&1`;

    if ($? != 0) {
        croak "jsnes wrapper failed: $json_output";
    }

    $emulator_state = decode_json($json_output);
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

=head1 DESCRIPTION

NES::Test provides a Perl DSL for writing automated tests for NES ROMs.
Phase 1 uses jsnes backend for headless execution.

=head1 PHASE 1 LIMITATIONS

- No cycle counting (jsnes doesn't expose it)
- No frame buffer access (not yet implemented)
- Controller input not yet supported (TODO)
- Nametable/tile assertions not implemented

=head1 FUNCTIONS

=head2 load_rom($path)

Load NES ROM file for testing.

=head2 at_frame($frame, $coderef)

Advance emulator to specified frame and run assertions.

=head2 press_button($buttons)

Press controller buttons and advance one frame.
Examples: 'A', 'A+B', 'Start', 'Up+A'

=head2 run_frames($count)

Advance N frames without assertions (lazy evaluation).

=head2 assert_ram($addr, $expected)

Assert memory value at address. $expected can be value or coderef.

=head2 assert_cpu_pc($expected), assert_cpu_a($expected), etc.

Assert CPU register values.

=head2 assert_sprite($num, %attrs)

Assert sprite OAM attributes (y, tile, attr, x).

=head2 assert_ppu_ctrl($expected), assert_ppu_mask($expected), etc.

Assert PPU register values.

=head1 AUTHOR

Claude (Sonnet 4.5) with human guidance

=head1 SEE ALSO

TESTING.md - Complete testing strategy
toys/PLAN.md - Toy development plan

=cut
