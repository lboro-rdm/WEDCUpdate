library(httr2)
library(jsonlite)
library(tidyverse)

APIkey <- Sys.getenv("APIkey")
base_url <- "https://api.figshare.com/v2/account"
article_id <- "28142597"

# Step 1: Get file --------------------------------------------------------



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
file_md5 <- as.character(tools::md5sum(file_path))

# Step 1: Initiate file upload
upload_init_req <- request(base_url) |> 
  req_url_path_append("articles", article_id, "files") |> 
  req_auth_bearer_token(APIkey) |> 
  req_body_json(list(name = basename(file_path), size = file_size, md5 = file_md5)) |>  
  req_method("POST") |> 
  req_perform()

# Extract upload URL and file ID
upload_info <- upload_init_req |> resp_body_json()
file_id <- str_extract(upload_info$location, "\\d+$")
print(upload_info)
print(file_id)

# Step 2: Retrieve upload details from Uploader Service
file_info_req <- request(upload_info$location) |> 
  req_auth_bearer_token(APIkey) |> 
  req_perform() |> 
  resp_body_json()

print(file_info_req)
str(file_info_req)

upload_url <- file_info_req$upload_url

num_parts <- length(upload_parts_req$parts)

# New Step: Send a GET request to check number of file parts
for (part_no in seq_len(num_parts)) {
  # Get the upload token from the previous response
  upload_token <- upload_parts_req$upload_token
  
  # Construct the URL for the specific part
  part_url <- paste0(upload_url, "/", upload_token, "/", part_no)
  
  # Now send a GET request to retrieve the upload URL for the part
  part_info_req <- request(part_url) |> 
    req_method("GET") |> 
    req_perform() |> 
    resp_body_json()
}
  

print(upload_parts_req)  # This will show number of parts needed

# Step 3: Upload file parts

  upload_part_req <- request(upload_url) |> 
    req_method("PUT") |> 
    req_headers("Content-Type" = "application/octet-stream") |>  
    req_body_file(file_path) |> 
    req_perform()
  
  print(paste("Uploaded part:", part$partNo))


Sys.sleep(5)

# Step 4: Complete file upload
complete_upload_req <- request(base_url) |> 
  req_url_path_append("articles", article_id, "files", file_id) |> 
  req_auth_bearer_token(APIkey) |>  
  req_method("POST") |> 
  req_perform()

print(complete_upload_req |> resp_body_json())  # Debugging




# Stop here for now -------------------------------------------------------




# Step 3: Mark Upload as Complete
complete_req <- request(base_url) |> 
  req_url_path_append("articles", article_id, "files", file_id) |> 
  req_auth_bearer_token(APIkey) |> 
  req_method("POST") |> 
  req_perform()

cat("File upload completed successfully!\n")

