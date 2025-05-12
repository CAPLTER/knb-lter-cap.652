DBI::dbGetInfo(pg)

DBI::dbExecute(
    conn      = pg,
    statement = "
    CREATE TEMPORARY TABLE contacts (
    id SERIAL PRIMARY KEY,
    name VARCHAR (100),
    phones TEXT []
    )
    ;
"
)

DBI::dbExecute(
    conn      = pg,
    statement = "
    INSERT INTO contacts (name, phones) VALUES('John Doe', ARRAY [
    '(408)-589-5846','(408)-589-5555' ]) ;
    "
)

from_db <- DBI::dbGetQuery(pg, "SELECT * FROM contacts ;")

# does not work, inserts two rows

tibble::tribble(
    ~name, ~phones,
    "Stevie Nicks", c("(555)-589-5846", "(555)-589-5555")
) |>
    glue::glue_data_sql(
        "INSERT INTO contacts (name, phones) VALUES ({name}, {phones}) ;",
        .con = DBI::ANSI()
    )

array_insert <- tibble::tribble(
    ~name, ~phones,
    "Steve Miller", "(559)-589-5846",
    "Steve Miller", "(980)-721-5846"
) |>
    dplyr::group_by(name) |>
    dplyr::summarise(phones_array = paste0(phones, collapse = ",")) |>
    dplyr::ungroup() |>
    glue::glue_data_sql(
        "INSERT INTO contacts (name, phones) VALUES ( { name }, ARRAY [{ phones_array }] ) ;",
        .con = DBI::ANSI()
    )

DBI::dbWithTransaction(
    conn = pg,
    {
        purrr::walk(
            .x = array_insert,
            .f = ~ DBI::dbExecute(
                statement = .x,
                conn      = pg
            )
        )
    }
)

from_db <- DBI::dbGetQuery(pg, "SELECT * FROM contacts ;")

vs <- DBI::dbGetQuery(pg, "SELECT * FROM survey200.vegetation_samples ;")


veg_taxa <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT 
    vegetation_taxon_id,
    vegetation_scientific_name
  FROM survey200.vegetation_taxon_list
  ;
  "
)

my_path <- getwd()

## first pass

taxonomyCleanr::create_taxa_map(
  path = my_path,
  x    = veg_taxa,
  col  = "vegetation_scientific_name"
)

taxonomyCleanr::resolve_sci_taxa(
  path         = my_path,
  data.sources = c(3, 11)
) 

SELECT
    vegetation_taxon_list.vegetation_scientific_name,
    veg_count.count
FROM vegetation_taxon_list
LEFT JOIN (
    SELECT
        vegetation_samples.vegetation_taxon_id,
        count(vegetation_samples.vegetation_taxon_id)
    FROM vegetation_samples
    GROUP BY vegetation_taxon_id
) AS veg_count ON (veg_count.vegetation_taxon_id = vegetation_taxon_list.vegetation_taxon_id)
;