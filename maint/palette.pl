#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Convert::Color;
use Convert::Color::HUSL;
use Convert::Color::RGB;

my @SEQ = qw(ibis:Issue ibis:Position ibis:Argument skos:Concept
           ibis:generalizes ibis:specializes ibis:suggests ibis:suggested-by
         ibis:questions ibis:questioned-by ibis:response ibis:responds-to
       ibis:supports ibis:supported-by ibis:opposes ibis:opposed-by);

my %MAP = (
    'ibis:Issue'         => [12,  45,  15],
    'ibis:Position'      => [128, 45,  15],
    'ibis:Argument'      => [266, 45,  15],
    'skos:Concept'       => [308, 45,  15],
    'ibis:generalizes'   => [261, 100, 55],
    'ibis:specializes'   => [265, 100, 37],
    'ibis:suggests'      => [62,  100, 85],
    'ibis:suggested-by'  => [55,  100, 80],
    'ibis:questions'     => [36,  100, 72],
    'ibis:questioned-by' => [27,  100, 65],
    'ibis:response'      => [350, 100, 29],
    'ibis:responds-to'   => [356, 100, 46],
    'ibis:supports'      => [124, 100, 78],
    'ibis:supported-by'  => [120, 90,  61],
    'ibis:opposes'       => [9,   100, 50],
    'ibis:opposed-by'    => [4,   78,  40],
);

my @VARIANTS = (
    [45,  5],
    [45, 15],
    [45, 30],
    [45, 40],
    [45, 70],
    [60, 90],
    [100, 50],
    [100, 90],
);

my ($min, $max) = do {
    my @len = sort { length $a <=> length $b } @SEQ;

    (length($len[0]), length($len[-1]));
};

my $pal = "\$PALETTE: (\n";
for my $i (0..$#SEQ) {
    my $key = $SEQ[$i];
    my @hsl = @{$MAP{$key}};

    my @hex;
    for my $v (@VARIANTS) {
        my $str = sprintf 'husl:%f,%f,%f', $hsl[0], @$v;
        my $col = Convert::Color->new($str)->as_rgb8;
        push @hex, '#' . $col->hex;
    }

    my $fmt = sprintf qq{   "%s": %s(%%s)%s\n}, $key,
        ' ' x ($max - length $key), ($i < $#SEQ ? ',' : '');
    $pal .= sprintf $fmt, join ', ', @hex;
}
$pal .= ");\n";

print $pal;
