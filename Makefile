2018:
	ruby src/parse-csv.rb -v -d 20181106 -o 2018/counties/ -t general ../openelections-sources-ks/2018/2018G_KS_*
	perl -pi -e 's,Governor / Lt. Governor,Governor,g' 2018/counties/*csv
	perl -pi -e 's,United States House of Representatives,U.S. House,g' 2018/counties/*csv
	perl -pi -e 's,Kansas House of Representatives,State House,g' 2018/counties/*csv
	perl -pi -e 's/,(\w{2})$$/,0000$$1/g' 2018/counties/*csv
	perl -pi -e 's/,(\w{3})$$/,000$$1/g' 2018/counties/*csv
	perl -pi -e 's/,(\w{4})$$/,00$$1/g' 2018/counties/*csv
	perl -pi -e 's/,(\w{5})$$/,0$$1/g' 2018/counties/*csv
	perl -pi -e 's/,000vtd$$/,vtd/g' 2018/counties/*csv

2020-transform:
	ruby src/2020/parse-johnson-court-appeals.rb ../openelections-sources-ks/2020/2020_General_Election_Court_of_Appeals_results_by_precinct/JOHNSON.csv > 2020/johnson-court-appeals.csv
	ruby src/2020/parse-sedgwick-court-appeals.rb ../openelections-sources-ks/2020/2020_General_Election_Court_of_Appeals_results_by_precinct/SEDGWICK.csv > 2020/sedgwick-court-appeals.csv
	ruby src/2020/parse-shawnee-court-appeals.rb ../openelections-sources-ks/2020/2020_General_Election_Court_of_Appeals_results_by_precinct/SHAWNEE.csv > 2020/shawnee-court-appeals.csv
	ruby src/2020/parse-wyandotte-court-appeals.rb ../openelections-sources-ks/2020/2020_General_Election_Court_of_Appeals_results_by_precinct/WYANDOTTE.csv > 2020/wyandotte-court-appeals.csv
	ruby src/2020/parse-supreme-court.rb Johnson ../openelections-sources-ks/2020/2020_General_Election_Supreme_Court_Justice_results_by_precinct/JOHNSON.csv > 2020/johnson-supreme-court.csv
	ruby src/2020/parse-supreme-court.rb Sedgwick ../openelections-sources-ks/2020/2020_General_Election_Supreme_Court_Justice_results_by_precinct/SEDGWICK.csv > 2020/sedgwick-supreme-court.csv
	ruby src/2020/parse-supreme-court.rb Shawnee ../openelections-sources-ks/2020/2020_General_Election_Supreme_Court_Justice_results_by_precinct/SHAWNEE.csv > 2020/shawnee-supreme-court.csv
	ruby src/2020/parse-supreme-court.rb Wyandotte ../openelections-sources-ks/2020/2020_General_Election_Supreme_Court_Justice_results_by_precinct/WYANDOTTE.csv > 2020/wyandotte-supreme-court.csv
	ruby src/2020/parse-president.rb Johnson ../openelections-sources-ks/2020/2020_General_Election_President_results_by_precinct/Johnson.csv > 2020/johnson-president.csv
	ruby src/2020/parse-president.rb Sedgwick ../openelections-sources-ks/2020/2020_General_Election_President_results_by_precinct/Sedgwick.csv > 2020/sedgwick-president.csv
	ruby src/2020/parse-president.rb Shawnee ../openelections-sources-ks/2020/2020_General_Election_President_results_by_precinct/Shawnee.csv > 2020/shawnee-president.csv
	ruby src/2020/parse-president.rb Wyandotte ../openelections-sources-ks/2020/2020_General_Election_President_results_by_precinct/Wyandotte.csv > 2020/wyandotte-president.csv
	ruby src/2020/parse-ks-house.rb Johnson ../openelections-sources-ks/2020/2020_General_Election_Kansas_House_of_Representatives_results_by_precinct/JOHNSON.csv > 2020/johnson-state-house.csv
	ruby src/2020/parse-ks-house.rb Sedgwick ../openelections-sources-ks/2020/2020_General_Election_Kansas_House_of_Representatives_results_by_precinct/SEDGWICK.csv > 2020/sedgwick-state-house.csv
	ruby src/2020/parse-ks-house.rb Shawnee ../openelections-sources-ks/2020/2020_General_Election_Kansas_House_of_Representatives_results_by_precinct/SHAWNEE.csv > 2020/shawnee-state-house.csv
	ruby src/2020/parse-ks-house.rb Wyandotte ../openelections-sources-ks/2020/2020_General_Election_Kansas_House_of_Representatives_results_by_precinct/WYANDOTTE.csv > 2020/wyandotte-state-house.csv

2020-mkdir:
	mkdir -p 2020/counties

2020-parse-sos:
	ruby src/parse-csv.rb -o 2020/counties -t general -d 20201103 ../openelections-sources-ks/2020/2020_General_Election_*/*csv
	ruby src/parse-csv.rb -o 2020/counties -t general -d 20201103 2020/*.csv

2020-normalize:
	perl -pi -e 's,United States House of Representatives,U.S. House,g' 2020/counties/*csv
	perl -pi -e 's,United States Senate,U.S. Senate,g' 2020/counties/*csv
	perl -pi -e 's,Kansas House of Representatives,State House,g' 2020/counties/*csv
	perl -pi -e 's,Kansas Senate,State Senate,g' 2020/counties/*csv
	perl -pi -e 's,President / Vice President,President,g' 2020/counties/*csv

2020: 2020-mkdir 2020-transform 2020-parse-sos 2020-normalize

.PHONY: 2018 2020
