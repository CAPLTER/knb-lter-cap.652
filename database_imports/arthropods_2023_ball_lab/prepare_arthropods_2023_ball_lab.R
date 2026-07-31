args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 2) {
  stop(
    "Usage: prepare_arthropods_2023_ball_lab.R INPUT.csv OUTPUT.csv",
    call. = FALSE
  )
}

input_path <- args[[1]]
output_path <- args[[2]]

expected_columns <- c(
  "sample_date",
  "site_code",
  "sweepnet_sample_type",
  "substratum",
  "arthropod_scientific_name",
  "number_of_arthropods",
  "number_immature",
  "number_winged",
  "notes"
)

incoming <- read.csv(
  input_path,
  colClasses = "character",
  check.names = FALSE,
  fileEncoding = "UTF-8-BOM",
  na.strings = "NA",
  stringsAsFactors = FALSE
)

if (!identical(names(incoming), expected_columns)) {
  stop("CSV columns differ from the reviewed input", call. = FALSE)
}

if (nrow(incoming) != 384) {
  stop(
    sprintf("Expected 384 source rows; found %s", nrow(incoming)),
    call. = FALSE
  )
}

required_text <- c(
  "sample_date",
  "site_code",
  "sweepnet_sample_type",
  "substratum",
  "arthropod_scientific_name",
  "number_of_arthropods"
)

if (any(vapply(
  incoming[required_text],
  function(x) any(is.na(x) | trimws(x) == ""),
  logical(1)
))) {
  stop("Required source fields contain blank values", call. = FALSE)
}

is_unsigned_integer <- function(x) {
  is.na(x) | grepl("^[0-9]+$", x)
}

for (column in c(
  "number_of_arthropods",
  "number_immature",
  "number_winged"
)) {
  if (!all(is_unsigned_integer(incoming[[column]]))) {
    stop(sprintf("%s contains a malformed value", column), call. = FALSE)
  }
}

original_date <- as.Date(incoming$sample_date, format = "%m/%d/%Y")
if (any(is.na(original_date))) {
  stop("One or more sample dates could not be parsed", call. = FALSE)
}

corrected_date <- original_date
date_corrections <- data.frame(
  sample_date = c(
    "5/31/2022",
    "3/20/2023",
    "3/29/2023",
    "4/14/2023",
    "4/19/2023",
    "6/3/2023"
  ),
  site_code = c("AB22", "E12", "F12", "X15", "V20", "AB17"),
  corrected_date = as.Date(c(
    "2023-05-31",
    "2023-03-30",
    "2023-03-30",
    "2023-04-13",
    "2023-04-14",
    "2023-06-06"
  )),
  stringsAsFactors = FALSE
)

for (i in seq_len(nrow(date_corrections))) {
  selected <- incoming$sample_date == date_corrections$sample_date[[i]] &
    incoming$site_code == date_corrections$site_code[[i]]
  corrected_date[selected] <- date_corrections$corrected_date[[i]]
}

stripped_substratum <- sub(
  "\\s+sp\\.?$",
  "",
  trimws(incoming$substratum),
  ignore.case = TRUE
)

vegetation_scientific_name <- stripped_substratum
vegetation_scientific_name[
  incoming$site_code == "AA21" & stripped_substratum == "Tecoma"
] <- "Tecoma stans"
vegetation_scientific_name[
  stripped_substratum == "Cascabela thevetia"
] <- "Thevetia peruviana"
vegetation_scientific_name[
  stripped_substratum == "Encilia farinosa"
] <- "Encelia farinosa"
vegetation_scientific_name[
  stripped_substratum == "Prosopsis"
] <- "Prosopis"
vegetation_scientific_name[
  stripped_substratum == "Salvia rosmarinus"
] <- "Rosmarinus officinalis"

insect_scientific_name <- trimws(incoming$arthropod_scientific_name)
insect_scientific_name[insect_scientific_name == "None"] <- "Unknown"

extract_replicate <- function(note) {
  if (is.na(note) || trimws(note) == "") {
    return(NA_integer_)
  }

  matched <- regexec("#\\s*([123])", note)
  values <- regmatches(note, matched)[[1]]
  if (length(values) == 0) NA_integer_ else as.integer(values[[2]])
}

replicate_number <- vapply(
  incoming$notes,
  extract_replicate,
  integer(1)
)
selected_rank <- ifelse(is.na(replicate_number), 1L, replicate_number)

prepared <- data.frame(
  source_row = seq_len(nrow(incoming)),
  original_date = format(original_date, "%Y-%m-%d"),
  corrected_date = format(corrected_date, "%Y-%m-%d"),
  site_code = trimws(incoming$site_code),
  sweepnet_sample_type = trimws(incoming$sweepnet_sample_type),
  original_substratum = trimws(incoming$substratum),
  vegetation_scientific_name = vegetation_scientific_name,
  original_insect_name = trimws(incoming$arthropod_scientific_name),
  insect_scientific_name = insect_scientific_name,
  count_of_insect = as.integer(incoming$number_of_arthropods),
  number_immature = as.integer(incoming$number_immature),
  number_winged = as.integer(incoming$number_winged),
  original_notes = ifelse(
    is.na(incoming$notes) | trimws(incoming$notes) == "",
    NA_character_,
    trimws(incoming$notes)
  ),
  replicate_number = replicate_number,
  selected_rank = as.integer(selected_rank),
  stringsAsFactors = FALSE
)

if (sum(prepared$count_of_insect) != 5098) {
  stop("Prepared arthropod total is not 5098", call. = FALSE)
}

zero_rows <- prepared$count_of_insect == 0 &
  prepared$site_code == "AB22" &
  prepared$vegetation_scientific_name == "Lactuca serriola" &
  prepared$insect_scientific_name == "Unknown"
if (sum(zero_rows) != 1) {
  stop("Expected AB22 zero-organism observation was not found", call. = FALSE)
}

ac19_nerium <- prepared$site_code == "AC19" &
  prepared$vegetation_scientific_name == "Nerium oleander"
ac19_second <- ac19_nerium &
  !is.na(prepared$original_notes) &
  prepared$original_notes == "Oleander#2"
if (
  sum(ac19_nerium) != 5 ||
  sum(ac19_second, na.rm = TRUE) != 1 ||
  prepared$selected_rank[which(ac19_second)] != 2 ||
  any(prepared$selected_rank[ac19_nerium & !ac19_second] != 1)
) {
  stop("AC19 Nerium assignment rule failed", call. = FALSE)
}

write.csv(
  prepared,
  output_path,
  row.names = FALSE,
  na = "",
  quote = TRUE
)

message(
  sprintf(
    "Prepared %s rows; total abundance %s; corrected-date rows %s.",
    nrow(prepared),
    sum(prepared$count_of_insect),
    sum(prepared$original_date != prepared$corrected_date)
  )
)
