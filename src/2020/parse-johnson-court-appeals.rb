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

@districts = %w( 4 6 8 9 14 )
@candidates = {
  '4' => 'Warner, Sarah E.',
  '6' => 'Bruns, David E.',
  '8' => 'Atcheson, G. Gordon',
  '9' => 'Arnold-Burger, Karen M.',
  '14' => 'Gardner, Kathryn'
}

def read_csv(filename)
  puts "County,Precinct,Race,Candidate,Party,Votes"
  CSV.foreach(filename, header_converters: [:downcase], encoding: 'bom|utf-8') do |row|
    next if !row[0]
    next if row[0] == 'COUNTY TOTALS'
    next if row[0] == 'PRECINCT NAME'

    votes = {}
    @districts.each_index do |district_idx|
      district = @districts[district_idx]
      votes['yes'] = row[(district_idx * 4) + 1]
      votes['no'] = row[(district_idx * 4) + 2]
      ['yes', 'no'].each do |bool|
        new_row = process_csv_row(row, district, bool, votes[bool])
        puts new_row
      end
    end
  end
end

def process_csv_row(row, district, bool, votes)
  cells = [
    'Johnson',
    row[0],
    "Court of Appeals #{district}",
    "#{@candidates[district]} - \"#{bool.upcase}\"",
    nil,
    votes
  ].to_csv
end

read_csv(ARGV.first)
