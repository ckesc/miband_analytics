CREATE TEMP TABLE _PersonParams(Height,Weight);

.read db/health.sql

CREATE TEMP TABLE _CalList(Dist,Cal);
INSERT INTO _CalList (Dist,Cal) VALUES (40.233,0.95);
INSERT INTO _CalList (Dist,Cal) VALUES (53.645,1.19);
INSERT INTO _CalList (Dist,Cal) VALUES (67.056,1.41);
INSERT INTO _CalList (Dist,Cal) VALUES (80.467,1.57);
INSERT INTO _CalList (Dist,Cal) VALUES (93.878,1.78);
INSERT INTO _CalList (Dist,Cal) VALUES (107.29,2.36);
INSERT INTO _CalList (Dist,Cal) VALUES (120.7,2.97);
INSERT INTO _CalList (Dist,Cal) VALUES (134.11,3.79);
INSERT INTO _CalList (Dist,Cal) VALUES (160.94,4.67);
INSERT INTO _CalList (Dist,Cal) VALUES (187.76,5.24);
INSERT INTO _CalList (Dist,Cal) VALUES (214.58,5.62);
INSERT INTO _CalList (Dist,Cal) VALUES (241.4,6.1);
INSERT INTO _CalList (Dist,Cal) VALUES (268.23,6.91);
INSERT INTO _CalList (Dist,Cal) VALUES (295.05,7.62);
INSERT INTO _CalList (Dist,Cal) VALUES (321.87,9.05);
INSERT INTO _CalList (Dist,Cal) VALUES (348.69,9.43);
INSERT INTO _CalList (Dist,Cal) VALUES (375.52,10.95);

CREATE TEMP TABLE _Hght(h1);
insert into _Hght select Height*0.42/100 from _PersonParams;

CREATE temp TABLE blobdata (
     id INTEGER,
     pos integer,
     b1 integer,
     b2 integer,
     b3 integer
);

with hexrec(i,l,r,c11,c12,c21,c22,c31,c32) as (
 select id,0,hex(data),'','','','','','' from date_data
union all
 select i,
 l+1 as l,
 substr(r,7),
 substr(r,1,1),
 substr(r,2,1),
 substr(r,3,1),
 substr(r,4,1),
 substr(r,5,1),
 substr(r,6,1)
from hexrec
where length(r) > 0
)
insert into blobdata
select i,l,
case c11 when '0' then 0 when '1' then 1 when '2' then 2 when '3' then 3 when '4' then 4 when '5' then 5 when '6' then 6 when '7' then 7 when '8' then 8 when '9' then 9 when 'A' then 10 when 'B' then 11 when 'C' then 12 when 'D' then 13 when 'E' then 14 when 'F' then 15 else 0 end * 16 +
case c12 when '0' then 0 when '1' then 1 when '2' then 2 when '3' then 3 when '4' then 4 when '5' then 5 when '6' then 6 when '7' then 7 when '8' then 8 when '9' then 9 when 'A' then 10 when 'B' then 11 when 'C' then 12 when 'D' then 13 when 'E' then 14 when 'F' then 15 else 0 end,
case c21 when '0' then 0 when '1' then 1 when '2' then 2 when '3' then 3 when '4' then 4 when '5' then 5 when '6' then 6 when '7' then 7 when '8' then 8 when '9' then 9 when 'A' then 10 when 'B' then 11 when 'C' then 12 when 'D' then 13 when 'E' then 14 when 'F' then 15 else 0 end * 16 +
case c22 when '0' then 0 when '1' then 1 when '2' then 2 when '3' then 3 when '4' then 4 when '5' then 5 when '6' then 6 when '7' then 7 when '8' then 8 when '9' then 9 when 'A' then 10 when 'B' then 11 when 'C' then 12 when 'D' then 13 when 'E' then 14 when 'F' then 15 else 0 end,
case c31 when '0' then 0 when '1' then 1 when '2' then 2 when '3' then 3 when '4' then 4 when '5' then 5 when '6' then 6 when '7' then 7 when '8' then 8 when '9' then 9 when 'A' then 10 when 'B' then 11 when 'C' then 12 when 'D' then 13 when 'E' then 14 when 'F' then 15 else 0 end * 16 +
case c32 when '0' then 0 when '1' then 1 when '2' then 2 when '3' then 3 when '4' then 4 when '5' then 5 when '6' then 6 when '7' then 7 when '8' then 8 when '9' then 9 when 'A' then 10 when 'B' then 11 when 'C' then 12 when 'D' then 13 when 'E' then 14 when 'F' then 15 else 0 end
from hexrec rt
where l > 0;

