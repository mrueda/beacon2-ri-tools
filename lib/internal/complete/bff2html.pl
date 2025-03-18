#!/usr/bin/env perl
#
#   Script to transform dataTables-JSON to HTML
#
#   Last Modified: Jan/07/2025
#
#   Version taken from $beacon
#
#   Copyright (C) 2021-2022 Manuel Rueda - CRG
#   Copyright (C) 2023-2025 Manuel Rueda - CNAG (manuel.rueda@cnag.eu)
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
exit;

sub json2html {
    my $version        = '2.0.6';
    my @browser_fields = qw(
      variantInternalId assemblyId refseqId position referenceBases alternateBases
      QUAL FILTER variantType genomicHGVSId geneIds molecularEffects aminoacidChanges
      annotationImpact conditionId dbSNP ClinVar clinicalRelevance biosampleId
    );

    # Read and validate options
    GetOptions(
        'id=s'          => \my $id,
        'assets-dir=s'  => \my $assets_dir,
        'panel-dir=s'   => \my $panel_dir,
        'project-dir=s' => \my $project_dir,
        'help|?'        => \my $help,
        'man'           => \my $man,
        'debug=i'       => \my $debug,
        'verbose'       => \my $verbose,
        'version|v'     => sub { say "$0 Version $version"; exit; }
    ) or pod2usage(2);
    pod2usage(1)                              if $help;
    pod2usage( -verbose => 2, -exitval => 0 ) if $man;
    pod2usage(
        -message => "Please specify a valid id with -id <id>\n",
        -exitval => 1
    ) unless ( $id && $id =~ /\w+/ );
    pod2usage(
        -message => "Please specify a valid --panel-dir value\n",
        -exitval => 1
    ) unless ( $panel_dir && $panel_dir =~ /\w+/ );
    pod2usage(
        -message => "Please specify a valid --assets-dir value\n",
        -exitval => 1
    ) unless ( $assets_dir && $assets_dir =~ /\w+/ );

    # Read panels from the panel directory
    my @panel_files = glob("$panel_dir/*.lst");
    my %panel_counts;
    for my $panel_file (@panel_files) {
        my $count = 0;
        open( my $fh, '<', $panel_file );
        $count++ while <$fh>;
        close $fh;
        my $key = basename( $panel_file, '.lst' );
        $panel_counts{$key} = $count;
    }

    # Assemble full HTML by joining various parts
    my $html =
        generate_html_head( $assets_dir, [ keys %panel_counts ] )
      . generate_navbar()
      . generate_body_start( $project_dir, $id, \%panel_counts )
      . generate_table_tabs( \%panel_counts, \@browser_fields, $assets_dir )
      . generate_footer();

    print $html;
    return 1;
}

# Generates the <head> section including styles and JavaScript initialization
sub generate_html_head {
    my ( $assets_dir, $panels_ref ) = @_;
    my $html = <<"EOF";
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>BFF Browser</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="Beacon Friendly Format Browser">
    <meta name="author" content="Manuel Rueda"> 

    <!-- Styles -->
    <link rel="icon" href="$assets_dir/img/favicon.ico" type="image/x-icon" />
    <link rel="stylesheet" href="$assets_dir/css/bootstrap.css">
    <link rel="stylesheet" href="$assets_dir/css/bootstrap-responsive.css">
    <link rel="stylesheet" href="$assets_dir/css/main.css">
    <link rel="stylesheet" href="$assets_dir/jsD/media/css/jquery.dataTables.css">
    <link rel="stylesheet" href="$assets_dir/jsD/media/css/dataTables.colReorder.css">
    <link rel="stylesheet" href="$assets_dir/jsD/media/css/dataTables.colVis.css">
    <link rel="stylesheet" href="$assets_dir/jsD/media/css/dataTables.tableTools.css">
    
    <!-- JavaScript -->
    <script src="$assets_dir/js/jquery.min.js"></script>
    <script src="$assets_dir/js/bootstrap.min.js"></script>
    <script src="$assets_dir/jsD/media/js/jquery.dataTables.min.js"></script>
    <script src="$assets_dir/jsD/media/js/dataTables.colReorder.js"></script>
    <script src="$assets_dir/jsD/media/js/dataTables.colVis.js"></script>
    <script src="$assets_dir/jsD/media/js/dataTables.tableTools.js"></script>
    <script src="$assets_dir/js/jqBootstrapValidation.js"></script>
    
    <script type="text/javascript" class="init">
EOF

    # Insert DataTables initialization for each panel
    foreach my $panel ( sort @$panels_ref ) {
        $html .= generate_datatables_js($panel);
    }

    $html .= <<'EOF';
    </script>
  </head>
EOF
    return $html;
}

