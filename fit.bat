@@echo off
echo MiBand sync to Google Fit v0.3

if .%1.==.help. goto Help
set FitSteps=1324439
set FitSegments=1324438
set FitDistance=1324440
set FitOld=1324437

if NOT .%GKey%.==.. goto Start
echo Open http://http://mefit-run1-857.appspot.com/ in your browser and paste Token value here:
set /p GKey=Token:
set FitStepsDataSet=
set FitSegmentsDataSet=
set FitOldDataSet=
set FitDistanceDataSet=

:Start
set Log=fit\get_sets.log
del %Log% 2>nul
fit\curl --header "Authorization: Bearer %Gkey%" --header "Content-Type: application/json;encoding=utf-8" -k -s  -X GET "https://www.googleapis.com/fitness/v1/users/me/dataSources" -o %Log%
call :Checkerr

for /F "delims=" %%i IN ('fit\jq -r ".dataSource[] | select(.dataStreamId | contains(\"%FitSteps%\")) | .dataStreamId " ^<%Log%') DO set FitStepsDataSet=%%i
if .%FitStepsDataSet%.==.null. set FitStepsDataSet=

for /F "delims=" %%i IN ('fit\jq -r ".dataSource[] | select(.dataStreamId | contains(\"%FitSegments%\")) | .dataStreamId " ^<%Log%') DO set FitSegmentsDataSet=%%i
if .%FitSegmentsDataSet%.==.null. set FitSegmentsDataSet=

for /F "delims=" %%i IN ('fit\jq -r ".dataSource[] | select(.dataStreamId | contains(\"%FitOld%\")) | .dataStreamId " ^<%Log%') DO set FitOldDataSet=%%i
if .%FitOldDataSet%.==.null. set FitOldDataSet=

for /F "delims=" %%i IN ('fit\jq -r ".dataSource[] | select(.dataStreamId | contains(\"%FitDistance%\")) | .dataStreamId " ^<%Log%') DO set FitDistanceDataSet=%%i
if .%FitDistanceDataSet%.==.null. set FitDistanceDataSet=

if .%1.==.clean. goto Clean
if not .%1.==.. goto Help

set FitSetName=%FitSteps%
if .%FitStepsDataSet%.==.. goto AddDataSet

set FitSetName=%FitSegments%
if .%FitSegmentsDataSet%.==.. goto AddDataSet

set FitSetName=%FitDistance%
if .%FitDistanceDataSet%.==.. goto AddDataSet

::echo FitStepsDataSet %FitStepsDataSet%
::echo FitSegmentsDataSet %FitSegmentsDataSet%

