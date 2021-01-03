package App::streamfinder;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;

use Perinci::Object;

our %SPEC;

$SPEC{app} = {
    v => 1.1,
    summary => 'CLI for StreamFinder, a module to fetch actual raw streamable URLs from video & podcasts sites',
    description => <<'_',

Examples:

    % streamfinder https://www.youtube.com/watch?v=6yVIKvcPa6Q
    https://r5---sn-htgx20capjpq-jb3l.googlevideo.com/videoplayback?exp...

    % streamfinder https://www.youtube.com/watch?v=6yVIKvcPa6Q -l
    +--------------+------------------------- ...+-------+-------------+------------+--------------...+-----------...+-------------------------...+
    | artist       | description                 | genre | num_streams | stream_num | stream_url      | title        | url                        |
    +--------------+------------------------- ...+-------+-------------+------------+--------------...+-----------...+-------------------------...+
    | Powerful JRE | Another hilarious moment ...|       | 1           | 1          | https://r5---...| Pinky And ...| https://www.youtube.com/...|
    +--------------+--------------------------...+-------+-------------+------------+--------------...+-----------...+-------------------------...+

    % streamfinder https://www.youtube.com/watch?v=6yVIKvcPa6Q https://www.youtube.com/watch?v=6yzVtlUI02w --json
    ...

_
    args => {
        urls => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'url',
            schema => ['array*', of=>'str*'],
            req => 1,
            pos => 0,
            slurpy => 1,
        },
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub app {
    require StreamFinder;

    my %args = @_;

    my $envres = envresmulti();
    my $i = -1;
    for my $url (@{ $args{urls} }) {
        $i++;
        my $station = StreamFinder->new($url);
        unless ($station) {
            $envres->add_result(500, "Invalid URL or no streams found: $url", {item_id=>$i});
            next;
        }
        my @streams = $station->get;
        for my $j (0..$#streams) {
            $envres->add_result(200, "OK", {payload=>{
                url=>$url,
                stream_num=>$j+1,
                num_streams=>scalar(@streams),
                stream_url=>$streams[$j],
                title=>$station->getTitle,
                description=>$station->getTitle('desc'),
                artist=>$station->{artist},
                genre=>$station->{genre},
            }, item_id=>$i});
        }
    }

    my $res = $envres->as_struct;
    $res->[2] //= [];
    if (!$args{detail} && @{ $args{urls} } == 1 && @{ $res->[2] } == 1) {
        $res->[2] = $res->[2][0]{stream_url};
    }
    $res;
}

1;
#ABSTRACT:


=head1 SEE ALSO

L<StreamFinder>

=cut
