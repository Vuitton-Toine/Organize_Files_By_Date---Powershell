###########################################
# This powershell script organizes files  #
# into dated folders according to the     #
# file's created date.Then it will delete #
# the dated folders and it's contents     #
# after the assigned number of days       #
# specified in the $daysback_rem variable.#
# This is a completeletly functional      #
# script; however, I intend on cleaning   #
# since this was the first PS script      #
# I wrote for production                  #                                          
#                      -Anthony Mignona   #
#                          12/29/21       #
###########################################
 
# Variable Header 
$start_time = Get-Date
$source_folder = "C:\Users\JSmith\Pictures\test"
$storage_folder = $source_folder+"\storage" 
$date_time = Get-Date -Format "yyyy/MM/dd HH:mm:ss"
$date = get-date -Format "yyyy-MM-dd"
$daysback = "-1" # This dictates the date that we want to begin organizing source folder files. -1 = yesterday
$currentdate = Get-Date
$datetomove = ($currentdate.AddDays($daysback)).Date
$log_file = $storage_folder+"\log.txt"
$storage_Check = Get-ChildItem -Path $source_folder -Directory -Name "storage"


# Checks if the storage directory exists. If it doesn't, it will create a directory. This gives the directory persistence if deleted accidentally by someone. 
if($storage_Check -eq $null) {
    New-Item -Path $storage_folder -ItemType Directory
}

# Checks if the log file exists in storage folder. If it doesn't, it will create the file. 
$log_check = get-childitem -Path $storage_folder -Name "log.txt"

if($log_check -eq $null) {
    $log_header =  "Log file created on "+$date+"."
    New-Item $log_file
    Add-Content $log_file $log_header
    $date_time = Get-Date -Format "yyyy/MM/dd HH:mm:ss"
    $log_mess = "`n("+$date_time+") Task started."
    Add-Content $log_file $log_mess

}else { 
    $date_time = Get-Date -Format "yyyy/MM/dd HH:mm:ss"
    $log_mess = "`n("+$date_time+") Task started."
    Add-Content $log_file $log_mess
    }

#### This limits the size of the log file. Simply change the $maxlines variable accordingly to adjust the size. 
$maxlines = 70000
(get-content $log_file -tail $maxlines -readcount 0) | set-content $log_file

# Grabs unique on files within directory, excludes today's date
$unique_file_dates = get-childitem $source_folder | where-object {$_.Extension -eq ".tif" -or $_.extension -eq ".pdf" } | Select-object -ExpandProperty LastWriteTime | Get-Date -f "yyyy-MM-dd" | select -Unique | Where-Object { $PSItem –ne $date } 

# Makes a folder for each object "aka value" it pulled in the line above, but ONLY if it doesnt already exist. 
ForEach($object in $unique_file_dates){
    if(get-childitem -Path $storage_folder -Attributes Directory | Select-object -Property Name | Where-Object -Property Name -eq $object) {
    write-host "Folder " $object " already exists. No action taken."
    }
    else { 
    mkdir -Path $storage_folder -Name $object
    $date_time = Get-Date -Format "yyyy/MM/dd HH:mm:ss"
    $add_dir_log = "`n("+$date_time+") Created the "+$object+" folder."
    Add-Content $log_file $add_dir_log
    }
}

Start-Sleep -Seconds 1

# This moves all *tifs that are older that are not from today to their respective dated folders. Additionally, it logs each file that's moved. 
Get-ChildItem $source_folder\*.tif, $source_folder\*.pdf | where LastWriteTime -lt $datetomove | foreach { 
    $x = $PSItem.LastWriteTime
    $date_folder = Get-Date $x -Format "yyyy-MM-dd"
    $destination = $storage_folder+"\"+$date_folder 
    move-item $PSItem $destination 
    $date_time = Get-Date -Format "yyyy/MM/dd HH:mm:ss"
    $log_message = "`n("+$date_time+") Moved "+$PSItem+" to the "+$date_folder+" folder."
    Add-Content $log_file $log_message
    }

###########################################
# This is the "housekeeping" section of   #
# the script. Use the $daysback_rem       #
# variable  to set how many days          #
# back we want to keep storage folders.   #
# Currently, we keep these folders for    #
# 30 days, so we'd assign the integer     #
# to -30 days to acheive the desired      #
# results.                                #
#                      -Anthony Mignona   #
#                         01/12/2022      #
###########################################

# This variable dictates the when the storage folders will should be deleted. NOTE updating this variable updates both removal methods 1 & 2 in script accordingly!  
$daysback_rem = -30

##################################################
# DIRECTORY REMOVAL METHOD 1 - BY DIRECTORY NAME #
##################################################

$folder_removal_date = ((Get-Date).AddDays($daysback_rem)).Date | get-date -format "yyyy-MM-dd"
$date_folder_example = get-childitem $storage_folder -Directory | Select-Object -ExpandProperty name

foreach($x in $date_folder_example) {
    $x = [Datetime]::ParseExact($x, 'yyyy-MM-dd', $null)
    if($x -lt $folder_removal_date){
    $x = $x | get-date -format "yyyy-MM-dd"
    $y = $storage_folder+"\"+$x
    Remove-Item $y -Recurse -Force
    $date_time = Get-Date -Format "yyyy/MM/dd HH:mm:ss"
    $rem_log = "`n("+$date_time+") Deleted the "+$y+" folder."
    Add-Content $log_file $rem_log
    }
}

##################################
# Logs script total process time #
##################################

$end_time = get-date
$process_time = NEW-TIMESPAN –Start $start_time –End $end_time
$date_process_log = Get-Date $x -Format "MM-dd-yyyy"
$date_time = Get-Date -Format "yyyy/MM/dd HH:mm:ss"
$process_time_log_mess = "`n("+$date_time+") FINISHED PROCESSING. On "+$date_process_log+" this script took "+($process_time.TotalSeconds)+" second(s) to complete."
Add-Content $log_file $process_time_log_mess