library(httr)
library(jsonlite)
library(digest)

APIkey <- Sys.getenv("APIkey")


# Download file -----------------------------------------------------------

item_id <- "28142597"

url <- paste0("https://api.figshare.com/v2/account/articles/", item_id, "/files?page_size=10")
response <- GET(url, add_headers(Authorization = paste("token", APIkey)))
response_content <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
download_url <- response_content$download_url

file <- GET(download_url, add_headers(Authorization = paste("token", APIkey)))
downloaded_file <- paste0(item_id, ".csv")
writeBin(content(file, "raw"), downloaded_file)

# Delete file -------------------------------------------------------------

file_id <- sub(".*/files/([0-9]+)", "\\1", download_url)

delete_url <- paste0("https://api.figshare.com/v2/account/articles/", item_id, "/files/", file_id)
print(delete_url)

delete_response <- DELETE(delete_url, add_headers(Authorization = paste("token", APIkey)))

# Upload new file ---------------------------------------------------------

file_name <- paste0(item_id, ".csv")
file_path <- downloaded_file
file_size <- file.info(file_path)$size

class(file_size)

md5_checksum <- digest(file_path, algo = "md5", serialize = FALSE)

upload_url <- paste0("https://api.figshare.com/v2/account/articles/", item_id, "/files")

initiate_response <- POST(
  upload_url,
  add_headers(Authorization = paste("token", APIkey)),
  body = list(name = file_name, size = file_size, md5 = md5_checksum),
  encode = "json" # Ensure the body is sent as JSON
)

# Parse the initiate upload response
initiate_content <- fromJSON(content(initiate_response, as = "text", encoding = "UTF-8"))
print(status_code(initiate_response))

response_content <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
download_url_2 <- response_content$download_url





upload_token <- initiate_content$upload_token
print(paste("Upload initiated with token:", upload_token))

# Step 2: Upload the file using the upload URL
file_upload_url <- initiate_content$upload_url
upload_response <- PUT(
  upload_url,
  body = upload_file(file_path)
)

if (status_code(upload_response) == 200) {
  print("File uploaded successfully.")
} else {
  print("File upload failed.")
}

# Step 3: Complete the upload
complete_url <- paste0("https://api.figshare.com/v2/account/articles/", item_id, "/files/", initiate_content$id)
complete_response <- POST(
  complete_url,
  add_headers(Authorization = paste("token", APIkey))
)

if (status_code(complete_response) == 200) {
  print("File upload completed successfully.")
} else {
  print("File upload completion failed.")
}

