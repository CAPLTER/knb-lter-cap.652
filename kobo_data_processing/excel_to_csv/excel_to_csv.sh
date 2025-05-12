# convert downloaded Excel (from Kobo) to csv; converts each workbook sheet into a separate csv
soffice --convert-to csv:"Text - txt - csv (StarCalc)":44,34,UTF8,1,,0,false,true,false,false,false,-1 ESCA_tree_survey_-_all_versions_-_English_en_-_2024-04-22-18-39-45.xlsx --outdir ~/Dropbox/development/esca_working/
