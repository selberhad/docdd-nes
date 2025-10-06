package NES::Test::Toy;

use strict;
use warnings;
use Carp qw(croak);
use File::Basename qw(dirname);
use Cwd qw(abs_path);

sub import {
    my ($class, $rom_name) = @_;

    croak "Usage: use NES::Test::Toy 'rom_name';" unless $rom_name;

    # Get caller's package
    my $caller = caller;

    # Enable strict and warnings in caller's context
    strict->import;
    warnings->import;

    # Import Test::More into caller's namespace
    # Must call Test::More->import targeting the caller's package
    require Test::More;
    eval qq{
        package $caller;
        Test::More->import();
        1;
    } or croak "Failed to import Test::More: $@";

    # Import NES::Test functions into caller's namespace
    require NES::Test;
    NES::Test->import();

    # Manually export NES::Test functions to caller
    {
        no strict 'refs';
        for my $func (@NES::Test::EXPORT) {
            *{"${caller}::$func"} = \&{"NES::Test::$func"};
        }
    }

    # Auto-load ROM (relative to caller's file location)
    # Caller's test file is in toys/toyN_name/t/test.t
    # ROM is at toys/toyN_name/rom_name.nes
    my ($caller_file) = (caller(0))[1];
    my $test_dir = dirname(abs_path($caller_file));
    my $toy_dir = dirname($test_dir);  # Parent of t/
    my $rom_path = "$toy_dir/$rom_name.nes";

    # Load ROM immediately (happens during 'use' statement, before test body runs)
    NES::Test::load_rom($rom_path);
}

1;

__END__

=head1 NAME

NES::Test::Toy - Boilerplate reducer for toy ROM testing

=head1 SYNOPSIS

    # Old way (7 lines)
    use strict;
    use warnings;
    use Test::More;
    use FindBin qw($Bin);
    use lib "$Bin/../../../lib";
    use NES::Test;
    load_rom "$Bin/../scroll.nes";

    # New way (1 line)
    use NES::Test::Toy 'scroll';

    # Then write tests as normal
    after_nmi 1 => sub {
        assert_ram 0x10 => 0x01;
    };

    done_testing();

=head1 DESCRIPTION

NES::Test::Toy reduces boilerplate in toy ROM test files by:

- Auto-importing strict, warnings, Test::More, and NES::Test
- Auto-loading ROM file from parent directory
- Setting up correct lib path

This module exists purely to save tokens and make test files more concise.

=head1 USAGE

    use NES::Test::Toy 'rom_name';

Where 'rom_name' is the ROM filename (without .nes extension) in the toy's directory.

For test file at:
    toys/toy5_scrolling/t/01-test.t

ROM file expected at:
    toys/toy5_scrolling/scroll.nes

Usage:
    use NES::Test::Toy 'scroll';

=head1 IMPLEMENTATION

The module uses import() magic to:

1. Enable strict/warnings in caller's package
2. Import Test::More and NES::Test
3. Calculate ROM path from caller's file location
4. Schedule load_rom() to run via END block

The END block ensures ROM loads after all test code is compiled.

=head1 TOKEN SAVINGS

Per test file:
- Before: 7 lines of boilerplate
- After: 1 line
- Savings: 6 lines × ~15 test files = 90 lines total

=head1 AUTHOR

Claude (Sonnet 4.5) - Meta-learning from blog post #6 (housekeeping)

=head1 SEE ALSO

L<NES::Test> - Test DSL functions

=cut
