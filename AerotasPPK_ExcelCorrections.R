# Aerotas P4RTK PPK Adjustments Worksheet Translation
# This script is to make the Aerotas PPK Excel spreadsheet more batch process focused and to make my research more transparent

# Steps:
#1. Import RTKLIB corrected position file
#2. Import Timestamp.MRK file from DJI P4RTK flights
#3. Calculate camera specific position from those two files
#4. Scrape EXIF-data from original photos to append yaw, pitch, and roll columns to location file

# Setup Workspace #####
setwd("~/Desktop/RTK_PPK/20200121_RTK")
Date <- "20200121" #in YYYYMMDD format ONLY
FileName <- "100_0013" #probably 100_00XX of some sort
options(digits = 15) #preserves long format Lat/Lon decimal places

#1. Import RTKLIB corrected position file and tidy up: ####
RTKLIB <- read.csv(paste0("preprocessing_files/", FileName, "_Rinex.csv"), 
                   header = TRUE, stringsAsFactors = FALSE, skip = 1, row.names = NULL)
colnames(RTKLIB)[c(1, 2)] <- c("GPS.Day", "GPST")


#2. Import and tidy up Timestamp.MRK file: ####
Timestamp <- read.table(paste0("preprocessing_files/", FileName, "_Timestamp.MRK"), 
                      header = FALSE, stringsAsFactors = FALSE, row.names = NULL)
colnames(Timestamp) <- c("Photo#", "GPST", "GPS.Day", "Northing_diff_mm", "Easting_diff_mm", 
                         "Elevation_diff_mm", "Lat", "Lon", "Height_m", "std_North_m", 
                         "std_East_m", "std_Ele_m", "RTK_status_flag")
# NOTE: RTK status flag. 0: no positioning; 16: single-point positioning mode; 34: RTK floating 
# solution; 50: RTK fixed solution. When the flag bit of a photo is not 50, it is recommended 
# not to use this photo directly in map building.

# Clean Timestamp file of non-numeric text in columns and convert to numeric
Timestamp2 <- Timestamp
Timestamp2$`Photo#` <- as.numeric(Timestamp$`Photo#`)
Timestamp2$GPS.Day <- as.numeric(gsub("[^0-9.-]", "", x = Timestamp$GPS.Day))
Timestamp2$Northing_diff_mm <- as.numeric(gsub("([0-9]+).*$", "\\1", Timestamp$Northing_diff_mm)) #works
Timestamp2$Easting_diff_mm <- as.numeric(gsub("([0-9]+).*$", "\\1", Timestamp$Easting_diff_mm)) #works
Timestamp2$Elevation_diff_mm <- as.numeric(gsub("([0-9]+).*$", "\\1", Timestamp$Elevation_diff_mm)) #works
Timestamp2$Lat<- as.numeric(gsub(",?[Lat]?", "", x = Timestamp$Lat))
Timestamp2$Lon<- as.numeric(gsub(",?[Lon]?", "", x = Timestamp$Lon))
Timestamp2$Height_m<- as.numeric(gsub(",?[Ellh]?", "", x = Timestamp$Height_m))
Timestamp2$std_North_m <- as.numeric(gsub(",", "", x = gsub("\\(?[0-9]+.\\+$,", "\\1", Timestamp$std_North_m))) #gotta still get rid of the damn comma?
Timestamp2$std_East_m <- as.numeric(gsub(",", "", x = gsub("\\(?[0-9]+.\\+$,", "\\1", Timestamp$std_East_m))) #gotta still get rid of the damn comma?
Timestamp2$RTK_status_flag <- as.numeric(gsub("[^0-9.-]", "", x = Timestamp$RTK_status_flag))


#3. Calculate camera specific positions: ####
# Step 1 - Create calculations spreadsheet
Calc <- data.frame(matrix(ncol = 23, nrow = nrow(Timestamp2)), stringsAsFactors = FALSE)
Calc.Headers <- c("Northing_diff_mm",	"Easting_diff_mm",	"Elevation_diff_mm",	"Closest_Loc_ID",	"Timestamp_of_Closest",
                          "Closest_Lat",	"Closest_Lon",	"Closest_El",	"2nd_Closest_Loc_ID",	"Timestamp_of_2nd_closest", "2nd_Closest_Lat",
                          "2nd_Closest_Lon", "2nd_Closest_El",	"Percent_diff_between_timestamps",	"Interpolated_Lat",	"Interpolated_Lon",
                         "Interpolated_El",	"Lat_Diff_deg",	"Lon_Diff_deg",	"El_Diff_m",	"New_Lat",	"New_Lon", "New_El")
colnames(Calc) <- Calc.Headers

# Step 2 - Calculate values and input into the Calc dataframe
Calc$Northing_diff_mm <- Timestamp2$Northing_diff_mm
Calc$Easting_diff_mm <- Timestamp2$Easting_diff_mm
Calc$Elevation_diff_mm <- Timestamp2$Elevation_diff_mm

# create 'between' function to search for the most similar two timestamp values and return the nearest two
btw <- function(data, num){
  c(min(which(num <= data))-1, min(which(num <= data)))
}

