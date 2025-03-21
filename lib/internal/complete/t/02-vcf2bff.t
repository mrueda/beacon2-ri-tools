#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use File::Compare;

# Define file names
my $output_file    = "t/genomicVariationsVcf-dev-bff.json.gz";
my $reference_file = "t/expected_genomicVariationsVcf-dev-bff.json.gz";  # adjust if needed

# Remove any existing output file to ensure a clean test
unlink $output_file if -e $output_file;

# Build the command line
my $cmd = "perl vcf2bff.pl -i t/test_pathogenic.vcf.gz --genome hg19 -dataset-id foo -project-dir 123456789 -f bff-pretty -out-dir t";

# Run the command, capturing both stdout and stderr
my $cmd_output = `$cmd 2>&1`;
my $exit_status = $? >> 8;

# Determine number of tests:
# Test 1: exit status, Test 2: output file exists, Test 3: reference comparison (or pass)
my $tests = 3;
plan tests => $tests;

# Test that the script exits successfully
is( $exit_status, 0, 'Script exited with status 0' );

# Test that the expected output file is created
ok( -e $output_file, "Output file '$output_file' exists" );

# Test uncompressed content, comparing against the reference file if it exists
if ( -e $reference_file ) {
    my $output_content = '';
    my $ref_content    = '';
    gunzip $output_file => \$output_content
      or die "gunzip failed for $output_file: $GunzipError";
    gunzip $reference_file => \$ref_content
      or die "gunzip failed for $reference_file: $GunzipError";
    
    # Sort the contents line-by-line
    my $sorted_output = join "\n", sort split /\n/, $output_content;
    my $sorted_ref    = join "\n", sort split /\n/, $ref_content;

    unlink($output_file);
    
    is( $sorted_output, $sorted_ref, "Sorted uncompressed content matches the expected reference" );
} else {
    pass("Reference file '$reference_file' not found, skipping file content comparison");
}

done_testing();

