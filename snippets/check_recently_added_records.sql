select * from finance_protected.CCS_triangle_utilization 
where update_ts < dateadd(minute,-5,current_timestamp()) ;
