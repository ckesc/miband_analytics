--Sample time correction table
--Use YYYY-MM-DD format for dates
--FromDt on each subsequent line should match ToDt from previous line
--Do not overlap time intervals or you will get multiple copies of data!
INSERT INTO _TimeOffset (FromDt,ToDt,Offset) VALUES ( '1970-03-13', '1970-11-06','+2 hour');
INSERT INTO _TimeOffset (FromDt,ToDt,Offset) VALUES ( '1970-11-06', '1971-03-13','+1 hour');
INSERT INTO _TimeOffset (FromDt,ToDt,Offset) VALUES ( '1971-03-13', '1971-11-06','+2 hour');
INSERT INTO _TimeOffset (FromDt,ToDt,Offset) VALUES ( '1971-11-06', '2099-01-01','+0 hour');
