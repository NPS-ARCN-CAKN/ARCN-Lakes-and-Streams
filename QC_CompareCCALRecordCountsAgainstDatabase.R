library(readxl)

# Function to open an Excel spreadsheet and return the number of rows in it
GetNumberOfRows = function(ExcelFile){
  data = read_xlsx(ExcelFile)
  return(nrow(data))
}

# Directory holding the CCAL tidied data files
dir = 'O:/Monitoring/Vital Signs/Stream Communities and Ecosystems/Data/Data Reports/CCAL/Tidied'

# Get a list of CCAL tidied files
files = list.files(path=dir,pattern=".xlsx$")

# Dump out SQL queries that will put the number of records by SourceFile next to the number of records in each Excel sheet
# Copy the output queries to Sql Server Management Studio, tidy up the crap R puts in, and then execute and compare the results.
for (file in files){
  datafile=paste(dir,"/",file,sep="")
  print(paste("SELECT SourceFilename,Count(*) as n,'",file,"' as [",file,"],",GetNumberOfRows(datafile)," as TidyFileRowCount FROM Chemistry WHERE SourceFilename='",file,"' Group By SourceFilename",sep=""))
}

