create index b1 on blobdata(id,pos);

.header on
.mode csv
.output extract_raw.csv
select time,description,steps
,round(iDistance,2) as WalkDistance
,case when runs> 0 then Round(((3+runs*2) * iDistance / 15),2) else 0 end as RunDistance
,case when steps > 0 then Round((weight *2.2046 *  iDistance * (select coalesce(max(Cal),0.95)/coalesce(max(Dist),40.233) from _CalList where Dist <= iDistance) / 60),2) else 0 end as WalkCalories
,case when runs> 0 then Round(((3+runs*2.0) /15 * weight *2.2046 *  iDistance * (select coalesce(max(Cal),0.95)/coalesce(max(Dist),40.233) from _CalList where Dist <= iDistance) / 60),2) else 0 end as RunCalories
,RawActivity,RawSensorData

 from (
select datetime(d.date,'+'||cast(pos as text)||' minute') as time
,case when b1 in (4,5) then 'Sleep' when b1 > 15 and b3 > 0 then 'Run' when b1 > 0 and b3 > 0 then 'Walk' else 'Idle' end as Description
,case when b1 not in (4,5) then b3 else 0 end as Steps
,b1 as RawActivity
,b2 as RawSensorData
,case when b3 > 0 then (b1 >> 4) else 0 end as Runs
--,case when b3 > 0 then (b1 & 0xf) else 0 end as mode
,case when b3> 0 and b1 not in (4,5) then case when b3 <= 90 then b3*h1*0.9 else b3*b3*h1/(case when b3 > 120 then 125 else 100 end) end else 0 end as iDistance

from blobdata b, date_data d,_Hght 
where d.id = b.id
and b.b1 <> 126
order by b.id, pos
) a
, _PersonParams;

.output extract_raw_summary.csv

select time
,sum(Steps) as Steps
,sum(Runs) as Runs
,round(sum(iDistance)) as WalkDistance
,round(sum(case when runs>0 then (3+runs*2) * iDistance / 15 else 0 end)) as RunDistance
,round(sum(weight *2.2046 *  iDistance * (select coalesce(max(Cal),0.95)/coalesce(max(Dist),40.233) from _CalList where Dist <= iDistance) / 60)) as WalkCalories
,round(sum(case when runs> 0 then (3+runs*2.0) /15 * weight *2.2046 *  iDistance * (select coalesce(max(Cal),0.95)/coalesce(max(Dist),40.233) from _CalList where Dist <= iDistance) / 60 else 0 end)) as RunCalories

 from 
 (select d.date as time
,case when b1 in (4,5) then 'Sleep' when b1 > 15 and b3 > 0 then 'Run' when b1 > 0 and b3 > 0 then 'Walk' else 'Idle' end as Description
,case when b1 not in (4,5) then b3 else 0 end as Steps
,b1 as RawActivity,b2 as RawSensorData
,case when b3 > 0 then (b1 >> 4) else 0 end as Runs
--,case when b3 > 0 then (b1 & 0xf) else 0 end as mode
,case when b3> 0 and b1 not in (4,5) then case when b3 <= 90 then b3*h1*0.9 else b3*b3*h1/(case when b3 > 120 then 125 else 100 end) end else 0 end as iDistance

from blobdata b, date_data d,_Hght 
where d.id = b.id
and b.b1 <> 126
and b3 > 0
and (b1 & 0xf) <> 6
and (b1 & 0xf) <= 7
and (b1 & 0xf) > 0
and b1 not in (4,5)
) a, _PersonParams
group by time;
