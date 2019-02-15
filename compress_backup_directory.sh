#!/bin/bash

if [ -d sdcard ]
then
    echo -e "\n[*] Compressing backup directory...\n"
    zip -r sdcard.zip sdcard
    sleep 1
    echo -e "\n[*] Done"
else
    echo -e "\n[*] Nothing to compress\n"
fi
