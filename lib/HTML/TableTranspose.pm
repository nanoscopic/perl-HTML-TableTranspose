package HTML::TableTranspose;
use Exporter;
use Carp;
use Data::Dumper;
use HTML::Bare qw/xval forcearray/;
@ISA = qw(Exporter);
@EXPORT_OK = qw(flip_table);
use strict;
use warnings;
$HTML::TableTranspose::VERSION = '0.01';
sub new { my $pkg = shift; return bless { @_ }, $pkg; }

sub flip_table {
  my $html = shift;
  my ( $ob, $xml ) = HTML::Bare->new( text => $html );
  
  my $table = $xml->{'table'};
  my $trs = forcearray( $table->{'tr'} );
  my $tr1 = $trs->[0];
  my $cols = count_cols( $tr1 );
  my $rows = scalar @$trs;
  my @cells;
  
  my $y = 0;
  for my $tr ( @$trs ) {
    my $els = mix_els( $tr, 'td', 'th' );
    my $x = 0;
    my $curcell = $cells[ $y * $cols + $x ];
    
    for my $el ( @$els ) {
      while( $curcell ) {
        $x++;
        $curcell = $cells[ $y * $cols + $x ];
      }
      my $td = $el->[1];
      my $colspan = xval $td->{'colspan'};
      my $rowspan = xval  $td->{'rowspan'};
      swap_attributes( $td, 'colspan', 'rowspan' );
      swap_attributes( $td, 'align', 'valign', {
        left => 'top',
        right => 'bottom',
        top => 'left',
        bottom => 'right'
      } );
      $cells[ $y * $cols + $x ] = $el;
      if( $rowspan ) {
        my $ty = $y;
        while( $rowspan > 1 ) {
          $ty++;
          $cells[ $ty * $cols + $x ] = [ 'span', 0 ];
          $rowspan--;
        }
      }
      if( $colspan ) {
        while( $colspan > 1 ) {
          $x++;
          $cells[ $y * $cols + $x ] = [ 'span', 0 ];
          $colspan--;
        }
      }
      $x++;
    }
    $y++;
  }
  
  delete $table->{'tr'};
  $table->{'value'} = 'blah';
  my $tablexml = HTML::Bare::Object::html( 0, { table => $table } );
  $tablexml =~ s|</table>||;
  $tablexml =~ s|blah||;
  my $out = $tablexml;
  
  #print Dumper( \@cells );
  
  for( my $x=0; $x < $cols; $x++ ) {
    $out .= "<tr>";
    for( $y=0;$y<$rows;$y++ ) {
      my $cell = $cells[ $y * $cols + $x ];
      #print "y: $y, $cols: $cols, x: $x\n";
      my $type = $cell->[0];
      my $node = $cell->[1];
      next if( $type eq 'span' );
      my $xml = HTML::Bare::Object::html( 0, { $type => $node } );
      $out .= $xml;
    }
    $out .= "</tr>";
  }
  $out .= "</table>";
  return $out;
}

sub swap_attributes {
  my ( $node, $att1, $att2, $map ) = @_;
  my $a1 = $node->{ $att1 };
  my $a2 = $node->{ $att2 };
  if( $a1 && $map ) { $a1->{'value'} = $map->{ $a1->{'value'} }; }
  if( $a2 && $map ) { $a2->{'value'} = $map->{ $a2->{'value'} }; }
  
  if( $a1 ) { $node->{ $att2 } = $a1; } else { delete $node->{ $att2 }; }
  if( $a2 ) { $node->{ $att1 } = $a2; } else { delete $node->{ $att1 }; }
}

sub mix_els {
  my $parent = shift;
  my @all;
  for my $name ( @_ ) {
    my $nodes = forcearray( $parent->{$name} );
    for my $node ( @$nodes ) {
      push( @all, [ $name, $node ] );
    }
  }
  @all = sort {
    my $apos = $a->[1]{'_pos'};
    my $bpos = $b->[1]{'_pos'};
    $apos <=> $bpos;
  } @all;
  return \@all;
}

sub count_cols {
  my $tr = shift;
  my $tds = forcearray( $tr->{'td'} );
  my $ths = forcearray( $tr->{'th'} );
  my @nodes = ( @$tds, @$ths );
  my $cnt = 0;
  for my $td ( @nodes ) {
    if( $td->{'colspan'} ) {
      my $colspan = xval $td->{'colspan'};
      $cnt += $colspan;
    }
    else {
      $cnt++;
    }
  }
  return $cnt;
}

1;