# names of the output from Excel to csv converion a bit more palatable
# run this after soffice mediated export from Excel to csv
for i in *.csv ; do mv "$i" "${i/_-_all_versions_-_English_en_-/}" ; done
