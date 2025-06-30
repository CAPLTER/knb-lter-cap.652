# A workflow that overlays a grid onto the bounding box of ESCA points then
# cells of a prescribed size in which points fall are isolated as a spatial data
# resource. We can ignore any subtle changes to the positions of points that may
# be catalogued in survey200.sites_geography owing the coarse nature of the
# grid.

sites_lat_long <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT
    site_code,
    latitude,
    longitude
  FROM survey200.sites
  WHERE research_focus = 'survey200'
  ;
  "
)

sites_lat_long <- sites_lat_long |>
  sf::st_as_sf(
    coords = c(
      "longitude",
      "latitude"
    ),
    crs = 4326
  )

# sf::st_write(
#   obj          = sites_lat_long,
#   dsn          = "/tmp/sites_lat_long.geojson",
#   driver       = "geojson",
#   delete_dsn   = TRUE,
#   delete_layer = TRUE
# )

# generate bbox expanded slightly to ensure grid cells cover the points
bbox    <- sf::st_bbox(sites_lat_long)
expand  <- 0.001 # small buffer
bbox[1] <- bbox[1] - expand # xmin
bbox[2] <- bbox[2] - expand # ymin
bbox[3] <- bbox[3] + expand # xmax
bbox[4] <- bbox[4] + expand # ymax

# generate grid cells based on the bounding box
sites_grid <- sf::st_make_grid(
  x        = sf::st_as_sfc(bbox),
  cellsize = 0.015
)

# generate intersection of grid and points
grid_points_intersection <- sf::st_intersects(
  x = sites_grid,
  y = sites_lat_long
)

# subset grid cells to those with points
cells_with_points <- sites_grid[lengths(grid_points_intersection) > 0] |>
  sf::st_sf()

# add site id to grid cells
cells_with_points <- sf::st_join(
  x    = cells_with_points,
  y    = sites_lat_long,
  join = sf::st_intersects
)

# sf::st_write(
#   obj          = cells_with_points,
#   dsn          = "/tmp/cells_with_points.geojson",
#   driver       = "geojson",
#   delete_dsn = TRUE,
#   delete_layer = TRUE
# )