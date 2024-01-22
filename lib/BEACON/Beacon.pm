package Beacon;

use strict;
use warnings;
use autodie;
use feature qw(say);
use File::Basename;
use Carp;
use File::Spec::Functions qw(catdir catfile);
use Path::Tiny qw(path);
use Data::Dumper;
use Cwd qw(cwd abs_path);
use YAML::XS qw(LoadFile DumpFile);

=head1 NAME

    BEACON::Beacon

=head1 SYNOPSIS

  use BEACON::Beacon

=head1 DESCRIPTION
 
  To do


=head1 AUTHOR

Written by Manuel Rueda, PhD

=cut

=head1 METHODS

=cut

=head2 new

    About   : Using pure OO-Perl for simplicity
    Usage   :             
    Args    : 

=cut

sub new {

    # Changes in $self performed at main
    my ( $class, $self ) = @_;
    bless $self, $class;
    return $self;
}

=head2 vcf2bff

    About   : Method that sends the BASH pipeline vcf2bff
    Usage   :             
    Args    : 

=cut

sub vcf2bff {

    my $self      = shift;
    my $dir       = $self->{projectdir};
    my $input     = $self->{inputfile};
    my $datasetid = $self->{datasetid};
    my $snpeff    = $self->{snpeff};
    my $snpsift   = $self->{snpsift};
    my $bcftools  = $self->{bcftools};
    my $vcf2bff   = $self->{vcf2bff};
    my $ref       = $self->{reference};
    my $genome = $self->{genome} eq 'hs37' ? 'hg19' : $self->{genome}; # Needed for Step 2 <$snpeff -noStats>
    my $dbnsfp     = $self->{dbnsfp};
    my $clinvar    = $self->{clinvar};
    my $cosmic     = $self->{cosmic};
    my $zip        = $self->{zip};
    my $filename   = $self->{bash4bff};
    my $dbnsfp_set = $self->{dbnsfpset};
    my $debug      = $self->{debug};
    my $tmpdir     = $self->{tmpdir};
    my $verbose    = $self->{verbose};

    # In order to run vcf2bff we contemplated 3 possibilities:
    #   -------- External ($vcf2bff) - Local ($dir/) -------
    # 1 - External script with local parameters (i.e., source parameters.sh)
    # 2 - Local script with local parameters    (i.e., source parameters.sh)
    # 3 - Modified local script                 (i.e., parameters embeded) <==== EASIER FOR USER

    # Option 3 - Load the original script and create a new version with the right vars
    my @params = (
        "export TMPDIR=$tmpdir", "zip='$zip'",
        "snpeff='$snpeff'",      "snpsift='$snpsift'",
        "bcftools=$bcftools",    "vcf2bff=$vcf2bff",
        "genome='$genome'",      "ref=$ref",
        "cosmic=$cosmic",        "dbnsfp=$dbnsfp",
        "datasetid=$datasetid",  "projectdir=$dir",
        "clinvar=$clinvar"
    );

    # Prepare variables
    my $str_var .= join "\n", @params;
    my $str_db       = create_dbnsfp4_fields( $dbnsfp_set, $dbnsfp );
    my $file_content = path($filename)->slurp;

    #my $file_content = do { local ( @ARGV, $/ ) = $filename; <> }; # Pure Perl load
    $file_content =~ s/#____VARIABLES____#/$str_var/;
    $file_content =~ s/#____FIELDS____#/$str_db/;
    my $script = basename($filename);
    ( my $script_log = $script ) =~ s/sh/log/;
    $dir = catdir( $dir, 'vcf' );
    mkdir $dir;
    my $script_path     = catfile( $dir, $script );
    my $script_log_path = catfile( $dir, $script_log );

    # Create script
    write_file($script_path, \$file_content);

    # Script submission
    my $input_abs = abs_path($input);    # Mandatory to be abs_path
    say 'Dbg' . $debug . ': *** cwd: ', cwd, ' ***' if $debug;
    my $cmd = "cd $dir; bash $script $input_abs > $script_log 2>&1";
    say 'Dbg' . $debug . ': *** Submitting => ', $cmd, ' ***' if $debug;
    submit_cmd( $cmd, $script_path, $script_log_path, $debug );
    say 'Dbg' . $debug . ': *** cwd: ', cwd, ' ***' if $debug;
    return 1;
}

