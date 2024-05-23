# Description: This script employs Sarah Wright's imd-ccal R script to process CCAL's not so useful file formats into
# a tidy, useful format, with the objective of moving the processed spreadsheets into the ARCN Lakes and Streams Sql Server database
# Written by: NPS\SDMiller, 2024-05-17

# The next section is about how to download and use the NPS imd-ccal R library, uncomment and run lines as needed
# to set up your environment
options(download.file.method = "wininet") # Allows downloading of R packages on NPS network
#install.packages("remotes")
#library(remotes)
#remotes::install_github("nationalparkservice/imd-ccal") # Install the imd-ccal package

# Load the imd-ccal package
library(imdccal)

# Current date
CurrentDate = format(Sys.Date(), format='%B %d, %Y') # Get the current date

# PART ONE: Process CCAL files into tidy, entity/attribute spreadsheets
################################################################################################

# The CCAL source files directory where lab files are stored for ARCN Streams
dataDirectory = r"(O:\Monitoring\Vital Signs\Stream Communities and Ecosystems\Data\Data Reports\CCAL\)"

# Point to a singe CCAL file at a time (although imd-ccal will process a whole directory of ccal files unsupervised, it always seemed to
# bomb out on a file here and there)
# Uncomment one file at a time and run the script.
# CCALFilename = 'ANJO_031114.xlsx'
CCALFilename = 'ANJO_041014.xlsx'
# CCALFilename = 'ANJO_042016.xlsx'
# CCALFilename = 'ANJO_061516.xlsx'
# CCALFilename = 'ANJO_061617.xlsx'
# CCALFilename = 'ANJO_071223_071723.xlsx'
# CCALFilename = 'ANJO_071323.xlsx'
# CCALFilename = 'ANJO_071423.xlsx'
# CCALFilename = 'ANJO_071523.xlsx'
# CCALFilename = 'ANJO_072518.xlsx'
# CCALFilename = 'ANJO_072617.xlsx'
# CCALFilename = 'ANJO_080119_082819.xlsx'
# CCALFilename = 'ANJO_081122.xlsx'
# CCALFilename = 'ANJO_081723_082123.xlsx'
# CCALFilename = 'ANJO_081816_091416.xlsx'
# CCALFilename = 'ANJO_082316 (1).xlsx'
# CCALFilename = 'ANJO_082715.xlsx'
# CCALFilename = 'ANJO_082919.xlsx'
# CCALFilename = 'ANJO_083017.xlsx'
# CCALFilename = 'ANJO_091118.xlsx'
# CCALFilename = 'ANJO_091223.xlsx'
# CCALFilename = 'ANJO_091522.xlsx'
# CCALFilename = 'ANJO_091914.xlsx'
# CCALFilename = 'ANJO_092216.xlsx'
# CCALFilename = 'ANJO_092523.xlsx'
# CCALFilename = 'ANJO_092817.xlsx'
# CCALFilename = 'ANJO_101322.xlsx'
# CCALFilename = 'ANJO_101422.xlsx'
# CCALFilename = 'ANJO_101519.xlsx'
# CCALFilename = 'ANJO_112922.xlsx'




# Output file path for the processed CSV files - processed Excel files will go here
destinationDirectory = 'O:/Monitoring/Vital Signs/Stream Communities and Ecosystems/Data/Data Reports/CCAL/Tidied'

# The code below will process all the files in a directory, but I didn't do this because it bombed on certain files
# all_files <- list.files(dataDirectory, pattern = "*.xlsx$", full.names = TRUE)
# all_files = all_files[!(all_files == "O:/Monitoring/Vital Signs/Stream Communities and Ecosystems/Data/Data Reports/CCAL/ANJO_062618.xlsx")]
# machineReadableCCAL(all_files, destination_folder = destinationDirectory)  # Write one file of tidied data per input file

# Make a path to the CCAL file
dataFile = paste(trimws(dataDirectory),CCALFilename,sep='')

# Write tidied data to a new .xlsx
# Need to retrieve the tidy file, get the file name
tidiedFilename = paste(gsub(".xlsx","",CCALFilename),"_tidy.xlsx",sep="")
# Append the directory to the processed files
tidiedFile = paste(destinationDirectory,'/',tidiedFilename,sep='')

