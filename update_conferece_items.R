

# Read collection IDs and titles
collection_data <- read.csv("collection_ids.csv", stringsAsFactors = FALSE)
collection_ids <- collection_data$collection_id
collection_titles <- paste0(collection_data$number, ", ", collection_data$year, " (", collection_data$location, ")")
conference_ids <- collection_data$number

# Initialize a data frame to store results
article_details <- data.frame(
  collection_title = character(),
  conference_id = character(),
  article_id = character(),
  title = character(),
  stringsAsFactors = FALSE
)

# Base URL for the API
base_url <- "https://api.figshare.com/v2/articles?group="

# Function to fetch articles from a collection
fetch_articles_from_collection <- function(collection_id, collection_title, conference_id) {
  articles_url <- paste0(base_url, collection_id, "&page_size=1000")
  print(articles_url)
  articles_response <- GET(articles_url)
  
  if (status_code(articles_response) != 200) {
    message("Failed to fetch articles for collection: ", collection_title)
    return(NULL)
  }
  
  articles <- fromJSON(content(articles_response, as = "text"))
  
  if (is.null(articles) || length(articles) == 0) {
    message("No articles found for collection: ", collection_title)
    return(NULL)
  }
  
  # Convert conference_id to character to ensure consistency
  data.frame(
    collection_title = collection_title,
    conference_id = as.character(conference_id),  # Explicit conversion to character
    article_id = as.character(articles$id),
    title = articles$title,
    stringsAsFactors = FALSE
  )
}

# Iterate through each collection and fetch articles
for (i in seq_along(collection_ids)) {
  collection_id <- collection_ids[i]
  collection_title <- collection_titles[i]
  conference_id <- conference_ids[i]
  message("Fetching articles for collection: ", collection_title)
  
  # Fetch articles for the current collection
  collection_articles <- fetch_articles_from_collection(collection_id, collection_title, conference_id)
  
  # If articles were fetched successfully, bind them to the main data frame
  if (!is.null(collection_articles)) {
    article_details <- bind_rows(article_details, collection_articles)
  }
}

# Set the Figshare API request URL for articles
endpoint2 <- "https://api.figshare.com/v2/articles/"

# Initialize a data frame to store citation data
combined_df <- data.frame(
  collection_title = character(),
  conference_id = character(),
  article_id = character(),
  title = character(),
  Author = character(),
  Year = character(),
  hdl = character(),
  doi = character(),
  stringsAsFactors = FALSE
)

# Iterate through article IDs to get article citation data
for (i in 1:nrow(article_details)) {
  print(i)
  article_id <- article_details$article_id[i]
  full_url_citation <- paste0(endpoint2, article_id)
  
  # Get the article citation data
  response <- GET(full_url_citation)
  if (http_status(response)$category != "Success") {
    warning("Failed to fetch data for article ID: ", article_id)
    next
  }
  
  citation_data <- fromJSON(content(response, "text", encoding = "UTF-8"), flatten = TRUE)
  
  # Extract authors, year, and handle with appropriate checks
  Author <- if (!is.null(citation_data$authors) && nrow(citation_data$authors) > 0) {
    paste(citation_data$authors$full_name, collapse = ", ")
  } else {
    NA
  }
  
  year <- if (!is.null(citation_data$published_date)) {
    year(as.Date(citation_data$published_date))
  } else {
    NA
  }
  
  hdl <- if (!is.null(citation_data$handle) && citation_data$handle != "") {
    paste0("https://hdl.handle.net/", citation_data$handle)
  } else {
    ""
  }
  
  doi <- if (!is.null(citation_data$doi) && citation_data$doi != "") {
    paste0("https://doi.org/", citation_data$doi)
  } else {
    ""
  }
  
  # Append the citation data to the combined data frame
  combined_df <- rbind(combined_df, data.frame(
    collection_title = article_details$collection_title[i],
    article_id = article_id,
    title = article_details$title[i],
    conference_id = article_details$conference_id[i],  # Correctly link conference_id
    Author = Author,
    Year = year,
    hdl = hdl,
    doi = doi,
    stringsAsFactors = FALSE
  ))
}

# Save the final dataset to a CSV file
output_file <- "combined_data.csv"
write.csv(combined_df, file = output_file, row.names = FALSE)