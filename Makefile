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

.PHONY: 2018
