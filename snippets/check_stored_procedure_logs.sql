select * from ifm.ifm_StoredProcedure_Log
where last_updt_ts >= dateadd(minute,-10,current_timestamp());