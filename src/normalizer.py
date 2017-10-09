#!/usr/local/bin/python3
# -*- coding: utf-8 -*-

# The MIT License (MIT)
# Copyright (c) 2016 Nick Kocharhook
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

import pdb
import csv
import os
import re
import argparse

def main():
	args = parseArguments()

	normalizer = Normalizer(args.path)

	if normalizer.ready and "matrix" not in normalizer.filename:
		normalizer.normalize()

def parseArguments():
	parser = argparse.ArgumentParser(description='Computer-aided normalization of openelections CSV files')
	parser.add_argument('path', type=str, help='path to a CSV file')

	return parser.parse_args()

class Normalizer(object):
	# validOffices = frozenset(['President', 'U.S. Senate', 'U.S. House', 'Governor', 'State Senate', 'State House', 'Attorney General', 'Secretary of State', 'State Treasurer'])
	validOffices = {'President': ['Pres'],
					'U.S. Senate': ['Senator', 'Senate'],
					'U.S. House': ['Rep', 'Congress', 'House'],
					'Governor': ['Gov'],
					'State Senate': ['Senator', 'Senate'],
					'State House': ['Rep', 'House'],
					'Attorney General': ['Gen'],
					'Secretary of State': ['Sec'],
					'State Treasurer': ['Trea'],
					'Voters': []}

	def __init__(self, path):
		self.path = path
		self.filename = os.path.basename(path)
		self.rows = []
		self.normalizedOffices = {}
		self.excludedOffices = []
		self.invalidOfficeException = KeyError("invalid office")

		try:
			self.pathSanityCheck(path)

			self.ready = True
		except Exception as e:
			print(f"ERROR: {e}")

	def normalize(self):
		self.parseFileAtPath(self.path)

	def pathSanityCheck(self, path):
		if not os.path.exists(path) or not os.path.isfile(path):
			raise FileNotFoundError("Can't find file at path %s" % path)

		if not os.path.splitext(path)[1] == ".csv":
			raise ValueError("Filename does not end in .csv: %s" % path)

		print("==> {}".format(path))

	def parseFileAtPath(self, path):
		fields = []

		with open(path, 'rU') as csvfile:
			self.reader = csv.DictReader(csvfile)
			fields = self.reader.fieldnames
			
			for index, row in enumerate(self.reader):
				try:
					self.normalizeCounty(row)
					self.normalizeOffice(row)
				except KeyError as e:
					# skip this row and do nothing
					print(f"Skipping row {index}: {row}")
				else:
					self.rows.append(row)

		with open(self.newPath(), 'w') as newfile:
			writer = csv.DictWriter(newfile, fields, lineterminator="\n")

			writer.writeheader()

			for row in self.rows:
				writer.writerow(row)

	def normalizeOffice(self, row):
		office = row['office']

		# Have we seen this one before?
		if office in self.normalizedOffices:
			row['office'] = self.normalizedOffices[office]

		elif office in self.excludedOffices:
			raise self.invalidOfficeException

		# If not, try to find it
		elif office not in Normalizer.validOffices:
			foundOffice = False

			for validOffice, substrings in Normalizer.validOffices.items():
				if any(substring in office for substring in substrings):
					print(row)
					response = input(f'\nOK to replace all instances of "{office}" with "{validOffice}"? [y/n] ')
					if response.lower() == 'y':
						# First, save the corrected office for the future
						self.normalizedOffices[office] = validOffice

						# Then, replace it
						row['office'] = validOffice
						foundOffice = True
						break

			if not foundOffice:
				print(row)
				response = input(f'\nOK to DELETE all rows with office "{office}"? [y/n] ')
				if response.lower() == 'y':
					# First, save the excluded office
					self.excludedOffices.append(office)

					# Delete row
					raise self.invalidOfficeException


	def normalizeCounty(self, row):
		row['county'] = row['county'].title()

	def newPath(self):
		(name, ext) = os.path.splitext(self.path)
		return name + '-normalized' + ext


# Default function is main()
if __name__ == '__main__':
	main()
