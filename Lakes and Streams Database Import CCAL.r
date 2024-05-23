# Description: R script to process ARCN Lakes and Streams CCAL water chemistry data
# Written by: S.D. Miller

# Load libraries
library(tidyverse)
library(readxl)
library(sqldf)

# The CCAL source files directory
dataDirectory = 'O:/Monitoring/Vital Signs/Stream Communities and Ecosystems/Data/Data Reports/CCAL'

# Output file path for the processed CSV files
outputPath = 'C:/Development/Lakes and Streams R/'

# Build a path to a CCAL file
dataFilename = 'ANJO_031114.xlsx'
dataFile = paste(trimws(dataDirectory),'/',trimws(dataFilename),sep='')

# The CCAL file is poorly formatted for input.
# 1. There are lines above the data column headers
# 2. The column headers have carriage returns that must be removed
# Start by getting the column headers into a vector
# sheet refers to the worksheet containing the data
# skip indicates the row that contains the needed data
columnNames =  read_excel(dataFile, sheet = 2,skip=3, n_max = 0) %>% names()
columnNames = str_replace_all(columnNames, "[\r\n]" , "") # Replace all the new line characters in the headers

# Next, read in the data starting at line 4 and replace the column headers with the ones fixed above
data = read_excel(dataFile,sheet=2,skip=4,col_names = columnNames, guess_max = 1048576)

data$`NO3-N+NO2-N (mg N/L) QCCode` = NA
#data <- within(data, `NO3-N+NO2-N (mg N/L) QCCode`[`NO3-N+NO2-N (mg N/L)` %like% '*%' == TRUE] <- 'x')
#x = data$`NO3-N+NO2-N (mg N/L) QCCode`
#data$`NO3-N+NO2-N (mg N/L)`

data$`NO3-N+NO2-N (mg N/L) QCCode` = grep("*",data$`NO3-N+NO2-N (mg N/L)`)

# data %>%
#   mutate(`NO3-N+NO2-N (mg N/L) QCCode` = str_extract(`NO3-N+NO2-N (mg N/L)`, "[*]"))
#
# updateQuery="update data set [NO3-N+NO2-N (mg N/L) QCCode] = '*'"
# data <- suppressWarnings(sqldf(c(updateQuery, "select * from data")))


# df$result <- with(df, ifelse(scored > allowed, 'Win', 'Loss'))
# data$`NO3-N+NO2-N (mg N/L) QCCode` = with(data,ifelse(grepl(`NO3-N+NO2-N (mg N/L)`, '*', fixed = TRUE) == TRUE),'y','n')
#grepl(data$`NO3-N+NO2-N (mg N/L)`, '*', fixed = TRUE)
#data$`NO3-N+NO2-N (mg N/L) QCCode`[ grepl(data$`NO3-N+NO2-N (mg N/L)`, '*', fixed = TRUE) == TRUE ] <- '*'

# Process the data
processedData = data %>%

    # Get rid of the columns starting with 'Duplicate'. We'll leave these in the source files and leave out of the database
  select(!starts_with('Duplicate')) %>%

  # Get rid of all columns starting with 'Date'. These are sample processing dates, they are duplicative and of minimal value, we can get them from the source files if they are really needed.
  select(!starts_with('Duplicate')) %>%

  # read_excel made all columns text. Most parameters should be double.
  # I thought I needed to transform parameter columns from chr to dbl, but it is unimportant to the final CSV, and I'm not doing any statistics
  # so the line below is retained just as an example of how to transform a parameter, should it become necessary
  #mutate(`NO3-N+NO2-N (mg N/L)` = as.double(`NO3-N+NO2-N (mg N/L)`))  %>%

  # Chem columns contain an asterisk if they are below detection limit.
  # For such columns split it into two columns, one for the values and one for asterisked values below detection, this latter column append the column
  # name with ' MDL'
  separate_wider_delim(`NH3-N (mg N/L)`, '*', names = c('NH3-N (mg N/L)', 'NH3-N (mg N/L) MDL'), too_few = 'align_start') %>%
  separate_wider_delim(`NO3-N+NO2-N (mg N/L)`, '*', names = c('NO3-N+NO2-N (mg N/L)', 'NO3-N+NO2-N (mg N/L) MDL'), too_few = 'align_start') %>%
  separate_wider_delim(`PO4-P (mg P/L)`, '*', names = c('PO4-P (mg P/L)', 'PO4-P (mg P/L) MDL'), too_few = 'align_start') %>%
  separate_wider_delim(`TDN (mg N/L)`, '*', names = c('TDN (mg N/L)', 'TDN (mg N/L) MDL'), too_few = 'align_start') %>%
  separate_wider_delim(`TDP (mg P/L)`, '*', names = c('TDP (mg P/L)', 'TDP (mg P/L) MDL'), too_few = 'align_start') %>%
  separate_wider_delim(`Cl (mg/L)`, '*', names = c('Cl (mg/L)', 'Cl (mg/L) MDL'), too_few = 'align_start') %>%
  separate_wider_delim(`SO4-S (mg/L)`, '*', names = c('SO4-S (mg/L)', 'SO4-S (mg/L) MDL'), too_few = 'align_start') %>%
  separate_wider_delim(`F (mg/L)`, '*', names = c('F (mg/L)', 'F (mg/L) MDL'), too_few = 'align_start') %>%
  separate_wider_delim(`Br (mg/L)`, '*', names = c('Br (mg/L)', 'Br (mg/L) MDL'), too_few = 'align_start') %>%
  separate_wider_delim(`Na (mg/L)`, '*', names = c('Na (mg/L)', 'Na (mg/L) MDL'), too_few = 'align_start') %>%
  separate_wider_delim(`K (mg/L)`, '*', names = c('K (mg/L)', 'K (mg/L) MDL'), too_few = 'align_start') %>%
  separate_wider_delim(`Ca (mg/L)`, '*', names = c('Ca (mg/L)', 'Ca (mg/L) MDL'), too_few = 'align_start') %>%
  separate_wider_delim(`Mg (mg/L)`, '*', names = c('Mg (mg/L)', 'Mg (mg/L) MDL'), too_few = 'align_start')

  processedData$SourceFileName = dataFilename



# Write the processed data to a CSV file. outputPath is set up above.
csvFile = paste(outputPath,dataFilename,".csv",sep="")
write.csv(processedData,csvFile,quote=FALSE,na = "",row.names=FALSE)


###############################################
# I used the code below to create some of the repetitive code segments above
# Save and comment it out in case I need it again
# Get all the column names of data into a data frame
#cols = as.data.frame(colnames(processedData))
# Change the header
#colnames(cols) = c("ColumnName")
# Create the dplyr separate_wider commands as a new column
#cols$x = paste("separate_wider_delim(`",cols$ColumnName,"`, '*', names = c('",cols$ColumnName,"', '",cols$ColumnName," MDL'), too_few = 'align_start') %>% ",sep="")
#cols$y = paste("processedData$`",cols$ColumnName,"` = as.double(processedData$`",cols$ColumnName,"`)",sep="")
# Output so I can copy it into the data processing code above
#as.data.frame(cols$x)
#x = select(cols,y)