for /F "tokens=1,* delims=," %%A IN (minmaxtime.csv) do (
	echo {"dataSourceId": "%FitStepsDataSet%", "maxEndTimeNs": %%A000000000,"minStartTimeNs": %%B000000000, "point": [ >fit\steps.json
	echo {"dataSourceId": "%FitSegmentsDataSet%", "maxEndTimeNs": %%A000000000,"minStartTimeNs": %%B000000000, "point": [ >fit\segments.json
	echo {"dataSourceId": "%FitSegmentsDataSet%", "maxEndTimeNs": %%A000000000,"minStartTimeNs": %%B000000000, "point": [ >fit\sessions.json
	echo {"dataSourceId": "%FitDistanceDataSet%", "maxEndTimeNs": %%A000000000,"minStartTimeNs": %%B000000000, "point": [ >fit\distance.json
	set FitMin=%%B
	set FitMax=%%A
)

Setlocal EnableDelayedExpansion
set FitComma=
for /F "tokens=8,9,10,25,26,27,28,29,30,* delims=, skip=1" %%A IN (extract.csv) DO (
::	echo %%A, %%B, %%C, %%D
	echo !FitComma!{"dataTypeName": "com.google.step_count.delta","startTimeNanos":%%G000000000, "endTimeNanos":%%H000000000, "value": [{"intVal": %%B}]} >>fit\steps.json
	echo !FitComma!{"dataTypeName": "com.google.distance.delta","startTimeNanos":%%G000000000, "endTimeNanos":%%H000000000, "value": [{"fpVal": %%A}]} >>fit\distance.json
	echo !FitComma!{"dataTypeName": "com.google.activity.segment","startTimeNanos":%%G000000000, "endTimeNanos":%%H000000000, "value": [{"intVal": "7"}]} >>fit\segments.json
	set FitComma=,
	echo !FitComma!{"dataTypeName": "com.google.activity.segment","startTimeNanos":%%H000000000, "endTimeNanos":%%I000000000, "value": [{"intVal": "8"}]} >>fit\segments.json
	echo !FitComma!{"dataTypeName": "com.google.activity.segment","startTimeNanos":%%E000000000, "endTimeNanos":%%F000000000, "value": [{"intVal": "72"}]} >>fit\segments.json
	echo %%D000@{"id": "%%D000","name": "Session from MeBand","startTimeMillis": "%%F000","endTimeMillis": "%%G000","application":{"name": "MeStream","version": "1.0"},"activityType": 7} >>fit\sessions.json
	echo %%D008@{"id": "%%D008","name": "Session from MeBand","startTimeMillis": "%%G000","endTimeMillis": "%%H000","application":{"name": "MeStream","version": "1.0"},"activityType": 8} >>fit\sessions.json
	set FitLastDate=%%D
)
echo ]} >>fit\steps.json
echo ]} >>fit\segments.json
echo ]} >>fit\distance.json
echo !FitLastDate! > fit\last.csv

echo Populating steps
set Log=fit\post.log
del %Log% 2>nul
fit\curl --header "Authorization: Bearer %Gkey%" --header "Content-Type: application/json;encoding=utf-8" -k -s  -X PATCH -d @fit\steps.json "https://www.googleapis.com/fitness/v1/users/me/dataSources/%FitStepsDataSet%/datasets/1000000000000000000-2423296000000000000" -o %Log%
call :Checkerr

echo Populating segments
set Log=fit\post_segment.log
del %Log% 2>nul
fit\curl --header "Authorization: Bearer %Gkey%" --header "Content-Type: application/json;encoding=utf-8" -k -s  -X PATCH -d @fit\segments.json "https://www.googleapis.com/fitness/v1/users/me/dataSources/%FitSegmentsDataSet%/datasets/1000000000000000000-2423296000000000000" -o %Log%
call :Checkerr

echo Populating distance
set Log=fit\post_distance.log
del %Log% 2>nul
fit\curl --header "Authorization: Bearer %Gkey%" --header "Content-Type: application/json;encoding=utf-8" -k -s  -X PATCH -d @fit\distance.json "https://www.googleapis.com/fitness/v1/users/me/dataSources/%FitDistanceDataSet%/datasets/1000000000000000000-2423296000000000000" -o %Log%
call :Checkerr

echo All Done.
goto End

echo Populating Sessions
for /F "tokens=1,* delims=|" %%I IN (fit\sessions.json) DO (
	echo %%J > tmp.json
	call fit\add_session.bat %%I tmp.json
)	
goto End

:AddDataSet
echo %FitSetName% is empty, creating it.
set Log=fit\post_segment.log
del %Log% 2>nul
fit\curl --header "Authorization: Bearer %Gkey%" --header "Content-Type: application/json;encoding=utf-8" -k -s  -X POST -d @fit\%FitSetName%.json "https://www.googleapis.com/fitness/v1/users/me/dataSources"  -o %Log%
call :Checkerr
goto Start

:Clean

if .%FitOldDataSet%.==.. goto Clean1
echo Cleaning %FitOldDataSet%...
set Log=fit\clean_old.log
del %Log% 2>nul
fit\curl --header "Authorization: Bearer %Gkey%" --header "Content-Type: application/json;encoding=utf-8" -X DELETE "https://www.googleapis.com/fitness/v1/users/me/dataSources/"%FitOldDataSet%"/datasets/1400000000000000000-2423299600000000000" -o %Log% -k -s
call :Checkerr

:Clean1
if .%FitStepsDataSet%.==.. goto Clean2
echo Cleaning %FitStepsDataSet%...
set Log=fit\clean_steps.log
del %Log% 2>nul
fit\curl --header "Authorization: Bearer %Gkey%" --header "Content-Type: application/json;encoding=utf-8" -k -s -X DELETE "https://www.googleapis.com/fitness/v1/users/me/dataSources/"%FitStepsDataSet%"/datasets/1400000000000000000-2423299600000000000" -o %Log%
call :Checkerr

:Clean2
if .%FitSegmentsDataSet%.==.. goto Clean3
echo Cleaning %FitSegmentsDataSet%...
set Log=fit\clean_segments.log
del %Log% 2>nul
fit\curl --header "Authorization: Bearer %Gkey%" --header "Content-Type: application/json;encoding=utf-8" -k -s -X DELETE "https://www.googleapis.com/fitness/v1/users/me/dataSources/"%FitSegmentsDataSet%"/datasets/1400000000000000000-2423299600000000000" -o %Log%
call :Checkerr

:Clean3
if .%FitDistanceDataSet%.==.. goto Clean4
echo Cleaning %FitDistanceDataSet%...
set Log=fit\clean_distance.log
del %Log% 2>nul
fit\curl --header "Authorization: Bearer %Gkey%" --header "Content-Type: application/json;encoding=utf-8" -k -s -X DELETE "https://www.googleapis.com/fitness/v1/users/me/dataSources/"%FitDistanceDataSet%"/datasets/1400000000000000000-2423299600000000000" -o %Log%
call :Checkerr

:Clean4
goto End

set Log=fit\clean_sessions.log
del %Log% 2>nul
for /F "skip=1 tokens=1,* delims=@" %%I IN (fit\sessions.json) DO (
	echo deleting session %%I
	fit\curl --header "Authorization: Bearer %Gkey%" --header "Content-Type: application/json;encoding=utf-8" -k -s  -X DELETE "https://www.googleapis.com/fitness/v1/users/me/sessions/%%I" -o %Log%
	call :Checkerr
)	
goto End

:CheckErr
if not EXIST %Log% goto :eof
for /F "delims=" %%i IN ('fit\jq ".error | .message" ^<%Log%') DO set JSONErr=%%i
if .%JSONErr%.==.null. set JSONErr=
if .%JSONErr%.==.. goto :eof
echo Error in %Log% file: %JSONErr%.
if not .%JSONErr%.==."Invalid Credentials". goto ErrCont
echo Most likely your existing token is expired or not set. Please obtain new token at http://mefit-run1-857.appspot.com/ and rerun fit.bat
set GKey=
:ErrCont
for /F "delims= " %%i IN ('fit\jq ".error | .errors[] | .reason" ^<%Log%') DO set JSONErr=%%i
echo Reason: %JSONErr%
call :Abort 2>nul
goto :eof

:Abort
()
exit /b

:Help
echo Usage:
echo   FitSync                 - Syncrhonize with Google Fit
echo   FitSync clean           - clean data previously syncdhonized using this program
goto End

:End
::del fit\sessions.json 2>nul
del fit\segments.json 2>nul
del fit\distance.json 2>nul
del fit\steps.json 2>nul


