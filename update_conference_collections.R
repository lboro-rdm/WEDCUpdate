library(httr2)
library(jsonlite)
library(tidyverse)

APIkey <- Sys.getenv("APIkey")
base_url <- "https://api.figshare.com/v2/account"

# Step 1: Get file --------------------------------------------------------

article_id <- "28142597"

fig_req <- request(base_url) |> 
  req_url_path_append("articles", article_id, "files") |> 
  req_auth_bearer_token(APIkey)

file_metadata <- fig_req |> req_perform() |> resp_body_json()

download_url <- pluck(file_metadata, 1, "download_url")

file_request <- request(download_url) |> 
  req_url_query(access_token = APIkey)

file_response <- req_perform(file_request)

content_type <- resp_headers(file_response)$`content-type`

content_disposition <- resp_headers(file_response)$`content-disposition`

file_name <- pluck(file_metadata, 1, "name")
  
writeBin(resp_body_raw(file_response), file_name)

# STEP 2 Upload file to Figshare ----------------------------------------

file_path <- "conference_collection_ids.csv"
file_size <- file.info(file_path)$size
file_md5 <- tools::md5sum(file_path)

upload_init_req <- request(base_url) |> 
  req_url_path_append("articles", article_id, "files") |> 
  req_auth_bearer_token(APIkey) |> 
  req_body_json(list(name = basename(file_path), size = file_size, md5 = file_md5)) |>   req_method("POST") |> 
  req_perform()

# Extract the upload URL and file ID
upload_info <- upload_init_req |> resp_body_json()
file_id <- basename(upload_info$location)

file_info_req <- request(upload_info$location) |> 
  req_auth_bearer_token(APIkey) |> 
  req_perform() |> 
  resp_body_json()

upload_url <- pluck(file_info_req, "upload_url")


# Step 2: Upload the File (PUT Request to Upload URL)
upload_req <- request(upload_url) |> 
  req_method("PUT") |> 
  req_body_file(file_path) |> 
  req_perform()

# Step 3: Mark Upload as Complete
complete_req <- request(base_url) |> 
  req_url_path_append("articles", article_id, "files", file_id) |> 
  req_auth_bearer_token(APIkey) |> 
  req_method("POST") |> 
  req_perform()

cat("File upload completed successfully!\n")

