library(httr2)

# Replace with your actual API key and download URL
APIkey <- Sys.getenv("APIkey")  # Ensure your API key is set in your environment
download_url <- "https://ndownloader.figshare.com/files/51981344"  # Replace with your actual download URL

# Create the request to download the file
file_request <- request(download_url) |> 
  req_url_query(access_token = APIkey)

# Perform the request to download the file
file_response <- req_perform(file_request)

# Check if the request was successful
if (file_response |> resp_status() == 200) {
  # Check the content type and content disposition headers
  content_type <- resp_headers(file_response)$`content-type`
  content_disposition <- resp_headers(file_response)$`content-disposition`
  
  # Determine the file extension based on content type
  if (grepl("pdf", content_type)) {
    file_extension <- ".pdf"
  } else if (grepl("csv", content_type)) {
    file_extension <- ".csv"
  } else if (grepl("text", content_type)) {
    file_extension <- ".txt"
  } else {
    file_extension <- ""  # Default if unknown
  }
  
  # Extract the filename from content disposition if available
  if (!is.null(content_disposition)) {
    filename_match <- regexpr("filename=\"([^\"]+)\"", content_disposition)
    if (filename_match != -1) {
      file_name <- regmatches(content_disposition, filename_match)[[1]]
      file_name <- gsub("filename=\"|\"","", file_name)  # Clean up filename
    } else {
      file_name <- paste0("downloaded_file", file_extension)  # Fallback filename
    }
  } else {
    file_name <- paste0("downloaded_file", file_extension)  # Fallback filename
  }
  
  # Save the file to disk
  writeBin(resp_body_raw(file_response), file_name)
  cat("File downloaded successfully to:", file_name, "\n")
} else {
  # Print error details for troubleshooting
  cat("Error downloading the file:\n")
  cat("Status Code:", file_response |> resp_status(), "\n")
  cat("Response Body:", resp_body_string(file_response), "\n")
  cat("Response Headers:", resp_headers(file_response), "\n")
}







curl_translate('curl -X POST "https://api.figshare.com/v2/account/articles/{article_id}/files?page=&page_size=&limit=&offset="')
