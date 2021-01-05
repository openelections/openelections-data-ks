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
  'Democratic' => 'Bollier, Barbara',
  'Republican' => 'Marshall, Roger',
  'Libertarian' => 'Buckley, Jason',
}

def read_csv(filename)
  puts "County,Precinct,Race,Candidate,Party,Votes"
  CSV.foreach(filename, headers: true, header_converters: [:downcase], encoding: 'bom|utf-8') do |row|
    precinct = row[0]

    ['Democratic', 'Republican', 'Libertarian'].each do |party| 
      puts process_csv_row(row, precinct, party)
    end
  end
end

def process_csv_row(row, precinct, party)
  votes = nil
  row.each do |header, cell|
    if party == 'Democratic' and header =~ /bollier/i
      votes = cell
    elsif party == 'Libertarian' and header =~ /buckley/i
      votes = cell
    elsif party == 'Republican' and header =~ /marshall/i
      votes = cell
    end
  end
  cells = [
    @county,
    precinct,
    "U.S. Senate",
    @candidates[party],
    party,
    votes
  ].to_csv
end

@county = ARGV[0]
read_csv(ARGV[1])
