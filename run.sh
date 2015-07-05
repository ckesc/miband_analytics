#!/bin/bash

SDPath=/sdcard
OpenHTML=Y
ForceBackupMode=Y

# 1i8n support
export TEXTDOMAIN=mibandextract
# folder with .mo langage file, comment this line if you want to move
# .mo file in /usr/share/locale/XX/LC_MESSAGES/
export TEXTDOMAINDIR=./i18n/


if [ ! $ForceBackupMode == 'Y' ];then
 echo $"Extract Started" 2>&1 | tee log
 echo `date +"%m-%d-%y %H:%M"` 2>&1 | tee -a log
 
 echo $"Renaming" 2>&1 | tee -a log
 [[ -f ./db/origin_db ]] && mv ./db/origin_db ./origin_db.bak 2>&1 | tee -a log
 [[ -f ./db/origin_db-journal ]] && mv ./db/origin_db-journal ./db/origin_db-journal.bak 2>&1 | tee -a log
 
 echo $"ADB SU copy to sdcard" 2>&1 | tee -a log
 adb shell "su -c 'cp /data/data/com.xiaomi.hm.health/databases/origin_db* $SDPath/.'" 2>&1 | tee -a log
 echo $"ADB pull" >> log
 adb pull $SDPath/origin_db  ./db/origin_db 2>&1 | tee -a log
 adb pull $SDPath/origin_db-journal ./db/origin_db-journal 2>&1 | tee -a log
 adb shell "rm /sdcard/origin_db && rm /sdcard/origin_db-journal" 2>&1 | tee -a log

else 
echo "ok"
if [ ! -f ./db/origin_db ] || [ $ForceBackupMode == 'Y' ]
 then
     echo $"Cannot find database files. Non-rooted phone? Attemting backup approach" 2>&1 | tee -a log
     echo $"Press Backup My Data button on device..." 2>&1 | tee -a log
     adb backup -f mi.ab -noapk -noshared com.xiaomi.hm.health
     echo $"unpacking backup file"  2>&1 | tee -a log
     tail -c +25 mi.ab > mi.zlb  2>&1 | tee -a log
     cat mi.zlb | openssl zlib -d > mi.tar 2>&1 | tee -a log
     tar xvf mi.tar apps/com.xiaomi.hm.health/db/origin_db apps/com.xiaomi.hm.health/db/origin_db-journal  2>&1 | tee -a log
 
     echo $"deleting temp file" 2>&1 | tee -a log
     rm mi.ab
     rm mi.zlb
     rm mi.tar
     cp -f apps/com.xiaomi.hm.health/db/origin_db* ./db/
     rm -rf apps/
 fi
 
 
 if [ ! -f ./db/origin_db ]
 then
    echo $"Extraction failed"
    echo $"Still cannot find files. Restoring original files"
    [[ -f ./db/origin_db.bak ]] && mv ./db/origin_db.bak ./db/origin_db
    [[ -f ./db/origin_db-journal.bak ]] && mv ./db/origin_db-journal.bak origin_db-journal
 else
     echo $"sqlite operation started" 2>&1 | tee -a log
     sqlite3 ./db/origin_db < ./db/miband.sql | tee -a log
     [[ -f ./db/origin_db.bak ]] && rm ./db/origin_db.bak | tee -a log
     [[ -f ./db/origin_db-journal.bak ]] && rm ./db/origin_db-journal.bak | tee -a log
     
     [[ $OpenHTML == 'Y' ]] && xdg-open mi_data.html  
  
 fi
fi