#
if (file.exists(tidiedFile) == FALSE){
  print(paste("Tidying CCAL data file...",CCALFilename,sep=""))
  machineReadableCCAL(dataFile, destination_folder = destinationDirectory)
  #machineReadableCCAL(dataFile, format = "csv", destination_folder = destinationDirectory)  # Write tidied data to a folder of CSV files
  print("Done")
  }else{
   print(paste("CCAL file ",tidiedFilename," has already been tidied - ignoring.",sep=""))
}



# PART TWO: Convert the data in the processed CCAL files into a script of SQL INSERT queries that
# can be executed against the ARCN_LakesAndStreams database
################################################################################################

# Convert the data in the processed data files inte SQL Insert queries that can be executed against
# the ARCN_LakesAndStreams SQL Server database.





# Read the processed file into a data frame
data = readxl::read_excel(tidiedFile,sheet=1)

# Create a new column called InsertQuery and build SQL INSERT queries
data$InsertQuery = paste("INSERT INTO [dbo].[Chemistry]
([sample_name]
,[project_code]
,[lab_number]
,[site_id]
,[delivery_date]
,[comment]
,[parameter]
,[unit]
,[value]
,[date]
,[repeat_measurement]
,[flag_symbol]
,[qc_within_precision_limits]
,[qc_description]
,[SourceFilename])
     VALUES
('",data$sample_name,"'
,'",data$project_code,"'
,'",data$lab_number,"'
,'",data$site_id,"'
,'",data$delivery_date,"'
,'",data$comment,"'
,'",data$parameter,"'
,'",data$unit,"'
,",data$value,"
,'",data$date,"'
,'",data$repeat_measurement,"'
,'",data$flag_symbol,"'
,'",data$qa_within_precision_limits,"'
,'",data$qa_description,"'
,'",tidiedFilename,"')",sep="")

# Convert all the quoted NAs to database appropriate NULLs
data$InsertQuery <- gsub(",'NA'",",NULL", data$InsertQuery)

# Write the insert query scripts to files
# Create a path and file name for the SQL insert queries script
insertQueriesScriptFile = paste(destinationDirectory,"/",tidiedFilename,".INSERT.sql",sep="")

# Create a file connection for the SQL script
fileConn<-file(insertQueriesScriptFile)

# Create metadata for the script header to communicate the provenance of the insert queries
description = paste("-- ",CCALFilename," (",nrow(data)," rows).\n\n-- National Park Service, Arctic Inventory and Monitoring Program\n-- Streams and Lakes Monitoring\n-- https://irma.nps.gov/DataStore/Reference/Profile/2219173\n-- https://irma.nps.gov/DataStore/Reference/Profile/2219172\n\n-- Description: SQL INSERT queries script to convert raw CCAL data records from:\n-- ",dataFile," to a tidy entity-attribute spreadsheet at:\n-- ",tidiedFile,".\n-- The records from the tidied file were then converted into the SQL INSERT queries contained in this file.\n-- Created ",CurrentDate," by ",Sys.getenv("USERNAME"),sep="")

# Create a vector of insert queries
insertQueries = c(description,paste("USE ARCN_LakesAndStreams\n\n -- Highlight and execute the following query to ensure the records have not already been inserted.\n-- The query should return zero rows:\n-- SELECT * FROM Chemistry WHERE Sourcefilename = '",tidiedFilename,"';\n\nBEGIN TRANSACTION -- COMMIT ROLLBACK -- This line will open a database transaction ensuring all the records succeed together, or fail together\n-- You must issue COMMIT if all the insertions succeed, or\n -- Issue ROLLBACK if there were errors.\n",sep=""))

# Loop through the insert queries in the data frame and add them to the insert queries vector
for (i in 1:length(data$InsertQuery))
  insertQueries <- c(insertQueries, paste(data$InsertQuery[i],"\n",sep=""))

# Write the insert queries vector to file
writeLines(insertQueries, fileConn)
close(fileConn)

# Let user know it's done
print(paste("INSERT queries written to ",insertQueriesScriptFile,sep=''))
print("From here you can pick up the .sql files and execute them against the database in Microsoft SQL Server Management Studio")
print("It's recommended to execute the insert queries inside a transaction so that all the rows fail, or all the rows succeed.")






