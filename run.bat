@echo off
set SDPath=/sdcard
set OpenHTML=Y
set ForceBackupMode=N
set IPAddr=
set TCPPort=5555
set ExtractRaw=N
set Height=170
set Weight=75


bin\adb kill-server
echo Extract Started > log
date /t >> log

echo Renaming >> log
ren .\db\origin_db origin_db.bak >> log
ren .\db\origin_db-journal origin_db-journal.bak >> log

if .%IPAddr%.==.. goto Wired
echo Connecting to ADB over WiFi >> log
bin\adb tcpip %TCPPort%
bin\adb connect %IPAddr%
::Wait for 5 seconds before attempting to copy data
ping -n 5 0.0.0.0 > nul

:Wired
if .%ForceBackupMode%.==.Y. goto Backup

echo ADB SU copy to sdcard >> log
bin\adb shell "su -c 'cp /data/data/com.xiaomi.hm.health/databases/origin_db* %SDPath%/.'"

echo ADB pull >> log
bin\adb pull %SDPath%/origin_db  .\db\origin_db
bin\adb pull %SDPath%/origin_db-journal .\db\origin_db-journal
bin\adb shell "rm /sdcard/origin_db && rm /sdcard/origin_db-journal"
bin\adb kill-server

if exist .\db\origin_db goto Cont

echo Cannot find database files. Non-rooted phone? Attemting backup approach >>log

:Backup
echo Press "Backup My Data" button on device...
bin\adb backup -f mi.ab -noapk -noshared com.xiaomi.hm.health
bin\adb kill-server

:Cont2
echo unpacking backup file >>log
bin\tail -c +25 mi.ab > mi.zlb
bin\deflate d mi.zlb mi.tar >> log
bin\tar xvf mi.tar apps/com.xiaomi.hm.health/db/origin_db* 2>> log

echo deleting temp files >> log
del mi.ab
del mi.zlb
del mi.tar
copy /Y apps\com.xiaomi.hm.health\db\origin_db* db\. >>log 
rd /s/q apps >>log 2>> log_adb

if exist db\origin_db goto Cont

:Err2
echo Extraction failed
echo Still cannot find files. Restoring original files >> log
ren .\db\origin_db.bak origin_db >> log
ren .\db\origin_db-journal.bak origin_db-journal >> log
goto End

:Cont
echo sqlite operation started >> log
bin\sqlite3 db\origin_db < db\miband.sql >>log

if not .%ExtractRaw%.==.Y. goto Cont3

echo sqlite Raw extraction started >> log
echo INSERT INTO _PersonParams (Height,Weight) VALUES ( %Height%,%Weight%); > db\health.sql
bin\sqlite3 db\origin_db < db\miband_raw.sql >>log

:Cont3
del .\db\origin_db.bak >>log
del .\db\origin_db-journal.bak >>log

if not .%OpenHTML%.==.Y. goto End
if exist mi_data.html start mi_data.html

:End