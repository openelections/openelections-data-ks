#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dump 'dump';
use File::Slurper 'read_text';
use Text::CSV_XS 'csv';

my $usage     = "$0 path/to/sovc.txt path/to/results.csv county\n";
my $sovc_file = shift or die $usage;
my $csv_file  = shift or die $usage;
my $COUNTY    = shift or die $usage;

my %PARTIES = (
    D => 'Democratic',
    R => 'Republican',
    I => 'Indepedent',
    L => 'Libertarian',
);

my %results;

my $buf = read_text $sovc_file;

# \f is ascii 12 (form feed)
my @pages = split( /\f/, $buf );
my $page_count = 0;
PAGE: for my $page (@pages) {
    $page_count++;
    my @lines = split( /\n/, $page );    # assumes double-spacing

    # skip pages w/o Total Votes
    next PAGE unless $page =~ /Total\ +Votes/;

    # first line after Official Results is the race name
    my ($race_name) = ( $page =~ m/(?:Official Results|For\ +Precinct,\ +All\ +Counters,\ +All\ +Races)\s+(\S.+?)\n/ );

    printf( "%s => %s\n", $page_count, $race_name );

    my $line_count = 0;

    my @candidates;                      # array because order matters.

LINE: for my $line (@lines) {

        #printf( "[%s] %s\n", $line_count, $line );
        $line_count++;

        next LINE if $line =~ /Jurisdiction Wide/;    # meaningless header

        if ( $line =~ m/Total Votes/ ) {

            # header row. parse out candidate names.
            my ($candidate_frag) = ( $line =~ m/Total Votes\ +(\S+.+?)$/ );
            $candidate_frag
                =~ s/Write-In\ +Votes/Write-In Votes/;  # inconsistent spacing
            @candidates = split( /\ \ +/, $candidate_frag );
            $results{$race_name} ||= { candidates => \@candidates };
        }

        if ( @candidates && $line =~ m/\%/ ) {          # stats
            my ( $precinct, $registered, $counted, $total, $cand_totals )
                = ( $line
                    =~ m/^(\S+.+?)\ \ +(\d+)\ \ +(\d+)\ \ +(\d+)\ \ +(.+)$/ );
            $precinct =~ s/\s+$//;
            if ( $precinct eq 'Total' && $line_count == scalar(@lines) ) {
                $precinct = '_Total';   # avoid any weird namespace collisions
            }
            $results{$race_name}->{precincts}->{$precinct}->{_total} = $total;
            $results{$race_name}->{precincts}->{$precinct}->{_reg}
                = $registered;
            my $cand_idx = 0;
            while ( $cand_totals =~ m/(\d+)\ +([\d\.]+\%)/g ) {
                my $cand_votes = $1;
                my $cand_perc  = $2;
                $results{$race_name}->{precincts}->{$precinct}
                    ->{ $candidates[$cand_idx] }
                    = { _c => $cand_votes, _p => $cand_perc };
                $cand_idx++;
            }
        }
    }

    #dump \@candidates;
}

#dump \%results;

# quality control and csv creation
my @csv_rows;
RACE: for my $race ( sort keys %results ) {
    my $stats = $results{$race};
    my ( $office, $district ) = @{ parse_race($race) };
PRECINCT: for my $precinct ( sort keys %{ $stats->{precincts} } ) {
        if ( $precinct eq '_Total' ) {
            next PRECINCT;
        }
        my $candidates = $stats->{precincts}->{$precinct};
        if (!  qa_precinct($candidates) ) {
          warn "Total mismatch for $race in $precinct\n" . '=' x 50 . "\n";
        }
    CAND: for my $r ( sort keys %$candidates ) {
            my $r_stat = $candidates->{$r};
            next CAND if $r =~ m/^_/;

            my ( $party, $candidate ) = @{ parse_candidate($r) };
            my $votes = $r_stat->{_c};
            my $row   = [
                $COUNTY, $precinct,  $office, $district,
                $party,  $candidate, $votes
            ];
            push @csv_rows, $row;
        }
    }
}

# write it!
csv( in => \@csv_rows, out => $csv_file, sep_char => ',' );

# helper functions

sub qa_precinct {
    my ($r)     = @_;
    my $total   = $r->{_total};
    my $c_total = 0;
    for my $candidate ( grep { !/^_/ } keys %$r ) {
        $c_total += $r->{$candidate}->{_c};
    }
    if ( $total != $c_total ) {
        warn "Total mismatch: $total != $c_total " . dump($r) . "\n";
        return 0;
    }
    return 1;
}

sub parse_candidate {
    my ($cand_str) = @_;
    my ( $candidate, $p ) = ( $cand_str =~ m/^(.+?) \((\w)\w*\)/ );
    my $party = $PARTIES{ $p || '' } || '';
    $candidate ||= $cand_str;
    return [ $party, $candidate ];
}

sub parse_race {
    my ($race_str) = @_;
    my $office     = $race_str;
    my $district   = '';
    if ( $race_str =~ m/US Rep (\d)\S+ Dist/ ) {
        $district = $1;
        $office   = 'US House';
    }
    if ( $race_str =~ m/(\d+)\S+ Dist KS Rep/ ) {
        $district = $1;
        $office   = 'KS House';
    }
    return [ $office, $district ];
}
