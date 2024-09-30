DATEADD(DAY, 1, EOMONTH(Activity_Date, -1))

Activity_Date = '"02/23/23 00:00:00"'



-- sf_eq
 select date_trunc('month',to_timestamp(trim('"11/09/21 00:00:00"','"'),'MM/DD/YY HH24:MI:SS')) as cov_month
-- trim as input was from json and it was having double quotes around date value 
------------------------------------------------------------------------------------------------------------