=head2 bff2html

    About   : Method that sends the BASH pipeline bff2html
    Usage   :             
    Args    : 

=cut

sub bff2html {

    my $self        = shift;
    my $jobid       = $self->{jobid};
    my $dir         = $self->{projectdir};
    my $filename    = $self->{bash4html};
    my $input       = $self->{gvvcfjson};
    my $bff2json    = $self->{bff2json};
    my $json2html   = $self->{json2html};
    my $tmpdir      = $self->{tmpdir};
    my $browser_dir = $self->{browserdir};
    my $web_dir     = catdir( $browser_dir, 'web' );
    my $panel_dir   = $self->{paneldir};
    my $debug = $self->{debug};
    my $verbose     = $self->{verbose};

    # Parameters for the script
    my @params = (
        "export TMPDIR=$tmpdir", "bff2json=$bff2json",
        "json2html=$json2html",  "web_dir=$web_dir",
        "panel_dir=$panel_dir"
    );

    # Prepare variables
    my $str .= join "\n", @params;
    my $file_content = path($filename)->slurp;
    $file_content =~ s/#____VARIABLES_____/$str/;
    my $script = basename($filename);
    ( my $script_log = $script ) =~ s/sh/log/;
    $dir = catdir( $dir, 'browser' );
    mkdir $dir;
    my $script_path     = catfile( $dir, $script );
    my $script_log_path = catfile( $dir, $script_log );

    # Create script
    write_file($script_path, \$file_content);

    # Script submission
    my $input_abs = abs_path($input);    # Mandatory to be abs_path
    my $cmd = "cd $dir; bash $script $input_abs $jobid > $script_log 2>&1";
    say 'Dbg' . $debug . ': *** cwd: ', cwd, ' ***' if $debug;
    say 'Dbg' . $debug . ': *** Submitting => ', $cmd, '***' if $debug;
    submit_cmd( $cmd, $script_path, $script_log_path, $debug );
    say 'Dbg' . $debug . ': *** cwd: ', cwd, ' ***' if $debug;
    return 1;
}

=head2 bff2mongodb

    About   : Method that inserts the BFF data into MongoDB
    Usage   :             
    Args    : 

=cut

sub bff2mongodb {

    my $self        = shift;
    my $jobid       = $self->{jobid};
    my $dir         = $self->{projectdir};
    my $filename    = $self->{bash4mongodb};
    my $zip         = $self->{zip};
    my $bff         = $self->{bff};
    my $tmpdir      = $self->{tmpdir};
    my $mongoimport = $self->{mongoimport};
    my $mongodburi  = $self->{mongodburi};
    my $mongosh     = $self->{mongosh};
    my $verbose     = $self->{verbose};
    my $debug       = $self->{debug};

    #print Dumper $self->{bff};

    ##################
    # MongoDB checks #
    ##################
    # At two levels:
    # 1 - 'beacon' instance up and running => via <is_mongo_up> (requires MongoDB Perl driver)
    # is_mongo_up($mongodburi); # noCanDo as it will fail when no data has been loaded
    # 2 - Ingestion returned no errors => via <check_mongoimport> (parses log file)

    # Parameters for the script
    my @params = (
        "export TMPDIR=$tmpdir",    "zip='$zip'",
        "mongoimport=$mongoimport", "mongodburi=$mongodburi",
        "mongosh=$mongosh"
    );

    # This time having $arg is more complicated because we need constant naming for collections
    # Creating a Bash (v4) hash
    # e.g. declare -A collections=( ["moo"]="cow" ["woof"]="dog")
    my @tmp_collections = ();
    for my $collection ( keys %{$bff} ) {
        next
          if ( $collection eq 'metadatadir'
            || $collection eq 'genomicVariationsVcf' );
        my $collection_path = abs_path( $bff->{$collection} );
        push @tmp_collections, qq(["$collection"]="$collection_path");
    }
    my $tmp_str_collection =
      'declare -A collections=(' . join( ' ', @tmp_collections ) . ')';
    push @params, $tmp_str_collection;

    # Special case: genomicVariationsVCF is gzipped
    my $gv_str =
      $bff->{genomicVariationsVcf}
      ? "\n"
      . qq(echo "Loading collection...genomicVariations[Vcf]") . "\n"
      . '$zip -dc '
      . abs_path( $bff->{genomicVariationsVcf} )
      . qq( | \$mongoimport --jsonArray --uri "\$mongodburi" --collection genomicVariations || echo "Could not load <$bff->{genomicVariationsVcf}> for <genomicVariations>")
      . "\n"
      . qq(echo "Indexing collection...genomicVariations[Vcf]") . "\n"
      . qq(\$mongosh "\$mongodburi"<<EOF\ndisableTelemetry()\n/* Single field indexes */\ndb.genomicVariations.createIndex( {"\\\$**": 1}, {name: "single_field_genomicVariations"} )\n/* Text indexes */\ndb.genomicVariations.createIndex( {"\\\$**": "text"}, {name: "text_genomicVariations"} )\nquit()\nEOF)
      : '';

    # Prepare variables
    my $str .= join "\n", @params;
    my $file_content = path($filename)->slurp;
    $file_content =~ s/#____VARIABLES_____/$str/;
    $file_content =~ s/\n#__GENOMIC_VARIATIONS__/$gv_str/;
    my $script = basename($filename);
    ( my $script_log = $script ) =~ s/sh/log/;
    $dir = catdir( $dir, 'mongodb' );
    mkdir $dir;
    my $script_path     = catfile( $dir, $script );
    my $script_log_path = catfile( $dir, $script_log );

    # Create script
    write_file($script_path, \$file_content);

    # Script submission
    my $cmd = "cd $dir; bash $script > $script_log 2>&1";
    say 'Dbg' . $debug . ': *** cwd: ', cwd, ' ***' if $debug;
    say 'Dbg' . $debug . ': *** Submitting => ', $cmd, '***' if $debug;
    submit_cmd( $cmd, $script_path, $script_log_path, $debug );
    check_mongoimport($script_log_path);
    say 'Dbg' . $debug . ': *** cwd: ', cwd, ' ***' if $debug;
    return 1;
}

