
SELECT DATEADD(mm, DATEDIFF(mm, 0, '1970-08-23'), 0) AS Paid_Month;



  select to_timestamp_ntz(date_trunc(mm,'1970-08-23'::date));
