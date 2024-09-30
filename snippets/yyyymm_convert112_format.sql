
convert(char(6), cov_month, 112) as FundMth  
select to_varchar('2022-10-01'::date,'YYYYMM') as FundMth;




FORMAT(A.COVERAGE_MONTH,'yyyyMM')
-- coverate_month is date type
to_varchar(COVERAGE_MONTH,'YYYYMM')




