#!/usr/bin/env perl
#
#   Script to transform dataTables-JSON to HTML
#
#   Last Modified: Apr/12/2022
#
#   Version taken from $beacon
#
#   Copyright (C) 2021-2024 Manuel Rueda (manuel.rueda@cnag.eu)
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, see <https://www.gnu.org/licenses/>.
#
#   If this program helps you in your research, please cite.

use strict;
use warnings;
use autodie;
use Getopt::Long;
use Pod::Usage;
use File::Basename;
use feature qw(say);

#### Main ####
json2html();
##############
exit;

sub json2html {

    # Defining a few variables
    my $version = '2.0.1';
    my @browser_fields =
      qw(variantInternalId assemblyId refseqId position referenceBases alternateBases QUAL FILTER variantType genomicHGVSId geneIds molecularEffects aminoacidChanges annotationImpact conditionId dbSNP ClinVar clinicalRelevance biosampleId);

    # Reading arguments
    GetOptions(
        'id=s'        => \my $id,                                   # string
        'web-dir=s'   => \my $web_dir,                              # string
        'panel-dir=s' => \my $panel_dir,                            # string
        'help|?'      => \my $help,                                 # flag
        'man'         => \my $man,                                  # flag
        'debug=i'     => \my $debug,                                # integer
        'verbose'     => \my $verbose,                              # flag
        'version|v'   => sub { say "$0 Version $version"; exit; }
    ) or pod2usage(2);
    pod2usage(1)                              if $help;
    pod2usage( -verbose => 2, -exitval => 0 ) if $man;
    pod2usage(
        -message => "Please specify a valid id with -id <id>\n",
        -exitval => 1
    ) unless ( $id =~ /\w+/ );
    pod2usage(
        -message => "Please specify a valid --panel-dir value\n",
        -exitval => 1
    ) unless ( $panel_dir =~ /\w+/ );
    pod2usage(
        -message => "Please specify a valid --web-dir value\n",
        -exitval => 1
    ) unless ( $web_dir =~ /\w+/ );

    # First we read the list of panels from $panel_dir
    my @panels = glob("$panel_dir/*.lst");

    # Secondly we count the number of lines and create a hash $panel{exome} = 19002
    my %panel = ();
    for my $panel (@panels) {
        my $count = 0;
        open( my $file, "< $panel" );
        $count += tr/\n/\n/ while sysread( $file, $_, 2**16 );
        close $file;
        my $key = basename( $panel, '.lst' );
        $panel{$key} = $count;
    }

    # Finally, we print the HTML
    print create_html( $id, $web_dir, \%panel, \@browser_fields );
    return 1;
}

