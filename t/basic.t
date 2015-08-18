#!/use/bin/perl -w
use strict;
use HTML::Bare;
use Test::More tests => 8;

use_ok( 'HTML::TableTranspose', qw/flip_table/ );

my $t1 = "
<table>
  <tr>
    <td>h1</td><td>h2</td><td>h3</td>
  </tr>
  <tr>
    <td>d1</td><td>d2</td><td>d3</td>
  </tr>
</table>
";

my $t2 = flip_table( $t1 );
my ( $ob, $html ) = HTML::Bare->new( text => $t2 );
my $rows = $html->{'table'}{'tr'};
my $numrows = scalar @$rows;
is( $numrows, 3, 'correct number of rows' );
is( $rows->[0]{'td'}[0]{'value'}, 'h1' );
is( $rows->[1]{'td'}[0]{'value'}, 'h2' );
is( $rows->[2]{'td'}[0]{'value'}, 'h3' );
is( $rows->[0]{'td'}[1]{'value'}, 'd1' );
is( $rows->[1]{'td'}[1]{'value'}, 'd2' );
is( $rows->[2]{'td'}[1]{'value'}, 'd3' );