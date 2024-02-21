#' @title  combine journals and output csv file
#'
#' @import data.table
#' @importFrom stringr str_trim str_to_lower str_count str_replace_all str_glue str_squish
#' @importFrom stringi stri_escape_unicode
#' @importFrom usethis use_data
#' @return NULL
#' @keywords  combine journals and output CSV
#' @examples
#' \dontrun{
#' journalabbr:::combine_journal_lists()
#' }


# set_wd() 
# here::dr_here()
current_dir <- dirname(basename(normalizePath(path.expand("."))))
# script_dir <- dirname(rstudioapi::getSourceEditorContext()$path)
setwd(current_dir)
cat(stringr::str_glue("\n===== 当前工作目录为: {getwd()} ====\n"))


combine_journal_lists <- function(csvdir = "./metadata/journals/", format = c("rda", "js"), jspath = "./data.ts") {
  library(data.table)
  library(purrr)
  library(stringr)
  # check input
  if (!is.character(csvdir) || !is.character(format) || !is.character(jspath)) {
    stop("The input parameter must be a character type.")
  }
  
  if (!format %in% c("rda", "js")) {
    stop("The format parameter must be one of 'rda' or 'js'.")
  }
  journal <- journal_abbr <- journal_lower <- fz_count_dot <- fz_count_abbrlen <- fz_count_upper <- NULL
  filedf <- tibble::tribble(
    ~file, ~weight,
    "./woodward_library_new.csv", 2,
    "./metadata/journals/journal_abbreviations_acs.csv", 3,
    "./metadata/journals/journal_abbreviations_aea.csv", 3, # 新增
    "./metadata/journals/journal_abbreviations_ams.csv", 3,
    "./metadata/journals/journal_abbreviations_annee-philologique.csv", 3,
    "./metadata/journals/journal_abbreviations_dainst.csv", 3,
    "./metadata/journals/journal_abbreviations_entrez.csv", 3,
    "./metadata/journals/journal_abbreviations_general.csv", 3,
    "./metadata/journals/journal_abbreviations_geology_physics_variations.csv", 3,
    "./metadata/journals/journal_abbreviations_geology_physics.csv", 3,
    # "./metadata/journals/journal_abbreviations_ieee_strings.csv", 3,
    "./metadata/journals/journal_abbreviations_ieee.csv", 3,
    "./metadata/journals/journal_abbreviations_lifescience.csv", 3,
    "./metadata/journals/journal_abbreviations_mathematics.csv", 3,
    "./metadata/journals/journal_abbreviations_mechanical.csv", 3,
    "./metadata/journals/journal_abbreviations_medicus.csv", 3,
    "./metadata/journals/journal_abbreviations_meteorology.csv", 3,
    "./metadata/journals/journal_abbreviations_sociology.csv", 3,
    "./metadata/journals/journal_abbreviations_webofscience.csv", 3,
    "./metadata/journals/journal_abbreviations_webofscience-dots.csv", 3,
  )
  # automatically add new files
  newfile <- list.files(path = csvdir, pattern = "\\.csv",  full.names = T)
  newfile_diff <- setdiff(newfile, filedf$file)
  if (length(newfile_diff) > 0) {
    for (i in newfile_diff) {
      filedf <- tibble::add_row(filedf, file = i, weight = 3)
    }
  }
  filedf <- filedf[filedf$file != "./metadata/journals/journal_abbreviations_ieee_strings.csv", ]
  filedf <- unique(filedf)

  filelist <- filedf$file

  dt_list <- list()
  k <- 1
  for (i in filelist) {
    if (file.exists(i)) {
      dt_list[[k]] <- data.table::fread(i, sep = ",", header = FALSE, fill = TRUE)
      dt_list[[k]][, "originFile" := i]
      k <- k + 1
    } else {
      print(stringr::str_glue("i={i}"))
    }
  }

  dt <- data.table::rbindlist(dt_list, fill = TRUE) # Merge multiple data
  dt <- dt[, c("V1", "V2", "originFile"), with = FALSE]
  dt <- merge(dt, filedf, sort = F, all.x = T, by.x = "originFile", by.y = "file")
  dt <- dt[, c("V1", "V2", "originFile", "weight"), with = FALSE]


  cat(sprintf("After the merger, there are %d journals in total.\n", dt[, .N]))
  setnames(
    dt, c("V1", "V2", "originFile", "weight"),
    c("journal", "journal_abbr", "originFile", "weight")
  )

  dt <- dt[, lapply(.SD, str_squish)]

  dt_1 <- copy(dt)
  dt_2 <- copy(dt)
  dt_3 <- copy(dt)


  dt_1[, journal := str_replace_all(journal, "(?<= )\\&(?= )", "&")]
  dt_1[, journal := str_replace_all(journal, "(?<= )\\\\&(?= )", "&")]
  dt_1[, journal := str_replace_all(journal, "(?<= )[aA][nN][dD](?= )", "&")]

  dt_2[, journal := str_replace_all(journal, "(?<= )&(?= )", "and")]
  dt_2[, journal := str_replace_all(journal, "(?<= )\\\\&(?= )", "and")]
  dt_2[, journal := str_replace_all(journal, "(?<= )\\&(?= )", "and")]

  dt_3[, journal := str_replace_all(journal, "(?<= )&(?= )", "\\\\&")]
  dt_3[, journal := str_replace_all(journal, "(?<= )[aA][nN][dD](?= )", "\\\\&")]
  dt_3[, journal := str_replace_all(journal, "(?<= )\\&(?= )", "\\\\&")]


  dt <- unique(rbindlist(list(dt_1, dt_2, dt_3), use.names = TRUE, fill = TRUE))
  cat(sprintf("After 'and' and '&' are replaced and merged, there are %d journals in total.\n", dt[, .N]))

  ############ 1. Journal special value processing
  #### 1.1 Delete lines with backslashes and forward slashes -- journals are too special
  dt <- dt[!grepl(pattern = "\\\\", journal), ]
  dt <- dt[!grepl(pattern = "/{1,10}", journal), ]
  #### 1.2 Delete lines with double quotes -- journals are too special
  dt <- dt[!grepl(pattern = '"', journal), ]
  ##### 1.3 Delete journals whose journal field is more than 80 or less than 5 characters
  dt <- dt[nchar(journal) <= 80 & nchar(journal) >= 5, ]

  # dt <- dt[!grepl(pattern = "\\\\", journal_abbr), ]
  # dt <- dt[!grepl(pattern = "/{1,10}", journal_abbr), ]
  dt <- dt[!grepl(pattern = '"', journal_abbr), ]


  ########### 2. Journal field to lowercase and add some auxiliary columns to help filter duplicate journals later.
  dt[, journal_lower := str_to_lower(journal)]
  dt[, fz_count_dot := str_count(journal_abbr, "\\.")] # Calculate the number of dots in the abbr field.
  dt[, fz_count_abbrlen := str_length(journal_abbr)] # Calculate the length of the abbr field.
  # Calculate the number of uppercase letters in the abbr field.
  dt[, fz_count_upper := str_count(journal_abbr, "[A-Z]")]

  ########## 3. Remove duplicate items, Filter according to certain conditions.
  dt_new <- dt[dt[, .I[order(weight, -fz_count_dot, -fz_count_upper, fz_count_abbrlen)[1]], by = journal_lower]$V1, ]

  dt_new_sub <- dt_new[, c("journal_lower", "journal_abbr", "originFile"), with = FALSE]
  stopifnot(uniqueN(dt_new_sub[, c("journal_lower"), with = FALSE]) == dt_new_sub[, .N])
  cat(sprintf(
    "Delete duplicate items. Finally, a total of %d journals with abbreviations were used.\n",
    dt_new_sub[, .N]
  ))

  if (format != "js") {
    # Only save as RDA format
    abbrtable_sys <- dt_new_sub[, lapply(.SD, stringi::stri_escape_unicode)]
    usethis::use_data(abbrtable_sys, compress = "xz", internal = TRUE, overwrite = TRUE, version = 3)
  } else {
    dtf <- dt_new_sub
    data.table::fwrite(dtf, file = "data_new.csv")

    if (file.exists(jspath)) {
      file.remove(jspath)
    }

    # output js file, for zotero-journalabbr repo
    cat("const journal_abbr = {\n  ", file = jspath, append = F, sep = "")

    s0 <- dtf[, paste0('"', journal_lower, '":"', journal_abbr, '"')]
    cat(s0, file = jspath, append = T, sep = ",\n  ")

    cat("};\n\nexport { journal_abbr };", file = jspath, append = T, sep = "")

    # output rda file, for journalabbr repo
    abbrtable_sys <- dt_new_sub[, lapply(.SD, stringi::stri_escape_unicode)]
    usethis::use_data(abbrtable_sys, compress = "xz", internal = TRUE, overwrite = TRUE, version = 3)
  }
}

combine_journal_lists(csvdir = "./metadata/journals/", format = "js", jspath = "./data_new.ts")
