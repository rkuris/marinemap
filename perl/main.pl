#!perl
use File::Temp qw/tmpnam tempfile/;
use JSON;
use POSIX;
use Data::Dumper;

for my $sourcefile (@ARGV) {
    if ( $sourcefile =~ /\.000$/ ) {
        my ( $mapid, $description );
	$depjson = zerotojson($sourcefile, 'DEPCNT');
	$sndjson = zerotojson($sourcefile, 'SOUNDG');
	$deparejson = zerotojson($sourcefile, 'DEPARE');

        ( $osm, $osmoutname ) = tempfile("tXXXXXX", DIR => '.', SUFFIX => '.osm' );

        print $osm q/<?xml version='1.0' encoding='UTF-8'?>
<osm version='0.6' upload='true' generator='enc2osm'>
/;

        $id = 0;
        foreach my $feature ( @{ $deparejson->{'features'} } ) {
            my $props = $feature->{'properties'};
		my $startid = $id - 1;
		foreach my $coord ( @{ $feature->{'geometry'}->{'coordinates'}->[0] } ) {
		    next if ref $coord->[1];
		    next if ref $coord->[0];
		    next unless $coord->[1];
		    next unless $coord->[0];
		    next if $coord->[1] < 10;
		    print $osm node(--$id, {'lat'=>$coord->[1], 'lon'=>$coord->[0]});
		}
		if ($startid != $id - 1) {
		    $id--;
		    print $osm
" <way id='$id' uid='401715' user='rkuris' visible='true' version='2'>\n";
		    for ( my $iid = $startid ; $iid > $id ; --$iid ) {
		        print $osm "  <nd ref='$iid' />\n";
		    }
		    print $osm "  <nd ref='$startid' />\n";
		    $feet = mtofeet( $props->{'DRVAL1'} );
		    print $osm "  <tag k='depth:area' v='$feet' />\n";
		    print $osm "  <tag k='seamark:type' v='depth_area' />\n";
		    # print $osm "  <tag k='name' v='$id' />\n"; # remove me
		    print $osm " </way>\n";
	        }
        }

        foreach my $feature ( @{ $sndjson->{'features'} } ) {
            my $props = $feature->{'properties'};
	    foreach my $coord ( @{ $feature->{'geometry'}->{'coordinates'} } ) {
	        my $feet = mtofeet($coord->[2]);
	        print $osm node(--$id, {'lat'=>$coord->[1], 'lon'=>$coord->[0]}, "  <tag k='waterway' v='depth' />\n  <tag k='name' v='$feet' />" );
	    }
        }
        foreach my $feature ( @{ $depjson->{'features'} } ) {
            my $props = $feature->{'properties'};
            unless ($mapid) {
                my $sorind = $props->{'SORIND'};
		if ($sorind !~ /,H-/) {
                    $mapid = $sorind;
                    $mapid =~ s/[^0-9]//g;
                    $mapid .= '0' x ( 8 - ( length $mapid ) );
                    $description = $1 if ( $sorind =~ /^[^,]*,[^,]*,[^,]*,([^,]*)/ );
                    $description = $1 if ( !$description && $sourcefile =~ m:.*?/(.*?)\.000: );
		}
	    }
	    if ( $props->{VALDCO} > 0 ) {
		my $startid = $id - 1;
		foreach
		  my $coord ( @{ $feature->{'geometry'}->{'coordinates'} } )
		{
		    next if ref $coord->[1];
		    next if ref $coord->[0];
		    next unless $coord->[1];
		    next unless $coord->[0];
		    next if $coord->[1] < 10;
		    print $osm node(--$id, {'lat'=>$coord->[1], 'lon'=>$coord->[0]});
		}
		if ($startid != $id - 1) {
		    $id--;
		    print $osm
" <way id='$id' uid='401715' user='rkuris' visible='true' version='2'>\n";
		    for ( my $iid = $startid ; $iid > $id ; --$iid ) {
		        print $osm "  <nd ref='$iid' />\n";
		    }
		    $feet = mtofeet( $props->{'VALDCO'} );
		    print $osm "  <tag k='depth:contour' v='$feet' />\n";
		    print $osm " </way>\n";
		}
	    }

        }
        print $osm qq(</osm>\n);
        close($osm);
        print
qq(java -jar mkgmap-r3363/mkgmap.jar --style-file=mkgmap-r3363/styles/rk -n $mapid --transparent --description="$description" $osmoutname\n);
        system
qq(java -jar mkgmap-r3363/mkgmap.jar --style-file=mkgmap-r3363/styles/rk -n $mapid --transparent --description="$description" $osmoutname);
    }
}

sub mtofeet
{
    return floor( $_[0] * 3.28084 + .5 );
}
sub zerotojson
{
    my ($sourcefile, $type) = @_;
    my $tmpfilename = tmpnam();
    print "ogr2ogr -f GeoJSON '$tmpfilename' '$sourcefile' $type\n";
    system("ogr2ogr -f GeoJSON '$tmpfilename' '$sourcefile' $type");
    open( $fh, '<', $tmpfilename ) || die;
    my $data;
    {
	local $/ = undef;
	$data = <$fh>;
    }
    close $fh;
    unlink $tmpfilename;
    return from_json($data);
}
sub node
{
    my ($id, $opts, $tags) = @_;
    $res = " <node id='$id' uid='401715' user='rkuris' visible='true' version='2' ";
    for my $opt (keys %$opts) {
        $res .= "$opt='$opts->{$opt}' ";
    }
    if ($tags) {
        $res .= ">\n$tags </node>\n"
    } else {
        $res .=" />\n";
    }
    return $res;
}
