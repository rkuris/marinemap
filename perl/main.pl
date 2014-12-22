#!perl
use File::Temp qw/tmpnam tempfile/;
use JSON;
use POSIX;
use Data::Dumper;
my %litchr = ( 1=> 'F', 2=>'Fl', 3=>'LFl', 4=>'Q', 5=>'VQ', 6=>'UQ', 7=>'Iso', 8=>'Oc', 9=>'IQ', 10=>'IVQ', 11=>'IUQ', 12=>'Mo', 13=>'FFl', 14=>'FlLFl', 15=>'OcFl', 16=>'FLFl', 17=>'Al.Oc', 18=>'Al.LFl', 19=>'Al.Fl', 20=>'Al.Gr', 25=>'Q', 26=>'VQ', 27=>'UQ', 28=>'Al', 29=>'Al.FFl' );
my %colour = ( 1=>'white', 2=>'black', 3=>'red', 4=>'green', 5=>'blue', 6=>'yellow', 7=>'grey', 8=>'brown', 9=>'amber', 10=>'violet', 11=>'orange', 12=>'magenta', 13=>'pink');

my %catcam = ( 1=>'north', 2=>'east', 3=>'south', 4=>'west');
my %catlam = ( 1=>'port', 2=>'starboard', 3=>'preferred_channel_starboard', 4=>'preferred_channel_port' );
my %catlamc = ( 1=>'green', 2=>'red', 3=>'green;red;green', 4=>'red;green;red' );
my %bcnshp = ( 1=>'pole', 2=>'withy', 3=>'tower', 4=>'lattice', 5=>'pile', 6=>'cairn', 7=>'buoyant' );

$id = 0;
my ( $osm, $osmoutname ) = tempfile("tXXXXXX", DIR => '.', SUFFIX => '.osm' );
print $osm q/<?xml version='1.0' encoding='UTF-8'?>
<osm version='0.6' upload='true' generator='enc2osm'>
/;
my ( $mapid, $description );
$mapid = '88887770';
$description = 'Cali Marine Map';

