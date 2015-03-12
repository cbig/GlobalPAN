log.name <- "DB-connection"

install.deps <- function() {
  if (!require("pgUtils")) {
    source("http://bioconductor.org/biocLite.R")
    biocLite("pgUtils")
    library("pgUtils")
  }
  
  if (!require("RPostgreSQL")) {
    install.packages("RPostgreSQL")
    library("RPostgreSQL")
  }
}

connect.WDPA <- function() {
  
  drv <- dbDriver("PostgreSQL")
  logdebug(paste("Connecting to DB: ", config$db_name), logger=log.name)
  con <- dbConnect(drv, dbname=config$db_name, user=config$db_user, 
                   password=config$db_password, host=config$db_host, 
                   port=config$db_port)
  if (!is.null(con)) {
    return(con)  
  } else {
    logerror("Connection failed", logger=log.name)
    stop()
  }
}

fetch.rli.data <- function(con, what="*", table, rows=-1) {
  # dbSendQuery(con, statement, ...) submits one statement to the database. Eg.
  rs <- dbSendQuery(con, paste("select", what, "from", table))
  # fetch all elements from the result set
  return(fetch(rs, n=rows))
}

upload <- function(con, df, table.name, overwrite=FALSE, row.names=FALSE, ...) {
  if (dbExistsTable(con, table.name)) {
    
    if (overwrite) {
      message(paste("Overwriting old table:", table.name))
      return(dbWriteTable(con, table.name, df, overwrite=TRUE, 
                          row.names=row.names))
    } else {
      stop(paste("Table", table.name, "exists and overwrite is off."))
    }
  } else {
    return(dbWriteTable(con, table.name, df, row.names=row.names, ...))
  }
} 