# Generates the JavaScript for initializing a DataTable for a given panel
sub generate_datatables_js {
    my $panel = shift;
    return <<"EOF";

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
        "order": [[ 1, "asc" ]],
        search: { "regex": true },
        aoColumnDefs: [
          { visible: false, targets: [ 0, 1, 6, 7, 9, 12, 13, 15, 14, 18 ] }
        ],
        dom: 'CRT<"clear">lfrtip',
        colVis: {
            showAll: "Show all",
            showNone: "Show none"
        },
        tableTools: {
            aButtons: [ { "sExtends": "print", "sButtonText": '<span class="icon-print" aria-hidden="true"></span>' } ]
        }
     });
   });
EOF
}

# Generates the navigation bar HTML
sub generate_navbar {
    my $navbar = <<'EOF';
  <body class="dt-example">
    <!-- NAVBAR -->
    <div class="navbar navbar-inverse navbar-fixed-top">
      <div class="navbar-inner">
        <div class="container">
          <a class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </a>
          <a class="brand" href="#">BFF Browser - Genomic Variations</a>
          <div class="nav-collapse collapse">
            <ul class="nav">
              <li class="dropdown">
                <a href="#" class="dropdown-toggle" data-toggle="dropdown">
                  Help <b class="caret"></b>
                </a>
                <ul class="dropdown-menu">
                  <li class="nav-header">Help</li>
                  <li>
                    <a href="https://b2ri-documentation.readthedocs.io/en/latest/data-ingestion/">
                      <span class="icon-question-sign"></span> Help Page
                    </a>
                  </li>
                  <li class="divider"></li>
                  <li class="nav-header">FAQs</li>
                  <li>
                    <a href="https://b2ri-documentation.readthedocs.io/en/latest/faq">
                      <span class="icon-question-sign"></span> FAQs Page
                    </a>
                  </li>
                </ul>
              </li>
              <li class="dropdown">
                <a href="#" class="dropdown-toggle" data-toggle="dropdown">
                  Links <b class="caret"></b>
                </a>
                <ul class="dropdown-menu">
                  <li class="nav-header">Contact</li>
                  <li>
                    <a href="mailto:manuel.rueda\@cnag.eu">
                      <span class="icon-envelope"></span> Author
                    </a>
                  </li>
                  <li class="divider"></li>
                  <li class="nav-header">Links</li>
                  <li>
                    <a href="https://www.cnag.crg.eu">
                      <span class="icon-home"></span> CNAG
                    </a>
                  </li>
                </ul>
              </li>
            </ul>
          </div><!--/.nav-collapse -->
        </div>
      </div>
    </div>
EOF
    return $navbar;
}

