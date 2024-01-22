package Help;

use strict;
use warnings;
use feature qw(say);
use Pod::Usage;
use Getopt::Long qw(:config posix_default);
use Data::Dumper;

=head1 NAME

    BEACON::Help - Help file for Beacon script

=head1 SYNOPSIS

  use BEACON::Help

=head1 DESCRIPTION


=head1 AUTHOR

Written by Manuel Rueda, PhD

=cut

=head1 METHODS

=cut

=head2 usage

    About   : Subroutine that parses the arguments
    Usage   :            
    Args    : 

=cut

sub usage {

    my $version = shift;

    # Help if no args
    pod2usage( -exitval => 1, -verbose => 1 ) unless @ARGV;

    # Parse things related to info
    info( $version, lc( $ARGV[0] ) );

    # 1st arg will become 'mode'
    my %arg  = ( mode => shift(@ARGV) );
    my %func = (
        full    => \&vcf_and_full,
        vcf     => \&vcf_and_full,
        mongodb => \&mongodb
    );

    pod2usage(
        -exitval => 1,
        -verbose => 1,
        -message => "Unknown mode $arg{mode}"
    ) unless exists $func{ $arg{mode} };

    # Execute function if mode is present
    if ( $arg{mode} eq 'full' ) {
        $func{ $arg{mode} }->('full');
    }
    else {
        &{ $func{ $arg{mode} } };
    }
}

sub info {

    my ( $version, $arg ) = @_;
    if ( $arg eq '-h' || $arg eq '-help' ) {
        pod2usage( -exitval => 0, -verbose => 1 );
    }
    elsif ( $arg eq '-man' ) {
        pod2usage( -exitval => 0, -verbose => 2 );
    }
    elsif ( $arg eq '-v' ) {
        say "$version" and exit;
    }
    return 1;
}

sub vcf_and_full {

    my $mode = shift;
    my %arg  = ( debug => 0, mode => $mode // 'vcf' );
    GetOptions(
        'debug=i'     => \$arg{debug},         # numeric (integer)
        'verbose'     => \$arg{verbose},       # flag
        'no-color|nc' => \$arg{nocolor},       # flag
        'n=i'         => \$arg{ncpu},          # numeric (integer)
        'param|p=s'   => \$arg{paramfile},     # string
        'config|c=s'  => \$arg{configfile},    # string
        'input|i=s'   => \$arg{inputfile}      # string
    ) or pod2usage( -exitval => 1, -verbose => 1 );
    pod2usage(
        -exitval => 1,
        -verbose => 1,
        -message => 'Modes vcf|full require an input vcf file'
    ) unless ( $arg{inputfile} );
    usage_params( \%arg );

    # Turning color off if argument <--no-color>
    $ENV{'ANSI_COLORS_DISABLED'} = 1 if $arg{nocolor};

    #print Dumper \%arg;
    return wantarray ? %arg : \%arg;
}

sub mongodb {

    my %arg = ( debug => 0, mode => 'mongodb' );
    GetOptions(
        'debug=i'     => \$arg{debug},        # numeric (integer)
        'verbose'     => \$arg{verbose},      # flag
        'no-color|nc' => \$arg{nocolor},      # flag
        'n=i'         => \$arg{ncpu},         # numeric (integer)
        'param|p=s'   => \$arg{paramfile},    # string
        'config|c=s'  => \$arg{configfile}    # string

    ) or pod2usage( -exitval => 1, -verbose => 1 );
    usage_params( \%arg );

    # Turning color off if argument <--no-color>
    $ENV{'ANSI_COLORS_DISABLED'} = 1 if $arg{nocolor};

    #print Dumper \%arg;
    return wantarray ? %arg : \%arg;
}

sub usage_params {

    my $arg = shift;
    pod2usage(
        -exitval => 1,
        -verbose => 1,
        -message => 'Option --c requires a config file'
    ) if ( $arg->{configfile} && !-s $arg->{configfile} );
    pod2usage(
        -exitval => 1,
        -verbose => 1,
        -message => 'Option --p requires a param file'
    ) if ( $arg->{paramfile} && !-s $arg->{paramfile} );
    pod2usage(
        -exitval => 1,
        -verbose => 1,
        -message => 'Option --n requires a positive integer'
    ) if ( $arg->{ncpu} && $arg->{ncpu} <= 0 );    # Must be positive integer
    return 1;
}

package GoodBye;

sub new {
    my $class = shift;
    return bless {}, $class;
}

=head2 goodbye

    About   : Well, the name says it all :-)
    Usage   :         
    Args    : 

=cut

sub say_goodbye {

    my @words = ( <<"EOF" =~ m/^\s*(.+)/gm );
      Aavjo
      Abar Dekha-Hobe
      Adeus
      Adios
      Aloha
      Alvida
      Ambera
      Annyong hi Kashipshio
      Arrivederci
      Auf Wiedersehen
      Au Revoir
      Ba'adan Mibinamet
      Dasvidania
      Donadagohvi
      Do Pobatchenya
      Do Widzenia
      Eyvallah
      Farvel
      Ha Det
      Hamba Kahle
      Hooroo
      Hwyl
      Kan Ga Waanaa
      Khuda Hafiz
      Kwa Heri
      La Revedere
      Le Hitra Ot
      Ma'as Salaam
      Mikonan
      Na-Shledanou
      Ni Sa Moce
      Paalam
      Rhonanai
      Sawatdi
      Sayonara
      Selavu
      Shalom
      Totsiens
      Tot Ziens
      Ukudigada
      Vale
      Zai Geen
      Zai Jian
      Zay Gesunt
EOF
    my $random_word = $words[ rand @words ];
    return $random_word;
}
1;