=head2 create_dbnsfp4_fields
    
    About   : Subroutine that creates a list of annotation fields to be used with SnpSift/dbNFSP
    Usage   :             
    Args    : 
    
=cut

sub create_dbnsfp4_fields {

    my ( $selection, $file ) = @_;
    my $str = '';

    # ***LEGACY: Fields selected by EGA somewhere around late 2020***
    if ( $selection eq 'ega' ) {
        my @ega_fields =
          qw(aaref aaalt rs_dbSNP151 aapos genename Ensembl_geneid Ensembl_transcriptid Ensembl_proteinid Uniprot_acc Uniprot_entry HGVSc_snpEff HGVSp_snpEff SIFT_score SIFT_converted_rankscore SIFT_pred Polyphen2_HDIV_score Polyphen2_HDIV_pred Polyphen2_HVAR_score Polyphen2_HVAR_pred MutPred_score MVP_score DEOGEN2_score ClinPred_score ClinPred_pred phastCons100way_vertebrate phastCons30way_mammalian clinvar_id clinvar_clnsig clinvar_trait clinvar_review clinvar_hgvs clinvar_var_source clinvar_MedGen_id clinvar_OMIM_id clinvar_Orphanet_id Interpro_domain);
        $str = join ',', sort @ega_fields;
    }

    # All fields available in dbNSFP4
    else {
        chomp( my $header = `zcat $file | head -1 | cut -c2-` );
        $str = join ',', sort map { $_ =~ m/[()]/ ? "'$_'" : $_ } split /\s+/,
          $header;
    }
    return $str;
}

=head2 submit_cmd
    
    About   : Subroutine that sends systems calls
    Usage   :             
    Args    : 
    
=cut

sub submit_cmd {

    my ( $cmd, $job, $log, $debug ) = @_;
    my $msg = "Failed to execute: $job\nPlease check this file $log";
    system("$cmd") == 0 or ( $debug ? confess($msg) : croak($msg) );
    return 1;
}

sub write_file {
  
    my ($file, $content) = @_;
    path($file)->spew($$content);
    chmod 0755, $file;
}

sub check_mongoimport {

    my $filename     = shift;
    my $file_content = path($filename)->slurp;
    $file_content =~ m/(\d+) document(s) failed to import/;
    die "There was an error with <mongoimport>. Please check <$filename>" if $1;
    return 1;
}

sub is_mongo_up {

    my $host_uri = shift;
    require MongoDB;    # required at runtime
    die "We could not connect to MongoDB <$host_uri>"
      if eval { my $client = MongoDB->connect($host_uri) };
    return 1;
}

1;
