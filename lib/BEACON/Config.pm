package Config;

use strict;
use warnings;
use autodie;
use feature qw(say);
use List::Util qw(any);
use Sys::Hostname;
use File::Spec::Functions qw(catdir catfile updir);
use Data::Dumper;
use YAML::XS qw(LoadFile DumpFile);

#$YAML::XS::QuoteNumericStrings = 0;

=head1 NAME

    BEACON::Config - Package for Config subroutines

=head1 SYNOPSIS

  use BEACON::Config

=head1 DESCRIPTION


=head1 AUTHOR

Written by Manuel Rueda, PhD

=cut

=head1 METHODS

=cut

=head2 read_config_file

    About   : Subroutine that reads the configuration file
    Usage   :            
    Args    :  

=cut

sub read_config_file {

    my $config_file = shift;

    # NGS-utils will be stored in a hash
    my $NGSutils_dir = '/media/mrueda/4TBT/NGSutils';
    my %NGSutils     = (
        snpeff   => catfile( $NGSutils_dir, 'snpEff/snpEff.jar' ),
        snpsift  => catfile( $NGSutils_dir, 'snpEff/SnpSift.jar' ),
        bcftools => catfile( $NGSutils_dir, 'bcftools-1.15.1/bcftools' )
    );

    # Mongo-DB
    # Database tools
    my $mongodb_db_tools_dir =
'/media/mrueda/4TBT/Soft/mongodb-database-tools-ubuntu2004-x86_64-100.5.1/bin/';
    my %mongodb_db_tools = (
        mongostat   => catfile( $mongodb_db_tools_dir, 'mongostat' ),
        mongoimport => catfile( $mongodb_db_tools_dir, 'mongoimport' ),
        mongoexport => catfile( $mongodb_db_tools_dir, 'mongoexport' )
    );

    # Mongo shell
    my $mongosh = '/usr/bin/mongosh';

    # Login URI
    my $mongodb_uri =
      'mongodb://root:example@127.0.0.1:27017/beacon?authSource=admin';

    # Default values
    my $root_dir = catdir( $main::Bin, File::Spec->updir );
    my $RAM         = '4G';
    my $db_dir      = '/media/mrueda/4TBT/Databases';
    my $genomes_dir = catdir( $db_dir, 'genomes' );
    my $snpeff_dir  = catdir( $db_dir, 'snpeff/v5.0' );
    my $tmpdir      = '/media/mrueda/4TBT/tmp';
    my $browser_dir = catdir( $root_dir, 'browser' );
    my $panel_dir   = catdir( $browser_dir, 'data' );

    # Load "databases" in 2D-hash (w/ autovivification) to simplify nomenclature
    my %data = ();

    # GRCh37/hg19, GRCh38/hg38 and hs37
    my @assemblies = qw(hg19 hg38 hs37);
    $data{hg19}{fasta} = catfile( $genomes_dir, 'ucsc.hg19.fasta.gz' );
    $data{hg38}{fasta} = catfile( $genomes_dir, 'hg38.fa.gz' );
    $data{hs37}{fasta} = catfile( $genomes_dir, 'hs37d5.fa.gz' );

    for my $ref (@assemblies) {
        my $ref_tmp = $ref eq 'hs37' ? 'hg19' : $ref; # hs37 shares files with hg19
        $data{$ref}{cosmic} =
          "$snpeff_dir/$ref_tmp/CosmicCodingMuts.normal.$ref_tmp.vcf.gz";
        $data{$ref}{dbnsfp4} =
          "$snpeff_dir/$ref_tmp/dbNSFP4.1a_$ref_tmp.txt.gz";
        $data{$ref}{clinvar} = "$snpeff_dir/$ref_tmp/clinvar_20211218.vcf.gz";
    }

    # We load %config with the default values
    my %config = (
        mem         => $RAM,
        bcftools    => $NGSutils{bcftools},
        snpeff      => $NGSutils{snpeff},
        snpsift     => $NGSutils{snpsift},
        hg19cosmic  => $data{hg19}{cosmic},
        hg19clinvar => $data{hg19}{clinvar},
        hg19dbnsfp  => $data{hg19}{dbnsfp4},
        hg19fasta   => $data{hg19}{fasta},
        hg38cosmic  => $data{hg38}{cosmic},
        hg38clinvar => $data{hg38}{clinvar},
        hg38dbnsfp  => $data{hg38}{dbnsfp4},
        hg38fasta   => $data{hg38}{fasta},
        hs37cosmic  => $data{hs37}{cosmic},              # From hg19
        hs37dbnsfp  => $data{hs37}{dbnsfp4},             # From hg19
        hs37fasta   => $data{hs37}{fasta},
        mongoimport => $mongodb_db_tools{mongoimport},
        mongostat   => $mongodb_db_tools{mongostat},
        mongosh     => $mongosh,
        mongodburi  => $mongodb_uri,
        dbnsfpset   => 'all',
        paneldir    => $panel_dir,
        tmpdir      => $tmpdir
    );
    my @keys     = keys %config;
    my $hostname = hostname;
    my $user     = $ENV{LOGNAME} || $ENV{USER} || getpwuid($<);

    # Definining options for config
    my $beacon_config = catfile( $root_dir, 'config.yaml' ); # Global $::Bin variable
    $config_file =
      ( $user eq 'mrueda' && $hostname =~ 'mrueda-ws1' ) ? $config_file : # debug
      defined $config_file ? $config_file :    # -c arg
      $beacon_config;                          # default location

    # Parsing config file
    %config = ( %config, parse_yaml_file( $config_file, \@keys ) )
      if $config_file;                         # merging two hashes in one

    # **** Important note about <hs37> *******
    # We loaded default values for hs37cosmic or hs37dbnsfp, which are good for development
    # but when <using beacon.config> the paths for hs37cosmic or hs37dbnsfp are not specified
    # so they're hard-coded below
    $config{hs37cosmic}  = $config{hg19cosmic};
    $config{hs37dbnsfp}  = $config{hg19dbnsfp};
    $config{hs37clinvar} = $config{hg19clinvar};

    #print Dumper \%config;
    #Check that DB exes/files and tmpdir exist
    while ( my ( $key, $val ) = each %config ) {
        next
          if ( $key eq 'mem' || $key eq 'dbnsfpset' || $key eq 'mongodburi' );
        die
"We could not find <$val> files\nPlease check for typos? in your <$beacon_config> file"
          unless -e $val;
    }

    # Below are a few internal paramaters
    my $beacon_bin = "$root_dir/lib/BEACON/bin";    # Global $::Bin variable
    my $java       = '/usr/bin/java';
    $config{snpeff}    = "$java -Xmx" . $config{mem} . " -jar $config{snpeff}";
    $config{snpsift}   = "$java -Xmx" . $config{mem} . " -jar $config{snpsift}";
    $config{bash4bff}  = catfile( $beacon_bin, 'run_vcf2bff.sh' );
    $config{bash4html} = catfile( $beacon_bin, 'run_bff2html.sh' );
    $config{bash4mongodb} = catfile( $beacon_bin, 'run_bff2mongodb.sh' );
    $config{vcf2bff}      = catfile( $beacon_bin, 'vcf2bff.pl' );
    $config{bff2json}     = catfile( $beacon_bin, 'bff2json.pl' );
    $config{json2html}    = catfile( $beacon_bin, 'bff2html.pl' );
    $config{browserdir}   = $browser_dir;

    # Check if the scripts exist and have +x permission
    my @scripts =
      qw(bash4bff bash4html bash4mongodb vcf2bff bff2json json2html);
    for my $script (@scripts) {
        die "You don't have +x permission for script <$config{$script}>"
          unless ( -x $config{$script} );
    }
    die "Sorry only [ega|all] values are accepted for <dbnsfpset>"
      unless ( $config{dbnsfpset} eq 'all' || $config{dbnsfpset} eq 'ega' );

    return wantarray ? %config : \%config;
}

