Extended analytics for data from Xiaomi Mi Band

![Screenshot](http://i.imgur.com/ALWh4zf.gif)
![Screenshot](http://i.imgur.com/id5BV3q.gif)
![Screenshot](http://i.imgur.com/tg1XKO9.gif)

# Mac OS X
For Mac OS X install fresh sqlite3
```bash
brew install sqlite3
```

# New versions
[Original version here](http://forum.xda-developers.com/general/accessories/xiaomi-mi-band-data-extraction-t3019156/post58575745#post58575745)

[Original russian description here](http://4pda.ru/forum/index.php?showtopic=596501)

# How to use:
Preparation steps:
1. If you plan to use both packages, unpack them both to same directory.
2. Make sure you have USB drivers for your device properly installed and that your device is accessible by ADB when you connect it through USB
3. If you use it on windows, extract package has all binaries included, for Linux/OSX see comments below.

# Checking configuration settings:
1. Review SDPath parameter value in `run.bat/run.sh`. The program will copy files from Mi app location to folder specified in SDPath before pulling
   them to desktop. In most cases default value (`/sdcard`) shoud work fine, however if your phone does not have this directory, find the path where
   your Internal/External SD is mounted and put that path string into SDPath value. Second most common value might be `/storage/sdcard0`
2. Review config.js and make any changes to your liking (set Goals for sleep hours and daily steps, force override UI language to specific value)
3. If you do not want main report being open every time you run extract, change `OpenHTML=Y` in `run.bat/run.sh` to `OpenHTML=N`
4. If your device is not rooted or have any issues with first (root) method that application uses and prefer to skip straight to the second (backup)
   method, set `ForceBackupMode` value to `Y` in `run.bat`.
5. If you are planning to use ADB over WiFi, edit run.sh and set up IPAddr value to IP address of your phone, if you use USB cable, leave `IPAddr`
   value blank. If you using non-default port, you may need to change `TCPPort` value.

You may also think of a great idea of running syncronization automatically and unattended using ADB over Wifi - at least I liked that idea initially.
I gave that idea more thought and as of now I strongly recommend not to do it - having ADB running over Wifi is a security risk, if you have to use it
over Wifi, enable it manually, run the sync and disable ADB over Wifi right away. 

# For Linux/OSX users:
1. You would need to to manually install android-sdk for (adb binary), sqlite3 and openssl to uncompress zlib data. Please note that versions of sqlite3
   and openssl that are preinstalled on your machine might be too old to be used with this package, so you might need to obtain newer versions. For example,
   I was told that sqlite3 3.7.13 that comes preinstalled with OSX was incompatible with some of functions used in script. I would recommend using version
   3.8.x at least.
2. You'll need to grant execute permissions to run.sh by using chmod +x run.sh and you will need to execute run.sh instead of run.bat in steps listed below.
   You'll also need to make configuration changes in run.sh instead of run.bat
3. Check that your sqlite3 is properly configured for your time zone. Run following command and see if it returns correct timestamp:
```bash
bin\sqlite3 dbfile "select datetime('now','localtime');"
```

# Running application:
1. Connect your phone through USB and make sure USB debugging setting is enabled on your phone.
2. Execute `run.bat` - if your phone is rooted, the data would be pulled automatically. If your phone is not rooted you would see backup screen and
   you need to press "Back up my data" button in the bottom left corner.
3. Data from your mi band will be saved to extract.csv file and extract.js. After extraction is complete, if OpenHTML is set to `Y`, `mi_data.html` will
   be opened automatically to show charts for your Mi usage.
4. HTML reports are using Google Charts framework and Google TOS does not allow storing their scripts offline along with the application, therefore
   you will need to have working internet access for reports to work. Your data is not being sent to Google, the internet connection is only used to
   download latest version of Google Charts javascripts.

# Configuration and localization:
`config.js` - Set initial daily goal values; select interface language
`locale.js` - contains all locale data
`run.bat/run.js` - OpenHTML defines whether to open web browser upon extract completion
