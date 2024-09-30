

-- column Cov_Month is varchar and has below values in table ifm.STG_CLM_TRIANGLE_Test_POT_With_Count

2023-05-01 00:00:00.000
Sep  1 2022 12:00AM
Oct  1 2016 12:00AM
Aug  1 2015 12:00AM
2019-02-01
2017-09-01
Feb  1 2024 12:00AM
Apr  1 2024 12:00AM

-----------------------------------------------------------------
-- solution

SELECT         distinct Cov_Month,
case
            when try_to_timestamp(cov_month) is not null then to_timestamp(cov_month)
            when try_to_timestamp(cov_month, 'yyyy-mm-dd hh24:mi:ss.ff') is not null then to_timestamp(cov_month, 'yyyy-mm-dd hh24:mi:ss.ff')
            when try_to_timestamp(cov_month, 'mon dd yyyy hh12:miam') is not null then to_timestamp(cov_month, 'mon dd yyyy hh12:miam')
            else null
        end
        FROM            ifm.STG_CLM_TRIANGLE_Test_POT_With_Count;
