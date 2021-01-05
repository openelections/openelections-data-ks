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
require 'zlib'
require 'pp'

# filename template
# date__state__{party}__{special}__election_type__{jurisdiction}{office}__{office_district}__{reporting_level}.format
#
# header template
# county,precinct,office,district,party,candidate,votes
#

require 'optparse'

@options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    @options[:verbose] = v
  end
  opts.on("-d=YMD", "--date=YMD", String, "Election date") do |d|
    @options[:date] = d
  end
  opts.on("-o=DIR", "--outdir=DIR", String, "Output directory") do |d|
    @options[:out] = d
  end
  opts.on('-t=TYPE', "--type=TYPE", String, "Election type") do |t|
    @options[:type] = t
  end
end.parse!

def csv_out_file(county)
  @options[:out] ||= '.'
  @options[:out] + '/' + sprintf("%s__ks__%s__%s__precinct.csv",
                          (@options[:date] || 'yyyymmdd'),
                          (@options[:type] || 'general'),
                          county.downcase,
                        )
end

def write_to_csv(filepath, row)
  fh = fh_for(filepath)
  new_row = format_csv_row(row)
  fh.write(new_row)
end

def fh_for(filepath)
  @_filehandles ||= {}
  @_filehandles[filepath] ||= begin
    fh = File.new(filepath, 'w')
    fh.write("county,precinct,office,district,party,candidate,votes,vtd\n")
    fh
  end
end

def format_csv_row(row)
  office = (row['race'] || row['office'])
  district = (row['district'] || nil)
  if district.nil? and office =~ /\d+$/
    district = office.dup
    district.gsub!(/^.+\ (\d+)$/, '\1')
    office.gsub!(/^(.+)\ (\d+)$/, '\1')
  end
  cells = [
    row['county'],
    row['precinct'],
    office,
    district,
    (row['party']),
    (row['candidate']).strip,
    (row['votes']),
    (row['vtd']),
  ].to_csv
end

def process_csv_row(row)
  if !row['county']
    STDERR.puts "No county in row: #{row.inspect}"
  else
    write_to_csv(csv_out_file(row['county']), row)
  end
end

def read_csv(filename)
  CSV.foreach(filename, headers: true, header_converters: [:downcase], encoding: 'bom|utf-8') do |row|
    process_csv_row(row)
  end
end

def read_csv_gz(filename)
  Zlib::GzipReader.open(filename) do |gzip|
    csv = CSV.new(gzip, headers: true, header_converters: [:downcase])
    csv.each do |row|
      process_csv_row(row) 
    end
  end
end
  
ARGV.each do |filename|
  puts filename
  if filename.match(/\.csv$/)
    read_csv(filename)
  elsif filename.match(/\.csv\.gz$/)
    read_csv_gz(filename)
  else
    puts "Unsupported file format: #{filename}";
  end
end