# Loop to find and fill the different stationary variables in the dataframe
for(i in 1:nrow(Calc)){
  d = RTKLIB$GPST
  n = Timestamp2$GPST[[i]]
  
  c1 <- btw(data = d, num = n)[1]
  c2 <- btw(data = d, num = n)[2]
  
  Calc$Closest_Loc_ID[i] <- c1
  Calc$`2nd_Closest_Loc_ID`[i] <- c2

  Calc$Timestamp_of_Closest[i] <- RTKLIB$GPST[c1]
  Calc$Timestamp_of_2nd_closest[i] <- RTKLIB$GPST[c2]
  
  Calc$Closest_Lat[i] <- RTKLIB$latitude.deg.[c1]
  Calc$'2nd_Closest_Lat'[i] <- RTKLIB$latitude.deg.[c2]
  
  Calc$Closest_Lon[i] <- RTKLIB$longitude.deg.[c1]
  Calc$'2nd_Closest_Lon'[i] <- RTKLIB$longitude.deg.[c2]
  
  Calc$Closest_El[i] <- RTKLIB$height.m.[c1]
  Calc$'2nd_Closest_El'[i] <- RTKLIB$height.m.[c2]

}

# Calculate the differences (%) between the UAS timestamp and the calculated PPK positions then interpolate the positions
Calc$Percent_diff_between_timestamps <- abs((Timestamp2$GPST - Calc$Timestamp_of_Closest) /
      (Calc$Timestamp_of_Closest - Calc$Timestamp_of_2nd_closest))
Calc$Interpolated_Lat <- (Calc$Closest_Lat * (1-Calc$Percent_diff_between_timestamps) + 
      (Calc$'2nd_Closest_Lat' * Calc$Percent_diff_between_timestamps))
Calc$Interpolated_Lon <- (Calc$Closest_Lon * (1-Calc$Percent_diff_between_timestamps) + 
      (Calc$'2nd_Closest_Lon' * Calc$Percent_diff_between_timestamps))
Calc$Interpolated_El <- (Calc$Closest_El * (1-Calc$Percent_diff_between_timestamps) + 
      (Calc$'2nd_Closest_El' * Calc$Percent_diff_between_timestamps))

# Calculate lat, lon and elevation camera location differences from the UAS timestamp file
Calc$Lat_Diff_deg <- (Calc$Northing_diff_mm / 1000 / 111111) #111,111 is 1 degree lat in meters
Calc$Lon_Diff_deg <- (Calc$Easting_diff_mm / 1000 / 77416) #77,416 is 1 degree lon in meters
Calc$El_Diff_m <- Calc$Elevation_diff_mm / 1000 #convert from mm to meters

# Calculate final Lat, Lon, and Elevation from PPK corrections, Interpolated Points, and Camera specific differences
Calc$New_Lat <- Calc$Interpolated_Lat + Calc$Lat_Diff_deg
Calc$New_Lon <- Calc$Interpolated_Lon + Calc$Lon_Diff_deg
Calc$New_El <- Calc$Interpolated_El + Calc$El_Diff_m

#Grab the final positions in one clean file
Final_Positions <- data.frame(Calc$New_Lat, Calc$New_Lon, Calc$New_El, 
                     Calc$Northing_diff_mm*0.001, Calc$Easting_diff_mm*0.001, Calc$Elevation_diff_mm*0.001)
colnames(Final_Positions)[4:6] <- c("Lat_diff_m", "Lon_diff_m", "Elevation_diff_m")


#4. Scrape EXIF-data from original photos to append ya, pitch, and roll columns to final locaiton file: ####
library(exiftoolr)
#install_exiftool() #Need to run this the first time to install EXIFtool onto computer

# Aim at the folder you want to find photos in (BE SURE TO ADJUST THE DATE)
mydir <- paste0("~/Box/Research/data/Field_Days/", Date, "_Hourglass/Photos/", FileName)
pics <- list.files(path=mydir, pattern=".JPG", full.names=TRUE)

# Read the EXIF data
OGexif <- exif_read(pics, recursive = FALSE) #grab all EXIF data

# Append the relevant fields to the Final_Positions dataframe and export the final product ####
Export_Ready <- cbind(FileName = OGexif$FileName, Final_Positions, Yaw = OGexif$Yaw, Pitch = OGexif$Pitch, Roll = OGexif$Roll)
write.csv(Export_Ready, row.names = FALSE, quote = FALSE, 
          file = paste0(getwd(), "/processed_files/", Date, "_", FileName, "_finalpositions.csv"))

#5. Grab all the separate corrected location files and append into one single field day file ####
#ProcessedList <- list.files(path = paste0(getwd(), "/processed_files"), pattern=".csv", full.names=TRUE)
# load each location file
#flight1 <- read.csv(file = ProcessedList[1], header = TRUE, sep = ",", stringsAsFactors = FALSE)
#flight2 <- read.csv(file = ProcessedList[2], header = TRUE, sep = ",", stringsAsFactors = FALSE)
#flight3 <- read.csv(file = ProcessedList[3], header = TRUE, sep = ",", stringsAsFactors = FALSE)
#flight4 <- read.csv(file = ProcessedList[4], header = TRUE, sep = ",", stringsAsFactors = FALSE) #only need additional flights on certain days
#flight5 <- read.csv(file = ProcessedList[5], header = TRUE, sep = ",", stringsAsFactors = FALSE) #can create as many as needed

# Append the files together and export
#AllFlights <- rbind(flight1, flight2, flight3)
#colnames(AllFlights)[2:4] <- c("Lat", "Lon", "Elevation_m")
#write.csv(AllFlights, row.names = FALSE, quote = FALSE,
#          file = paste0(getwd(), "/processed_files/", Date, "_corrected_positions.csv"))


