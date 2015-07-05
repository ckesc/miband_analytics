@@echo off
echo Google Fit Data Tools v0.3

if .%1.==.help. goto Help

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
if .%1.==.listds. goto ListDS
if .%1.==.listdata. goto ListData
if .%1.==.listsess. goto ListSess
if .%1.==.deletedata. goto DeleteData
if .%1.==.backupdata. goto IterateDS
if .%1.==.loaddata. goto LoadData
goto Help

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

:ListDS
echo Sets available in your Google Fit account:
fit\jq -r ".dataSource[] | .dataStreamId" <fit\get_sets.log
goto End

:ListData
if .%2.==.. goto EmptyDS

for /F "delims=" %%i IN ('fit\jq -r ".dataSource[] | select(.dataStreamId | endswith(\"%2\")) | .dataStreamId " ^<%Log%') DO set FitStepsDataSet=%%i
if .%FitStepsDataSet%.==.null. set FitStepsDataSet=
if .%FitStepsDataSet%.==.. goto DSNotFound

echo Listing Session data for DataSet %FitStepsDataSet%
set Log=fit\FitTools.log
del %Log% 2>nul
fit\curl --header "Authorization: Bearer %Gkey%" -X GET --header "Content-Type: application/json;encoding=utf-8" -k "https://www.googleapis.com/fitness/v1/users/me/dataSources/%FitStepsDataSet%/datasets/1000000000000000000-2423299600000000000" -o %Log%
call :Checkerr
goto End

:DeleteData
if .%2.==.. goto EmptyDS

for /F "delims=" %%i IN ('fit\jq -r ".dataSource[] | select(.dataStreamId | endswith(\"%2\")) | .dataStreamId " ^<%Log%') DO set FitStepsDataSet=%%i
if .%FitStepsDataSet%.==.null. set FitStepsDataSet=
if .%FitStepsDataSet%.==.. goto DSNotFound

echo Deleting data for DataSet %FitStepsDataSet%
set Log=fit\FitTools.log
del %Log% 2>nul
fit\curl --header "Authorization: Bearer %Gkey%" --header "Content-Type: application/json;encoding=utf-8" -k -s -X DELETE "https://www.googleapis.com/fitness/v1/users/me/dataSources/"%FitStepsDataSet%"/datasets/1400000000000000000-2423299600000000000" -o %Log%
call :Checkerr
goto End

:IterateDS
if .%2.==.. goto EmptyBackupName
mkdir fit\backup 2>nul
mkdir fit\backup\%2 2>nul
for /F "tokens=1,2,* delims=#" %%I IN ('fit\jq -r ".dataSource[] | .dataStreamId | . + \"#\" + @uri" ^<%Log%') DO (
	echo Backing up %%I
	fit\jq -r ".dataSource[] | select(.dataStreamId | endswith(\"%%I\") )" %Log% >fit\backup\%2\"%%J".def
	fit\curl --header "Authorization: Bearer %Gkey%" -X GET --header "Content-Type: application/json;encoding=utf-8" -k "https://www.googleapis.com/fitness/v1/users/me/dataSources/%%I/datasets/1000000000000000000-2423299600000000000" -o fit\backup\%2\%%J.json -s
	)
goto End

:LoadData
if .%2.==.. goto EmptyJSON
if not EXIST %2.json goto EmptyJSON

if not EXIST %2.def goto NoDS
echo Creating DataSet from %2.def ...
set Log=fit\FitTools1.log
del %Log% 2>nul
fit\curl --header "Authorization: Bearer %Gkey%" --header "Content-Type: application/json;encoding=utf-8" -k -s  -X POST -d @%2.def "https://www.googleapis.com/fitness/v1/users/me/dataSources"  -o %Log%

:NoDS
for /F "delims=" %%i IN ('fit\jq -r ".dataSourceId" ^<"%2.json"') DO set FitDataSet=%%i
if .%FitDataSet%.==.null. set FitDataSet=
if .%FitDataSet%.==.. goto EmptySetName
echo Loading DataSet %FitDataSet%
set Log=fit\FitTools.log
del %Log% 2>nul
fit\curl --header "Authorization: Bearer %Gkey%" --header "Content-Type: application/json;encoding=utf-8" -k -s  -X PATCH -d @%2.json "https://www.googleapis.com/fitness/v1/users/me/dataSources/%FitDataSet%/datasets/1000000000000000000-2423296000000000000" -o %Log%
call :Checkerr
goto End

:EmptySetName
echo Cannot read DataSet name from json file (%2.json)
goto End

:EmptyJSON
echo You need to specify existing filenname for DataSet data (without extension)
goto End

:EmptyDS
echo You need to supply DSNAME (unique identifier for DataSource for which you want to pull session data
goto End

:EmptyBackupName
echo You need to supply backup name
goto End


:DSNotFound
echo DSNAME supplied was not found
goto End

:ListSess
fit\curl --header "Authorization: Bearer %GKey%" -X GET --header "Content-Type: application/json;encoding=utf-8" -k "https://www.googleapis.com/fitness/v1/users/me/sessions?startTime=2001-01-01T00:00:00.00Z&endTime=2020-12-31T23:59:59.99Z"
goto End

:Help
echo Usage:
echo.
echo   FitTools listds          - list all Data Sources in Google Fit account
echo.
echo   FitTools listdata NAME - list data within specified Data Source.
echo       NAME should contain a string uniquely identifying Data Source
echo.
echo   FitTools deletedata NAME - cleans all data within specified Data Source.
echo       NAME should contain a string uniquely identifying Data Source
echo       USE DELETEDATA WITH EXTREME CAUTION. It is strongly recommended
echo       to run FitTools backupdata first
echo.
echo   FitTools listsess        - list all sessions in Google Fit account
echo.
echo   FitTools backupdata NAME - backs up all data sources from Google Fit into
echo       fit\backup\NAME directory. Two files are created per data source.
echo       .def file contains data source definition; 
echo       .json file contains data from that data source
echo.
echo   FitTools loaddata NAME   - loads single dataset file.
echo       NOTE: Only datasets created by Mi Fit Sync application could be
echo       loaded! Other datasets from backup directory could not be loaded.
echo.
echo       Do not specify extension - .json is added automatically. Before
echo       loading dataset data source is created using file with same name
echo       and .def extension (if it exists)
goto End

:End
