#!/bin/bash

#vars
DATE=`date "+%Y-%m-%d"`
i=1

devices_list=""
device_number=""
backup_path=""
HDD_filesystem=""

#Convert bytes to K/M/T Bytes
function bytes_mb_gb_tb()
{
    let aux=0    
    let cont=0
    flag=true
    let value=$1    

    while $flag; do
        if [ $( printf "%.0f" $value ) -eq 0 ]; then
            flag=false
        else
            aux=$value
            value=`bc -l <<< "$value/1024"`
            let "cont++"
        fi
    done

    if [ $cont != 0 ]; then
        let "cont--"
    fi


    case "$cont" in
    
        0) echo "$aux bytes";;

        1) echo "$aux KB";;

        2) echo "$aux MB";;

        3) echo "$aux GB";;

        4) echo "$aux TB";;
    esac
}

#Gets the file that contains the size of the internal storage of the Android device in bytes
function get_sdcard_size()
{
    sdcard_size_file=sdcard_bytes_size_$device_id.txt
    
    while read -r line; do
        size="$line"
    done < "$sdcard_size_file"

    echo $size
}

#Find the name of the directory inside the file, and prints the size of the directory in the second column
function get_dir_file_size()
{
    directories_list_file=../contents_list_$device_id.txt
    size=`grep -R $1 $directories_list_file | cut -f2`

    echo $size
}

#Prints the available space of the HDD
function HDD_space()
{
   #FNR prints the line number, {print $#} prints the number field 
   ava_disk_space_bytes=`df -B1 "$HDD_filesystem" | awk 'FNR == 2 {print $4}'`

   echo $ava_disk_space_bytes
}

#Copy all the content inside the /sdcard/ directory of the Android device
function fullBackup()
{
   ava_disk_space_bytes=`HDD_space`
   ava_disk_space=`bytes_mb_gb_tb $ava_disk_space_bytes`

   adb -s $device_id pull /sdcard/sdcard_bytes_size.txt > /dev/null 2>&1
   mv sdcard_bytes_size.txt sdcard_bytes_size_$device_id.txt

   backup_size_bytes=`get_sdcard_size`
   backup_size=`bytes_mb_gb_tb $backup_size_bytes`

   sleep 4

   echo -e "\nAvailable Space on HDD: $ava_disk_space"

   sleep 4

   echo -e "\nBackup Size: $backup_size\n"

   sleep 4

   if [ ! "$ava_disk_space_bytes" -gt "$backup_size_bytes" ]; then
      echo -e "\nThere isn't enough space in the Backup HDD\n"
      exit
   fi

   adb -s $device_id pull /sdcard/

   if [ ! $? -eq 0 ]; then
      echo -e "\nCheck your device connection and try again, don't forget to delete the corrupted backup directory of today\n"
      exit
   fi

   echo -e "\nBackup sucessfully complete\n"
   sleep 1
   cp ~/'Backups Scripts'/compress_backup_directory.sh .
}

#Shows the content of the /sdcard/ directory and let you choose which File/Directory want to copy
function partialBackup()
{
   mkdir sdcard
   cd sdcard

   while read -u 2 line; do
      
      j=`echo -e $line | cut -f3`
      type=`echo -e $line | cut -f1`

      sleep 3

      if [ "$type" = "d" ]; then
         showDirectoryContents
      else
         showFile
      fi
   done 2< ../contents_list_$device_id.txt
}

function pullDirectory()
{
   echo -e "\nBacking up directory '$j/' ...\n"
   sleep 3
   adb -s $device_id pull /sdcard/"$j"/
}

function pullFile()
{
   echo -e "\nBacking up file '$j' ...\n"
   sleep 3
   adb -s $device_id pull /sdcard/"$j"	
}

function showDirectoryContents()
{
   echo -e "\n\n\n\nThese are the files and directories inside the '$j/' directory: \n\n"
   sleep 1
   adb -s $device_id shell "cd sdcard && ls -la '$j'" | awk '{print $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18}' > ../temp_dir_list.txt
   sed -i '1,3d' ../temp_dir_list.txt
   cat ../temp_dir_list.txt

   directory_size_bytes=`get_dir_file_size $j`
   directory_size=`bytes_mb_gb_tb $directory_size_bytes`

   echo -e "\n\nDirectory '$j' size: $directory_size"

   HDD_ava_space_bytes=`HDD_space`
   HDD_ava_space=`bytes_mb_gb_tb $HDD_ava_space_bytes`

   echo -e "\nAvailable Space on HDD: $HDD_ava_space"

   valid_danswer=false

   while [ $valid_danswer == false ]; do
      echo -e "\n\nDo you want to backup '$j/' directory? [ y/n ]"
      read danswer

      if [ "$danswer" = "y" ]; then
         sleep 3
         pullDirectory 
         valid_danswer=true
         sleep 3
      elif [ "$danswer" != "n" ]; then
         echo -e "\nInvalid option."
      else
         valid_danswer=true
      fi
   done
}

