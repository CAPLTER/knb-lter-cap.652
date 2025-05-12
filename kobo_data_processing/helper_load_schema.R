#' @title Delete survey200 schema and rebuild using most recent version in the
#' databaseDumps directory
#'
#' @note Calls a bash script in `helper_load_schema.sh` to rebuild the schema
#'
#' @param connection
#' (character) connection to PostgreSQL database in the form of a DBI
#' connection
#' 
helper_reload_schema <- function(connection = pg) {

  db_info <- DBI::dbGetInfo(connection)

  if (grepl("localhost", db_info$host, ignore.case = TRUE)) {

    DBI::dbExecute(
      conn      = pg,
      statement = "DROP SCHEMA IF EXISTS survey200 CASCADE ;"
    )

    # system() requires full path
    system("/home/srearl/Dropbox/development/esca_working/helper_load_schema.sh")

  } else {

    stop("not connected to local")

  }

}

helper_reload_schema()