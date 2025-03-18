#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More tests => 6;
use File::Temp qw(tempdir);
use File::Spec::Functions qw(catfile);
use Cwd qw(abs_path);
use BEACON::Beacon;

# Test new() method: create a dummy object and verify its class.
my $dummy_args = { foo => 1 };
my $beacon = Beacon->new($dummy_args);
isa_ok($beacon, 'Beacon', 'Object created from Beacon->new');

# Test create_dbnsfp4_fields in "cnag" mode.
my @cnag_fields = qw(
  aaref aaalt rs_dbSNP151 aapos genename Ensembl_geneid Ensembl_transcriptid
  Ensembl_proteinid Uniprot_acc Uniprot_entry HGVSc_snpEff HGVSp_snpEff
  SIFT_score SIFT_converted_rankscore SIFT_pred Polyphen2_HDIV_score
  Polyphen2_HDIV_pred Polyphen2_HVAR_score Polyphen2_HVAR_pred MutPred_score
  MVP_score DEOGEN2_score ClinPred_score ClinPred_pred phastCons100way_vertebrate
  phastCons30way_mammalian clinvar_id clinvar_clnsig clinvar_trait clinvar_review
  clinvar_hgvs clinvar_var_source clinvar_MedGen_id clinvar_OMIM_id
  clinvar_Orphanet_id Interpro_domain
);
my $expected = join(',', sort @cnag_fields);
# Call the subroutine directly (it doesn't shift off an object)
my $fields = Beacon::create_dbnsfp4_fields('cnag', '');
is($fields, $expected, 'create_dbnsfp4_fields returns expected string for "cnag" mode');

# Test write_file: create a temporary file and verify file creation and permissions.
my $temp_dir  = tempdir( CLEANUP => 1 );
my $temp_file = catfile($temp_dir, 'test_script.sh');
my $content   = "echo Hello World\n";
Beacon::write_file($temp_file, \$content);
ok(-e $temp_file, 'write_file creates the file');
my $mode = (stat($temp_file))[2] & 07777;
is($mode, 0755, 'write_file sets permissions to 0755');

# Test check_mongoimport: simulate a log file with no import errors.
my $good_log = catfile($temp_dir, 'mongo_good.log');
{
    open my $fh, '>', $good_log or die $!;
    print $fh "0 documents failed to import\n";
    close $fh;
}
ok(Beacon::check_mongoimport($good_log), 'check_mongoimport passes with no errors');

# Test check_mongoimport: simulate a log file that reports failures.
my $fail_log = catfile($temp_dir, 'mongo_fail.log');
{
    open my $fh, '>', $fail_log or die $!;
    print $fh "3 documents failed to import\n";
    close $fh;
}
my $dies;
eval { check_mongoimport($fail_log); };
$dies = $@ ? 1 : 0;
ok($dies, 'check_mongoimport dies on import errors');

done_testing();
