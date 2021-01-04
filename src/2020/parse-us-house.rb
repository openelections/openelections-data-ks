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

@candidates = {
  'Democratic' => { '1' => 'Barnett, Kali', '2' => 'De La Isla, Michelle', '3' => 'Davids, Sharice L.', '4' => 'Lombard, Laura' },
  'Republican' => { '1' => 'Mann, Tracey', '2' => 'LaTurner, Jake', '3' => 'Adkins, Amanda L.', '4' => 'Estes, Ron' },
  'Libertarian' => { '2' => 'Garrard, Robert', '3' => 'Hohe, Steven A.' }
}

def read_csv(filename)
  puts "County,Precinct,Race,Candidate,Party,Votes"
  CSV.foreach(filename, headers: true, header_converters: [:downcase], encoding: 'bom|utf-8') do |row|
    precinct = row[0]

    ['Democratic', 'Republican', 'Libertarian'].each do |party|
      %w( 1 2 3 4 ).each do |district|
        candidate = @candidates.dig(party, district)
        next if candidate.nil?
        out_row = process_csv_row(row, precinct, party, candidate, district)
        puts out_row if out_row
      end
    end
  end
end

def process_csv_row(row, precinct, party, candidate, district)
  votes = nil
  candidate_last_name = candidate.split(/, /).first.downcase
  row.each do |header, cell|
    next unless header
    next unless header.include?(candidate_last_name)
    if party == 'Democratic'
      votes = cell
    elsif party == 'Libertarian'
      votes = cell
    elsif party == 'Republican'
      votes = cell
    end
  end
  return unless votes
  cells = [
    @county,
    precinct,
    "U.S. House #{district}",
    candidate,
    party,
    votes
  ].to_csv
end

@county = ARGV[0]
read_csv(ARGV[1])
