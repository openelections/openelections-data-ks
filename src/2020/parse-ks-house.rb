#!/usr/bin/env ruby

# The MIT License (MIT)
# Copyright (c) 2017 Peter Karman
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'csv'
require 'pp'

# pattern is top 2 header rows must be combined to conform with SOS style
# we output to the KS SOS format, so that we can import to this repo with parse-csv.rb
# output header: County,Precinct,Race,Candidate,Party,Votes

# some counties are missing party affiliation (e.g. Johnson)
# so pull down master list from SOS to look up
@sos_results = 'https://raw.githubusercontent.com/statedemocrats/ks-sos-unofficial-stats/main/kssos_ent.csv'

def read_or_cache_sos_results
  tmp_file = '/tmp/kssos_ent.csv'
  if !File.exists?(tmp_file)
    system("curl -s #{@sos_results} > #{tmp_file}")
  end
  CSV.read(tmp_file, headers: true, header_converters: :symbol).map(&:to_h).map { |r| [r[:name], r] }.to_h
end

def read_csv(filename)
  puts "County,Precinct,Race,Candidate,Party,Votes"
  offices = nil
  candidates = nil
  sos_results = read_or_cache_sos_results
  CSV.foreach(filename, header_converters: [:downcase], encoding: 'bom|utf-8') do |row|
    # first 2 rows are headers, but some files contain multiple headers
    if row[0] == 'Precinct' or row[0] == 'PRECINCT NAME'
      offices = row
      candidates = nil
      next
    elsif !row[0] and !candidates
      candidates = row
      next
    end

    race_rows = {}
    candidates.each_index do |candidate_idx|
      candidate = candidates[candidate_idx]
      next if candidate.nil?
      next if candidate == 'UNDER VOTES'
      next if candidate == 'OVER VOTES'
      next if candidate == 'Write-in Totals'
      next if candidate == 'Total Votes Cast'

      race = offices[candidate_idx]
      if race.nil?
        idx = candidate_idx.dup
        while idx > 0 and race.nil?
          race = offices[idx]
          idx -= 1
        end
      end

      next unless race =~ /State Rep/

      votes = row[candidate_idx]
      race_rows[race] ||= []
      race_rows[race] << [votes.to_i, process_csv_row(row[0], candidate.dup, race, votes, sos_results)]
    end

    # only print rows where the vote total for the race in the precinct is > 0
    race_rows.each do |race, results|
      total_votes = 0
      results.each { |r| total_votes += r[0] }
      if total_votes > 0
        results.each { |r| puts r[1] }
      end
    end
  end
end

def process_csv_row(precinct, candidate, race, votes, sos_results)
  #puts "precinct=#{precinct} candidate=#{candidate} race=#{race} votes=#{votes}"
  party = nil
  if candidate =~ /DEM/i or sos_results.dig(candidate, :party) == 'D'
    party = 'Democratic'
  elsif candidate =~ /LIB/i or sos_results.dig(candidate, :party) == 'L'
    party = 'Libertarian'
  elsif candidate =~ /REP/i or sos_results.dig(candidate, :party) == 'R'
    party = 'Republican'
  end
  candidate.gsub!(/\ ?DEM|LIB|REP\ ?/i, '')
  if race =~ /.*State Representative (\d+)\w+ District/
    race.gsub!(/.*State Representative (\d+)\w+ District/, 'State Representative \1')
  end
  cells = [
    @county,
    precinct,
    race,
    candidate.strip,
    party,
    votes
  ].to_csv
end

@county = ARGV[0]
read_csv(ARGV[1])
