# AerotasPPK_forP4RTK
This script should follow the RTKLIB portion of the PPK corrections Aerotas workflow and supplements the very clunky Excel-macro focused calculations. It is written on a mac, so some minor adjustments to naming conventions may be necessary for windows compatibility!

README: AerotasPPK_ExcelCorrections.R

Script is replacement and translation of the Aerotas P4RTK PPK Excel spreadsheet.

The file structure MUST BE SET CORRECTLY for the script to work with minimal editing aside from the opening “Setup Workspace” lines.

Essential file structures:
1. “RTK_PPK” folder
	> “YYYMMDD_PPK”
		> “preprocessing_files” - This is where your RTKLIB input and output files are stored AND “processed_files” - This is where you final corrected PPK files will be deposited

2. Photos folder
	> “YYYYMMDD_Hourglass”
		> Photos
			> SURVEY
				> “100_00##” - this is where 1 flight’s worth of photos are stored AND “100_00##” - this is where another flight’s worth of photos are stored

Essential lines of code to adjust or double check: (line # is listed)
> 11 - setwd() = set working directory : aim this wherever you have the RTK_PPK folder and at the specific date (“YYYMMDD_RTK”) folder to be processed

> 12 - Date = set the date in quotes and in YYYYMMDD format

> 13 - FileName = set the single flight file name (“100_00##”) in quotes

> 122 - mydir <- paste0() = adjust this at your folder or directory where the photos are kept (it will auto fill Date and FileName from above)

If you have all of your directories correctly assigned, then you should be able to click “Source” in the corner of the script pane and just have to wait while the script runs!

At the end of processing each individual flight, un-comment the script lines of Step 5 and then run the final bit of script to append all of your new location information into one single file for the field day. You are now ready for importing into Agisoft!
