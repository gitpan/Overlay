BEGIN { $| = 1; print "1..10\n"; }
END {print "not ok 1\n" unless $loaded;}

use Tie::Hash::Overlay qw(&overlay);
$loaded = 1;
print "ok 1\n";

$hashes = [ { a => 1, b => 200 }, { foo => bar } ];
$remain = {};
$a = overlay($hashes, $remain);
print "not " unless ref $a;
print "ok 2\n";
print "not " unless $$a{a} == 1 && $$a{b} == 200 && $$a{foo} eq 'bar';
print "ok 3\n";

overlay(\%b, $hashes);

print "not " unless $b{a} == 1 && $b{b} == 200 && $b{foo} eq 'bar';
print "ok 4\n";

push @{$hashes}, { c => xxx };

print "not " unless $b{c} eq 'xxx' && $$a{c} eq 'xxx';
print "ok 5\n";

@keys = sort keys %b;
@keys2 = sort keys %{$a};

for($i = 0; $i < @keys || $i < @keys2; $i++) {
    if($keys[$i] ne $keys2[$i]) { print "not "; last }
}

print "ok 6\n";

@values = sort values %b;
@values2 = sort values %{$a};

for($i = 0; $i < @values || $i < @values2; $i++) {
    if($values[$i] ne $values2[$i]) { print "not "; last }
}

print "ok 7\n";

$$a{baz} = 'wiffle';
print "not " unless $$a{baz} eq 'wiffle' && $$remain{baz} eq 'wiffle';
print "ok 8\n";

$exists = exists $b{foo};
delete $b{foo};
print "not " unless $exists && !exists $b{foo};
print "ok 9\n";

%b = ();

print "not " unless scalar keys %b == 0;
print "ok 10\n";
