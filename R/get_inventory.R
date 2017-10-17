





#' Download and return a tidy data.frame of GSOD weather station data inventories
#'
#' The NCEI maintains a document,
#' <ftp://ftp.ncdc.noaa.gov/pub/data/noaa/isd-inventory.txt>, which shows the
#' number of weather observations by station-year-month from the beginning of
#' the stations' records. This function retrieves that document, prints the
#' header to display the last update time and caclulates the percent
#' monthly coverage for each station reported.
#'
#' @note The GSOD data, which are downloaded and manipulated by this R package,
#' stipulate that the following notice should be given.  \dQuote{The following
#' data and products may have conditions placed on their international
#' commercial use.  They can be used within the U.S. or for non-commercial
#' international activities without restriction.  The non-U.S. data cannot be
#' redistributed for commercial purposes.  Re-distribution of these data by
#' others must provide this same notification.}
#'
#' @examples
#' \dontrun{
#' inventory <- get_inventory()
#'}
#' @return \code{\link[base]{data.frame}} object of station inventories
#' @author Adam H Sparks, \email{adamhsparks@gmail.com}
#' @importFrom rlang .data
#' @export
#'
get_inventory <- function() {
  load(system.file("extdata", "isd_history.rda", package = "GSODR"))

  file_in <-
    curl::curl_download(
      "ftp://ftp.ncdc.noaa.gov/pub/data/noaa/isd-inventory.txt",
      destfile = tempfile(),
      quiet = TRUE
    )

  header <- readLines(file_in, n = 5)

  message(paste0(header[3:5], collapse = " "))

  body <-
    readr::read_fwf(
      file_in,
      skip = 8,
      readr::fwf_positions(
        c(1, 8, 14, 20, 28, 36, 44, 52, 60, 68, 76, 84, 92, 100, 108),
        c(7, 13, 18, 27, 35, 43, 51, 59, 67, 75, 83, 91, 99, 107, 113),
        c(
          "USAF",
          "WBAN",
          "YEAR",
          "JAN",
          "FEB",
          "MAR",
          "APR",
          "MAY",
          "JUN",
          "JUL",
          "AUG",
          "SEP",
          "OCT",
          "NOV",
          "DEC"
        )
      ),
      col_types = c("ciiiiiiiiiiiiii")
    )

  body[, "STNID"] <- paste(body$USAF, body$WBAN, sep = "-")

  body <- body[, -c(1:2)]

  body <- dplyr::select(body, .data$STNID, dplyr::everything())
  return(body)
}