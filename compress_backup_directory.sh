#!/bin/bash

if [ -d sdcard ]
then
    echo -e "\nCompressing backup directory...\n"
    zip -r sdcard.zip sdcard
    sleep 1
    echo -e "\nDone"
else
    echo -e "\nNothing to compress\n"
fi