sub create_html {
    my $id        = shift;
    my $web_dir   = shift;
    my $rh_panel  = shift;
    my $ra_header = shift;
    my @panels    = sort keys %$rh_panel;    # Note uc panels will be first
    my $str       = <<EOF;
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Beacon Friendly Format Genomic Variations Browser</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="Beacon Friendly Format Genomic Variations Browser">
    <meta name="author" content="Manuel Rueda"> 

      <!-- Le styles -->
    <link rel="icon" href="$web_dir/img/favicon.ico" type="image/x-icon" />
    <link rel="stylesheet" type="text/css" href="$web_dir/css/bootstrap.css" rel="stylesheet">
    <link rel="stylesheet" type="text/css" href="$web_dir/css/bootstrap-responsive.css" rel="stylesheet">
    <link rel="stylesheet" type="text/css" href="$web_dir/css/main.css" rel="stylesheet">
    <link rel="stylesheet" type="text/css" href="$web_dir/jsD/media/css/jquery.dataTables.css">
    <link rel="stylesheet" type="text/css" href="$web_dir/jsD/media/css/dataTables.colReorder.css">
    <link rel="stylesheet" type="text/css" href="$web_dir/jsD/media/css/dataTables.colVis.css">
    <link rel="stylesheet" type="text/css" href="$web_dir/jsD/media/css/dataTables.tableTools.css">
   
    <script src="$web_dir/js/jquery.min.js"></script>
    <script src="$web_dir/js/bootstrap.min.js"></script>
    <script src="$web_dir/jsD/media/js/jquery.dataTables.min.js"></script>
    <script src="$web_dir/jsD/media/js/dataTables.colReorder.js"></script>
    <script src="$web_dir/jsD/media/js/dataTables.colVis.js"></script>
    <script src="$web_dir/jsD/media/js/dataTables.tableTools.js"></script>
    <script src="$web_dir/js/jqBootstrapValidation.js"></script>

   <script type="text/javascript" language="javascript" class="init">
EOF

    for my $panel (@panels) {
        $str .= create_datatables($panel);
    }

    $str .= <<EOF;
   </script>


  </head>
  <body class="dt-example">

    <!-- NAVBAR
    ================================================== -->
    <div class="navbar navbar-inverse navbar-fixed-top">
            <div class="navbar-inner">
                <div class="container">
                    <a class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
                        <span class="icon-bar"></span>
                        <span class="icon-bar"></span>
                        <span class="icon-bar"></span>
                    </a>
                    <a class="brand" href="#">BFF Genomic Variations Browser</a>
                    <div class="nav-collapse collapse">
                        <ul class="nav">
                            <li class="dropdown">
                                <a href="#" class="dropdown-toggle" data-toggle="dropdown">Help <b class="caret"></b></a>
                                <ul class="dropdown-menu">
                                    <li class="nav-header">Help</li>
                                    <li><a href="https://b2ri-documentation.readthedocs.io/en/latest/bff-gv-browser/"><span class="icon-question-sign"></span> Help Page</a>
                                    <li class="divider"></li>
                                    <li class="nav-header">FAQs</li>
                                    <li><a href="https://b2ri-documentation.readthedocs.io/en/latest/faq"><span class="icon-question-sign"></span> FAQs Page</a></a></li>
                                </ul>
                            </li>
                            <li class="dropdown">
                                <a href="#" class="dropdown-toggle" data-toggle="dropdown">Links <b class="caret"></b></a>
                                <ul class="dropdown-menu">
                                    <li class="nav-header">Contact</li>
                                    <li><a href="mailto:manuel.rueda\@cnag.eu"><span class="icon-envelope"></span> Author</a></li>
                                    <li class="divider"></li>
                                    <li class="nav-header">CRG Links</li>
                                    <li><a href="https://www.crg.eu"><span class="icon-home"></span> CRG</a></li>
                                    <li><a href="https://ega-archive.org"><span class="icon-home"></span> EGA</a></li>
                                    <li><a href="https://www.cnag.crg.eu"><span class="icon-home"></span> CNAG</a></li>
                                </ul>
                            </li>
                        </ul>
                    </div><!--/.nav-collapse -->
                </div>
            </div>
        </div>

     <div class="container">
EOF

    for my $panel ( reverse @panels ) { # To get 'btn pull-right' rendered in the right order ;-)
        my $panel_ucf = ucfirst($panel);
        $str .=
qq(      <a class="btn pull-right" href="./$panel.json"><i class="icon-download"></i> $panel_ucf JSON</a>);
        $str .= "\n";
    }

    $str .= <<EOF;

     <h3>Job ID: $id &#9658 genomicVariationsVcf</h3>
     <p>Displaying variants with <strong>Annotation Impact</strong> values equal to <strong>HIGH</strong><p>

      <div>

       <ul class="nav nav-tabs">
EOF

    for my $panel (@panels) {
        my $panel_ucf = ucfirst($panel);
        my $bool = $panel eq $panels[0] ? 'active' : ''; # 1st panel is the active one
        $str .=
qq(      <li class="$bool"><a href="#tab-panel-$panel" data-toggle="tab"> $panel_ucf panel - $rh_panel->{$panel} genes</a></li>);
        $str .= "\n";
    }

    $str .= <<EOF;
       </ul>
      <div id="myTabContent" class="tab-content">
EOF

    for my $panel (@panels) {
        my $bool = $panel eq 'cardiopathy' ? 1 : 0;
        $str .= create_table( $panel, $bool, $ra_header );
    }

    $str .= <<EOF;

      </div>

      <br /><p class="pagination-centered">Beacon Friendly Format Genomic Variations Browser</p> 
      <hr>
      <!-- FOOTER -->
      <footer>
                    <p>&copy; 2021-2024 Centre for Genomic Regulation | Barcelona, Spain </p>

      </footer>

    </div><!-- /.container -->

  </body>
</html>
EOF
    return $str;
}