=head2 read_param_file

    About   : Subroutine that reads the parameters file
    Usage   :            
    Args    : 

=cut

sub read_param_file {

    my $arg        = shift;               # Some args will be needed for QC
    my $param_file = $arg->{paramfile};

    # We load %param with the default values
    my %param = (
        bff       => {},
        center    => 'CRG',
        datasetid => 'default_beacon_1',
        ega       => {
            egac => 'EGAC00000000000',
            egad => 'EGAD00000000000',
            egas => 'EGAS00000000000',
        },
        genome     => 'hg19',
        organism   => 'Homo Sapiens',
        projectdir => 'beacon',
        bff2html   => 0,
        pipeline   => {
            vcf2bff     => 'false',
            bff2html    => 'false',
            bff2mongodb => 'false'
        },
        technology => 'Illumina HiSeq 2000'

    );
    my @keys = keys %param;

    # NOTE: Nested parameters overwrite all
    # For instance, only {bff}{metadatadir} will empty {bff}
    %param = ( %param, parse_yaml_file( $param_file, \@keys ) )
      if $param_file;    # merging two hashes in one
                         #print Dumper \%param and die;

    # Below are a few internal paramaters
    chomp( my $ncpuhost = qx{/usr/bin/nproc} ) // 1;
    $param{jobid} = time . substr( "00000$$", -5 );
    $param{date}  = localtime();
    $param{projectdir} =~ tr/ /_/;    # Transform white spaces to _
    $param{projectdir} .= '_' . $param{jobid};
    $param{log}      = catfile( $param{projectdir}, 'log.json' );
    $param{hostname} = hostname;
    $param{user}     = $ENV{LOGNAME} || $ENV{USER} || getpwuid($<);
    $param{ncpuhost} = 0 + $ncpuhost;    # coercing it to be a number
    $param{ncpuless} = $param{ncpuhost} > 1 ? $param{ncpuhost} - 1 : 1;
    my $str_ncpuless = $param{ncpuless}; # We copy it (otherwise it will get "stringified" below and printed with "" in log.json)
    $param{zip} =
      ( -x '/usr/bin/pigz' )
      ? "/usr/bin/pigz -p $str_ncpuless"
      : '/bin/gzip';
    $param{organism} =
      $param{organism} eq lc('human') ? 'Homo Sapiens' : $param{organism};
    $param{gvvcfjson} =
      catfile( $param{projectdir}, 'vcf', 'genomicVariationsVcf.json.gz' );

    # Check parameter 'genome' (using any from List::Utils instead of exist $key{value}
    my @assemblies = qw(hg19 hg38 hs37);
    die "Please select a valid reference genome. The options are [@assemblies]"
      unless ( any { $_ eq $param{genome} } @assemblies );

    # Enforcing options depending on mode
    my ( $opt_a, $opt_b, $opt_c ) = ( 0, $param{bff2html}, 0 );
    if ( $arg->{mode} eq 'full' ) {
        ( $opt_a, $opt_c ) = ( 1, 1 );
    }
    elsif ( $arg->{mode} eq 'vcf' ) {
        ( $opt_a, $opt_c ) = ( 1, 0 );
    }
    else {    #mongodb
        ( $opt_a, $opt_b, $opt_c ) = ( 0, 0, 1 );
    }
    $param{pipeline}{vcf2bff}     = $opt_a;
    $param{pipeline}{bff2html}    = $opt_b;
    $param{pipeline}{bff2mongodb} = $opt_c;

    # Check if -f user_collections for modes [mongodb|full]
    if ( $arg->{mode} eq 'mongodb' || $arg->{mode} eq 'full' ) {
        my @collections =
          qw(runs cohorts biosamples individuals genomicVariations  analyses datasets);
        push @collections, 'genomicVariationsVcf' if $arg->{mode} eq 'mongodb';
        my @user_collections =
          grep { $_ ne 'metadatadir' } sort keys %{ $param{bff} };
        my $metadata_dir = $param{bff}{metadatadir};
        for my $collection (@user_collections) {
            die
"Collection: <$collection> is not a valid value for bff:\nAllowed values are <@collections>"
              unless any { $_ eq $collection } @collections;
            my $tmp_file =
                $collection eq 'genomicVariationsVcf'
              ? $param{bff}{$collection}
              : catfile( $metadata_dir, $param{bff}{$collection} );
            die
              "Collection: <$collection> does not have a valid file <$tmp_file>"
              unless -f $tmp_file;
            $param{bff}{$collection} = $tmp_file;
        }
    }

    # Force genomicVariations.json value if $mode eq 'full'
    $param{bff}{genomicVariationsVcf} = $param{gvvcfjson}
      if $arg->{mode} eq 'full';

    # Warn messages
    warn "Organism not tested => $param{organism}"
      if lc( $param{organism} ) ne 'homo sapiens';

    return wantarray ? %param : \%param;
}

sub parse_yaml_file {

    my ( $yaml_file, $ra_keys ) = @_;

    # Keeping booleans as 'true' or 'false'. Perl still handles 0 and 1 internally.
    $YAML::XS::Boolean = 'JSON::PP';

    # Decoding the YAML into a Perl data structure (Hash)
    my $yaml = LoadFile($yaml_file);

    # Check user typos in parameters name
    for my $key ( keys %$yaml ) {

        # Forcing lc($key) to allow case-typos
        # Note: We modify the original value in $yaml!
        $key = lc($key);
        my $param_syntax_ok = any { $_ eq $key } @$ra_keys; #Note scalar context
        die "Parameter <$key> does not exist (typo?)" unless $param_syntax_ok;
    }
    return wantarray ? %$yaml : $yaml;
}
1;