# Generates the start of the body section with project and job info plus download buttons
sub generate_body_start {
    my ( $project_dir, $id, $panel_counts_ref ) = @_;
    my $html = qq(  <div class="container">\n);
    foreach my $panel ( sort keys %$panel_counts_ref ) {
        my $panel_uc = ucfirst($panel);
        $html .=
qq(    <a class="btn pull-right" href="./$panel.json"><i class="icon-download"></i> $panel_uc JSON</a>\n);
    }
    $html .= qq(    <h4>Project &#9658; $project_dir</h4>\n);
    $html .= qq(    <h3>Job ID &#9658; $id &#9658; genomicVariationsVcf</h3>\n);
    $html .=
qq(    <p>Displaying variants with <strong>Annotation Impact</strong> values equal to <strong>HIGH</strong></p>\n);
    return $html;
}

# Generates the tabs and table sections for each panel
sub generate_table_tabs {
    my ( $panel_counts_ref, $header_ref, $assets_dir ) = @_;
    my @panels = sort keys %$panel_counts_ref;
    my $html   = qq(    <ul class="nav nav-tabs">\n);
    for my $i ( 0 .. $#panels ) {
        my $panel    = $panels[$i];
        my $panel_uc = ucfirst($panel);
        my $active   = $i == 0 ? 'active' : '';
        $html .=
qq(      <li class="$active"><a href="#tab-panel-$panel" data-toggle="tab">$panel_uc panel - $panel_counts_ref->{$panel} genes</a></li>\n);
    }
    $html .= qq(    </ul>\n);
    $html .= qq(    <div id="myTabContent" class="tab-content">\n);
    foreach my $panel (@panels) {

        # Example: setting "cardiopathy" as active if needed
        my $active_class = ( $panel eq 'cardiopathy' ) ? 'active' : '';
        $html .= generate_table( $panel, $active_class, $header_ref );
    }
    $html .= qq(    </div>\n);
    return $html;
}

# Generates an individual table section for a given panel
sub generate_table {
    my ( $panel, $active_class, $header_ref ) = @_;
    my $html =
qq(      <div class="tab-pane fade in $active_class" id="tab-panel-$panel">\n);
    $html .= qq(        <!-- TABLE -->\n);
    $html .=
qq(        <table id="table-panel-$panel" class="display table table-hover table-condensed">\n);
    $html .= qq(          <thead>\n            <tr>\n);
    foreach my $field (@$header_ref) {
        $html .= qq(              <th>$field</th>\n);
    }
    $html .=
qq(            </tr>\n          </thead>\n        </table>\n      </div>\n);
    return $html;
}

# Generates the footer section and closes the HTML
sub generate_footer {
    my $html = <<'EOF';
      <br /><p class="pagination-centered">BFF Browser - Genomic Variations</p> 
      <hr>
      <!-- FOOTER -->
      <footer>
          <p>&copy; 2021-2025 CNAG | Barcelona, Spain </p>
      </footer>
    </div><!-- /.container -->
  </body>
</html>
EOF
    return $html;
}

__END__

=head1 NAME

bff2html: A script to transform dataTables-JSON to HTML

=head1 SYNOPSIS

bff2html.pl -id your_id -assets-dir /path/foo/bar -panel-dir /path/web [-options]

     Arguments:                       
       -id              ID (string)
       -assets-dir      /path to directory with css, img and stuff.
       -panel-dir       /path to directory with gene panels

     Options:
       -h|help         Brief help message
       -man            Full documentation
       -debug          Print debugging (from 1 to 5, being 5 max)
       -verbose        Verbosity on

=head1 CITATION

The author requests that any published work that utilizes B<B2RI> includes a cite to the following reference:

Rueda, M, Ariosa R. "Beacon v2 Reference Implementation: a toolkit to enable federated sharing of genomic and phenotypic data". I<Bioinformatics>, btac568, https://doi.org/10.1093/bioinformatics/btac568

=head1 SUMMARY

Script to transform dataTables-JSON to HTML.

=head1 HOW TO RUN BFF2HTML

...

=head1 AUTHOR 

Written by Manuel Rueda, PhD. Info about CNAG can be found at L<https://www.cnag.eu>.

=head1 REPORTING BUGS

Report bugs or comments to <manuel.rueda@cnag.eu>.

=head1 COPYRIGHT

This PERL file is copyrighted. See the LICENSE file included in this distribution.

=cut