sub create_datatables {

    my $panel = shift;
    my $str   = <<EOF;

   \$(document).ready(function() {
    \$('#table-panel-$panel').dataTable( {
        "ajax": "$panel.mod.json",
        "bDeferRender": true,
         stateSave: true,
        "language": {
         "sSearch": '<span class="icon-search" aria-hidden="true"></span>',
         "lengthMenu": "Show _MENU_ variants",
         "sInfo": "Showing _START_ to _END_ of _TOTAL_ variants",
          "sInfoFiltered": " (filtered from _MAX_ variants)"
       },
        "order": [[  1, "asc" ]],
        search: {
          "regex": true
         }, 
       aoColumnDefs: [
          { visible: false, targets: [ 0, 1, 6, 7, 9, 12, 13, 15, 14, 18 ] }
       ], 
       dom: 'CRT<"clear">lfrtip',
       colVis: {
            showAll: "Show all",
            showNone: "Show none"
        },
          tableTools: {
            aButtons: [ { "sExtends": "print" , "sButtonText": '<span class="icon-print" aria-hidden="true"></span>' } ]
        } 
     } );
   } );

EOF
    return $str;
}

sub create_table {

    my $panel     = shift;
    my $active    = shift ? 'active' : '';
    my $ra_header = shift;
    my $str       = <<EOF;
      <div class="tab-pane fade in $active" id="tab-panel-$panel">
      <!-- TABLE -->
      <table id="table-panel-$panel" class="display table table-hover table-condensed">
        <thead>
            <tr>
EOF
    for my $field (@$ra_header) {
        $str .= "             <th>$field</th>\n";
    }

    $str .= <<EOF;
            </tr>
        </thead>
     </table>
     </div>

EOF
    return $str;
}

=head1 NAME

bff2html: A script to transform dataTables-JSON to HTML


=head1 SYNOPSIS


bff2html.pl -id your_id -web-dir /path/foo/bar -panel-dir /path/web [-options]

     Arguments:                       
       -id                            ID (string)
       -web-dir                       /path to directory with css, img and stuff.
       -panel-dir                     /path to directory with gene panels

     Options:
       -h|help                        Brief help message
       -man                           Full documentation
       -debug                         Print debugging (from 1 to 5, being 5 max)
       -verbose                       Verbosity on


=head1 CITATION

The author requests that any published work that utilizes B<B2RI> includes a cite to the the following reference:

Rueda, M, Ariosa R. "Beacon v2 Reference Implementation: a toolkit to enable federated sharing of genomic and phenotypic data". I<Bioinformatics>, btac568, https://doi.org/10.1093/bioinformatics/btac568

=head1 SUMMARY

Script to transform dataTables-JSON to HTML,

=head1 HOW TO RUN BFF2HTML

The script runs on Linux (tested on Debian-based distribution). Perl 5 is installed by default on Linux. 

For executing bff2html you will need:

=over

=item --id

A given ID (string)

=item --web-dir 

The directory with css, js, etc. files

=item --panel-dir 

The directory with the gene panels

=back

The script will use data from each C<$panel.json> files, which should have been generated previously with C<bff2json.pl>.

B<Examples:>

   $ ./bff2html.pl -id ega_123456 --web-dir /var/html/www/my_web  --panel-dir /home/foo/my_panel_dir > file.html

=head1 AUTHOR 

Written by Manuel Rueda, PhD. Info about CRG can be found at L<https://www.crg.eu>.

=head1 REPORTING BUGS

Report bugs or comments to <manuel.rueda@cnag.eu>.

=head1 COPYRIGHT

This PERL file is copyrighted. See the LICENSE file included in this distribution.

=cut