for my $sourcefile (@ARGV) {
    if ( $sourcefile =~ /\.000$/ ) {
	# LIGHTS
	my $lightjson = zerotojson($sourcefile, 'LIGHTS');
	my %lightmap;
	# create a map of the light locations so we can search for them when rendering beacons
	foreach my $feature ( @{ $lightjson->{'features'} } ) {
	    my $coord = $feature->{'geometry'}->{'coordinates'};
	    $lightmap{$feature->{'properties'}->{'LNAM'}} = $feature;
	}
	my $bcnjson = zerotojson($sourcefile, 'BCNLAT');
	foreach my $feature ( @{ $bcnjson->{'features'} } ) {
            my $props = $feature->{'properties'};
	    my $coord = $feature->{'geometry'}->{'coordinates'};
		    next if ref $coord->[1];
		    next if ref $coord->[0];
		    next unless $coord->[1];
		    next unless $coord->[0];
		    next if $coord->[1] < 10;

	    my $tags = " <tag k='seamark:type' v='beacon_lateral' />\n";
    	    $tags .= " <tag k='seamark:beacon_lateral:category' v='$catlam{$props->{CATLAM}}' />\n" if $props->{CATLAM};
    	    $tags .= " <tag k='seamark:beacon_lateral:colour' v='$catlamc{$props->{CATLAM}}' />\n" if $props->{CATLAM};
    	    $tags .= " <tag k='seamark:beacon_lateral:shape' v='$bcnshp{$props->{BCNSHP}}' />\n" if $props->{BCNSHP};
	    $tags .= " <tag k='seamark:beacon_lateral:ref' v='$props->{OBJNAM}' />\n" if $props->{OBJNAM};
	    $tags .= " <tag k='seamark:name' v='$1' />\n" if $props->{OBJNAM} =~ /.* ([^ ]*)$/;

	    if ( $props->{'LNAM_REFS'} && ref $props->{'LNAM_REFS'} eq 'ARRAY' ) {
	    	foreach my $lightref (@{$props->{'LNAM_REFS'}}) {
		    if (exists $lightmap{$lightref}) {
			my $light = $lightmap{$lightref};
                        my $props = $light->{'properties'};
			delete $lightmap{$lightref};
	    	        $tags .= "  <tag k='seamark:light:character' v='$litchr{$props->{LITCHR}}' />\n" if ($props->{'LITCHR'} && $litchr{$props->{'LITCHR'}});
	        	$tags .= "  <tag k='seamark:light:category' v='aero' />\n" if $props->{'CATLIT'} && $props->{'CATLIT'} == 5;
	        	$tags .= "  <tag k='seamark:light:height' v='$props->{HEIGHT}' />\n" if $props->{'HEIGHT'};
	        	$tags .= "  <tag k='seamark:light:multiple' v='$props->{MLTYLT}' />\n" if $props->{'MLTYLT'};
	        	$tags .= "  <tag k='seamark:light:range' v='$props->{VALNMR}' />\n" if $props->{'VALNMR'};
	    if ($props->{'COLOUR'}) {
		if ( $props->{'COLOUR'} =~ /,/) {
		    my $lid = 1;
		    for my $acolour (split(/,/, $props->{'COLOUR'})) {
		        $tags .= "  <tag k='seamark:light:$lid:colour' v='$colour{$acolour}' />\n" if $colour{$acolour};
			$lid++;
		    }
		} else {
		    my $acolour = $props->{'COLOUR'};
		    $tags .= "  <tag k='seamark:light:colour' v='$colour{$acolour}' />\n" if $colour{$acolour};
		}
	    }
	    $tags .= "  <tag k='seamark:light:group' v='$props->{SIGGRP}' />\n" if $props->{'SIGGRP'};
	    $tags .= "  <tag k='seamark:light:period' v='$props->{SIGPER}' />\n" if $props->{'SIGPER'};
	    $tags .= "  <tag k='seamark:light:sequence' v='$props->{SIGSEQ}' />\n" if $props->{'SIGSEQ'};
		    }
		}
	    }
	    print $osm node(--$id, {'lat'=>$coord->[1], 'lon'=>$coord->[0]}, $tags);
	}
        foreach my $feature ( values %lightmap ) {
            my $props = $feature->{'properties'};
	    my $coord = $feature->{'geometry'}->{'coordinates'};
		    next if ref $coord->[1];
		    next if ref $coord->[0];
		    next unless $coord->[1];
		    next unless $coord->[0];
		    next if $coord->[1] < 10;
	    my $tags = '';
	    $tags .= "  <tag k='seamark:type' v='light_major' />\n" if $props->{'VALNMR'};
	    $tags .= "  <tag k='seamark:type' v='light_minor' />\n" unless $props->{'VALNMR'};
	    $tags .= "  <tag k='seamark:light:character' v='$litchr{$props->{LITCHR}}' />\n" if ($props->{'LITCHR'} && $litchr{$props->{'LITCHR'}});
	    $tags .= "  <tag k='seamark:light:category' v='aero' />\n" if $props->{'CATLIT'} && $props->{'CATLIT'} == 5;
	    $tags .= "  <tag k='seamark:light:height' v='$props->{HEIGHT}' />\n" if $props->{'HEIGHT'};
	    $tags .= "  <tag k='seamark:light:multiple' v='$props->{MLTYLT}' />\n" if $props->{'MLTYLT'};
	    $tags .= "  <tag k='seamark:light:range' v='$props->{VALNMR}' />\n" if $props->{'VALNMR'};
	    $tags .= "  <tag k='name' v='$props->{OBJNAM}' />\n" if $props->{'OBJNAM'};
	    if ($props->{'COLOUR'}) {
		if ( $props->{'COLOUR'} =~ /,/) {
		    my $lid = 1;
		    for my $acolour (split(/,/, $props->{'COLOUR'})) {
		        $tags .= "  <tag k='seamark:light:$lid:colour' v='$colour{$acolour}' />\n" if $colour{$acolour};
			$lid++;
		    }
		} else {
		    my $acolour = $props->{'COLOUR'};
		    $tags .= "  <tag k='seamark:light:colour' v='$colour{$acolour}' />\n" if $colour{$acolour};
		}
	    }
	    $tags .= "  <tag k='seamark:light:group' v='$props->{SIGGRP}' />\n" if $props->{'SIGGRP'};
	    $tags .= "  <tag k='seamark:light:period' v='$props->{SIGPER}' />\n" if $props->{'SIGPER'};
	    $tags .= "  <tag k='seamark:light:sequence' v='$props->{SIGSEQ}' />\n" if $props->{'SIGSEQ'};

	    print $osm node(--$id, {'lat'=>$coord->[1], 'lon'=>$coord->[0]}, $tags);
        }
	undef $lightjson;

	# DEPTH AREAS
	my $deparejson = zerotojson($sourcefile, 'DEPARE');
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
	            print $osm "  <tag k='name' v='$props->{OBJNAM}' />\n" if $props->{'OBJNAM'};
		    # print $osm "  <tag k='name' v='$id' />\n"; # remove me
		    print $osm " </way>\n";
	        }
        }
	undef $deparejson;

	# DREDGED AREAS
	my $drgarejson = zerotojson($sourcefile, 'DRGARE');
        foreach my $feature ( @{ $drgarejson->{'features'} } ) {
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
		    print $osm "  <tag k='seamark:type' v='dredged' />\n";
		    # print $osm "  <tag k='name' v='$id' />\n"; # remove me
		    print $osm " </way>\n";
	        }
        }
	undef $drgarejson;

	# INDIVIDUAL SOUNDINGS
	my $sndjson = zerotojson($sourcefile, 'SOUNDG');
        foreach my $feature ( @{ $sndjson->{'features'} } ) {
            my $props = $feature->{'properties'};
	    foreach my $coord ( @{ $feature->{'geometry'}->{'coordinates'} } ) {
	        my $feet = mtofeet($coord->[2]);
	        print $osm node(--$id, {'lat'=>$coord->[1], 'lon'=>$coord->[0]}, "  <tag k='waterway' v='depth' />\n  <tag k='name' v='$feet' />" );
	    }
        }
	undef $sndjson;

	# DEPTH CONTOURS
	my $depjson = zerotojson($sourcefile, 'DEPCNT');
        foreach my $feature ( @{ $depjson->{'features'} } ) {
            my $props = $feature->{'properties'};
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
    }
}
        print $osm qq(</osm>\n);
        close($osm);
        print
qq(java -jar mkgmap-r3363/mkgmap.jar --style-file=mkgmap-r3363/styles/rk -n "$mapid" --description="$description" --country-name="USA" --country-abbr="US" --region-name="California" --region-abbr=CA --lower-case --family-name="CA Marine" --max-jobs --copyright-message="NOAA maps are free, does not meet chart carriage regulations"  --license-file=LICENSE $osmoutname\n);
        system
qq(java -jar mkgmap-r3363/mkgmap.jar --style-file=mkgmap-r3363/styles/rk -n "$mapid" --description="$description" --country-name="USA" --country-abbr="US" --region-name="California" --region-abbr=CA --lower-case --family-name="CA Marine" --max-jobs --copyright-message="NOAA maps are free, does not meet chart carriage regulations"  --license-file=LICENSE $osmoutname);

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
    return from_json($data) if $data;
    return { features=>[] };
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