function showFile()
{
   file_size_bytes=`get_dir_file_size $j`
   file_size=`bytes_mb_gb_tb $file_size_bytes`

   echo -e "\n\n\n\nFile '$j' size: $file_size"

   HDD_ava_space_bytes=`HDD_space`
   HDD_ava_space=`bytes_mb_gb_tb $HDD_ava_space_bytes`

   echo -e "\nAvailable Space on HDD: $HDD_ava_space"

   valid_fanswer=false

   while [ $valid_fanswer == false ]; do
      echo -e "\n\nDo you want to backup '$j' file? [ y/n ]"
      read fanswer

      if [ "$fanswer" = "y" ]; then
         sleep 3
         pullFile $j
         valid_fanswer=true
         sleep 3
      elif [ "$fanswer" != "n" ]; then
         echo -e "\nInvalid option"
      else
         valid_fanswer=true
      fi
   done
}

function printAndroidDevices()
{
   echo -e "\nList of connected Android devices:"
   echo -e "----------------------------------\n"
   line_num=0

   IFS=$'\n'

   for line in `adb devices`; do
      device=`echo "$line" | cut -f1`

      if [[ $line_num != 0 ]] && [[ ! -z $line ]]; then
         echo "$line_num) $device"
         devices_list+="$device\n"
      fi

      line_num=$(( line_num + 1 ))
   done

   if [ $line_num = 1 ]; then
      echo -e "No Android devices connected!\n"
      exit 1
   fi
}

function getDeviceToBackup()
{
   valid_dev_num=false

   while [ $valid_dev_num == false ]; do
      echo -e "\nType the number of the device to backup:"
      read device_number

      if [[ $device_number -gt 0 ]] && [[ $device_number -lt line_num ]] ; then
         valid_dev_num=true
      fi
   done
}

function checkRequirements()
{
   HDD_filesystem=`sudo blkid -U 574627C9574BE550`

   if [ -z $HDD_filesystem ]; then
      echo -e "\n[*] The HDD is different from the backups HDD or isn't connected\n"
      sleep 1
      exit 3
   fi

   HDD_mountpoint=`df -h | grep $HDD_filesystem | awk '{print $6}'`

   if [ -z "$HDD_mountpoint" ]; then
      echo -e "\n[*] HDD of backups isn't mounted\n"
      sleep 1
      exit 4
   fi

   backup_path=$HDD_mountpoint
   backup_path+="/Backups/"
   backup_path+=$device_id

   if [ ! -d "$backup_path" ]; then
      echo -e "\n[*] Directory of backup doesn't exists\n"
      sleep 1
      exit 5
   fi
}

############
#Main Rutine
############

echo ""
sudo adb start-server

echo -e "\nRunning backup script..."

echo -e "\nDATE: "$DATE
sleep 1

printAndroidDevices

getDeviceToBackup

device_id=`echo -e $devices_list | awk 'FNR =='$device_number`

checkRequirements

cd "$backup_path"
 
if [ -d $DATE ]; then
   echo -e "\nThe backup of today already exists!"
   sleep 1
   echo -e "\nCheck the backup folder!\n"
   exit 6
fi

mkdir $DATE
cd $DATE
      
echo -e "\nStarting the backup process...\n"

touch temp_dir_list.txt

adb -s $device_id pull /sdcard/contents_list.txt > /dev/null 2>&1
mv contents_list.txt contents_list_$device_id.txt

echo -e "\nThese are all the files and directories in 'sdcard/': \n"
sleep 5

cat contents_list_$device_id.txt | cut -f3

sleep 1

valid_option=false

while [ $valid_option == false ]; do
   echo -e "\nWhat do you want to do?"
   echo "    a) A full backup ( all files and directories )"
   echo -e "    b) Choose which files and/or directories to backup\n"

   printf '%s' '-> '
   read answer

   if [[ "$answer" = "a"  ]] || [[ "$answer" = "b" ]]; then
      valid_option=true
   else
      echo -e "\nInvalid option."
   fi
done

if [ "$answer" = "a"  ]; then
   fullBackup
else
   partialBackup
fi

exit 0
