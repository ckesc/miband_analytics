--CREATE TEMP TABLE _TimeOffset(FromDt DateTime, ToDt DateTime, Offset TEXT);
--.read db/offset.sql
 
.header on
.mode csv
.output extract.csv
select strftime('%Y-%m-%d',Date)||" " as Date,LightSleepMin+DeepSleepMin as InBedMin,DeepSleepMin,LightSleepMin,SleepStart,SleepEnd,AwakeMin
,DailyDistanceMeter,DailySteps,DailyBurnCalories
,DailyDistanceMeter-RunDistanceMeter as WalkDistance,WalkTimeMin,DailyBurnCalories-RunBurnCalories as WalkBurnCalories
,RunDistanceMeter,RunTimeMin,RunBurnCalories,(WalkTimeMin+RunTimeMin)*60 as WalkRunSeconds,
case strftime('%m',Date) when "01" then "Jan" when "02" then "Feb" when "03" then "Mar" when "04" then "Apr" when "05" then "May" when "06" then "Jun" when "07" then "Jul" when "08" then "Aug" when "09" then "Sep" when "10" then "Oct" when "11" then "Nov" when "12" then "Dec" else "1" end
||strftime(' %d, %Y',Date) as DateUS,"Daily Activity" as Activity,strftime('%H',SleepStart) as BedHour,strftime('%M',SleepStart) as BedMinute,strftime('%H',SleepEnd) as AwakeHour,strftime('%M',SleepEnd) as AwakeMinute
,strftime('%s',datetime(date,'utc')) as DateUnix
,strftime('%s',datetime(SleepStart,'utc')) as SleepStartUnix
,strftime('%s',datetime(SleepStart,'utc')) as SleepEndUnix
,strftime('%s',datetime(datetime(date,'utc'),'+8 hour')) as WalkStart
,strftime('%s',datetime(datetime(datetime(date,'utc'),'+8 hour'), '+'||cast(WalkTimeMin as Text)||' minute')) as WalkEnd
,strftime('%s',datetime(datetime(datetime(date,'utc'),'+8 hour'), '+'||cast(WalkTimeMin+RunTimeMin as Text)||' minute')) as RunkEnd
 from (
select date,summary
,cast(rtrim(substr(summary,instr(summary,'"lt":')+5,7),', "st":') as Integer) as LightSleepMin
,cast(rtrim(substr(summary,instr(summary,'"dp":')+5,7),', "ed":') as Integer) as DeepSleepMin
,cast(rtrim(substr(summary,instr(summary,'"wk":')+5,7),', "dp":') as Integer) as AwakeMin

,datetime(cast(rtrim(substr(summary,instr(summary,'"st":')+5,10),', "wk":') as Integer),'unixepoch','localtime') as SleepStart
,datetime(cast(rtrim(substr(summary,instr(summary,'"ed":')+5,10),', "v":') as Integer),'unixepoch','localtime') as SleepEnd
--,datetime(datetime(cast(rtrim(substr(summary,instr(summary,'"st":')+5,10),', "wk":') as Integer),'unixepoch','localtime'),ifnull(Offset,'+0 hour')) as SleepStart
--,datetime(datetime(cast(rtrim(substr(summary,instr(summary,'"ed":')+5,10),', "v":') as Integer),'unixepoch','localtime'),ifnull(Offset,'+0 hour')) as SleepEnd

,cast(rtrim(substr(summary,instr(summary,'"rn":')+5,7),', "cal"') as Integer) as RunTimeMin
,cast(rtrim(substr(summary,instr(summary,'"runDist":')+10,7),', "wk":') as Integer) as RunDistanceMeter
,cast(rtrim(substr(summary,instr(summary,'"runCal":')+9,7),', "dis"') as Integer) as RunBurnCalories

,cast(rtrim(substr(substr(summary,instr(summary,'"wk":')+5),instr(substr(summary,instr(summary,'"wk":')+5),'"wk":')+5,7),', "ttl"') as Integer) as WalkTimeMin
,cast(rtrim(substr(summary,instr(summary,'"ttl":')+6,7),', "runC') as Integer) as DailySteps
,cast(rtrim(substr(summary,instr(summary,'"dis":')+6,7),'}}') as Integer) as DailyDistanceMeter
,cast(rtrim(substr(summary,instr(summary,'"cal":')+6,4),', "runD') as Integer) as DailyBurnCalories

 from date_data d
 -- left outer join _TimeOffset t on d.Date >= t.FromDt and d.Date < t.ToDt
 where type = 0) order by date;

--cast(SleepStart as text)||","||cast(SleepEnd as text)||","||

.header off
.mode list
.output extract.js
.print "data.addRows([ "
select "[new Date(" ||strftime('%Y',Date)||","||cast((cast(strftime('%m',Date) as integer)-1) as text)||","|| strftime('%d',Date) ||"),"|| strftime('%Y',Date)
||","""||strftime('%Y-%m',Date)||""","||strftime('%m',Date)||","""||strftime('%Y-%W',Date)||""","||strftime('%W',Date)||","||strftime('%w',Date)
||","||strftime('%d',Date)||","||cast(LightSleepMin+DeepSleepMin as text)||","||cast(DeepSleepMin as text)||","||cast(LightSleepMin as text)||","||
cast(AwakeMin as text)||","||cast(DailyDistanceMeter as text)||","||cast(DailySteps as text)||","||cast(DailyBurnCalories as text)||","||
cast(DailyDistanceMeter-RunDistanceMeter as text)||","||cast(WalkTimeMin as text)||","||cast(DailyBurnCalories-RunBurnCalories as text)||","||
cast(RunDistanceMeter as text)||","||cast(RunTimeMin as text)||","||cast(RunBurnCalories as text)||","||
--cast(720+(SleepStart-strftime('%s',date))/60 as text)||","||cast((SleepEnd-SleepStart)/60 as text)
"new Date(0,0,"||case when SleepStart < Date then "-1" else "0" end||","||strftime('%H',SleepStart)||","||strftime('%M',SleepStart)||","||strftime('%S',SleepStart)||"),"||
"new Date(0,0,"||case when SleepEnd < Date then "-1" else "0" end||","||strftime('%H',SleepEnd)||","||strftime('%M',SleepEnd)||","||strftime('%S',SleepEnd)||")"

||"]"||case when date = (select max(date) from date_data) then "" else "," end
 from (
select id,date,summary
,cast(rtrim(substr(summary,instr(summary,'"lt":')+5,7),', "st":') as Integer) as LightSleepMin
,cast(rtrim(substr(summary,instr(summary,'"dp":')+5,7),', "ed":') as Integer) as DeepSleepMin
,cast(rtrim(substr(summary,instr(summary,'"wk":')+5,7),', "dp":') as Integer) as AwakeMin

--,datetime(datetime(cast(rtrim(substr(summary,instr(summary,'"st":')+5,10),', "wk":') as Integer),'unixepoch','localtime'),ifnull(Offset,'+0 hour')) as SleepStart
--,datetime(datetime(cast(rtrim(substr(summary,instr(summary,'"ed":')+5,10),', "v":') as Integer),'unixepoch','localtime'),ifnull(Offset,'+0 hour')) as SleepEnd
,datetime(cast(rtrim(substr(summary,instr(summary,'"st":')+5,10),', "wk":') as Integer),'unixepoch','localtime') as SleepStart
,datetime(cast(rtrim(substr(summary,instr(summary,'"ed":')+5,10),', "v":') as Integer),'unixepoch','localtime') as SleepEnd

,cast(rtrim(substr(summary,instr(summary,'"rn":')+5,7),', "cal"') as Integer) as RunTimeMin
,cast(rtrim(substr(summary,instr(summary,'"runDist":')+10,7),', "wk":') as Integer) as RunDistanceMeter
,cast(rtrim(substr(summary,instr(summary,'"runCal":')+9,7),', "dis"') as Integer) as RunBurnCalories

,cast(rtrim(substr(substr(summary,instr(summary,'"wk":')+5),instr(substr(summary,instr(summary,'"wk":')+5),'"wk":')+5,7),', "ttl"') as Integer) as WalkTimeMin
,cast(rtrim(substr(summary,instr(summary,'"ttl":')+6,7),', "runC') as Integer) as DailySteps
,cast(rtrim(substr(summary,instr(summary,'"dis":')+6,7),'}}') as Integer) as DailyDistanceMeter
,cast(rtrim(substr(summary,instr(summary,'"cal":')+6,4),', "runD') as Integer) as DailyBurnCalories
 from date_data d
-- left outer join _TimeOffset t on d.Date >= t.FromDt and d.Date < t.ToDt
 where type = 0) order by date;
.print ]);

.header off
.mode list
.output minmaxtime.csv

with MyTable as (
select id,datetime(date,'utc') as dt
,datetime(cast(rtrim(substr(summary,instr(summary,'"st":')+5,10),', "wk":') as Integer),'unixepoch','utc') as SleepStart
,datetime(cast(rtrim(substr(summary,instr(summary,'"ed":')+5,10),', "v":') as Integer),'unixepoch','utc') as SleepEnd
,cast(rtrim(substr(summary,instr(summary,'"rn":')+5,7),', "cal"') as Integer) as RunTimeMin
,cast(rtrim(substr(substr(summary,instr(summary,'"wk":')+5),instr(substr(summary,instr(summary,'"wk":')+5),'"wk":')+5,7),', "ttl"') as Integer) as WalkTimeMin
 from date_data d
 where type = 0 order by date
),
MaxTime as
(
select EndTime from (select datetime(datetime(dt,'+8 hour'),'+'||cast(WalkTimeMin+RunTimeMin as Text)||' minute') as EndTime
from MyTable order by dt desc limit 1)
union all
select max(SleepEnd) from MyTable
union all
select EndTime from (select datetime(dt) as EndTime from MyTable order by dt asc limit 1)
union all
select min(SleepStart) from MyTable
)
select strftime('%s',max(EndTime)),strftime('%s',min(EndTime)) from MaxTime;


.header off
.mode list
.output app_locale.js
select "var app_lang = """||locale||""";" from android_metadata;

--DROP TABLE _TimeOffset;
--ATTACH DATABASE "db\user-db" AS user;
--.header on
--.mode csv
--.once log.csv
--select date || '  ' || time as date, text1, text2 from user.[LUA_LIST] where [INDEX] is null;
