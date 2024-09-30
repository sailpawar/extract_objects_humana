


select 'select ' 
+ ''''+TABLE_CATALOG+'''' + ' as ' + ''''+'DB'+''''+', '
+ ''''+TABLE_SCHEMA+'''' + ' as ' + ''''+'SCHEMA'+''''+', '
+ ''''+TABLE_NAME+'''' + ' as ' + ''''+'TABLE_NAME'+''''+', '
+ ''''+cast(ORDINAL_POSITION as varchar)+'''' + ' as ' + ''''+'ORDINAL_POSITION'+''''+', '
+ ''''+IS_NULLABLE+'''' + ' as ' + ''''+'IS_NULLABLE'+''''+', '
+ ''''+DATA_TYPE+'''' + ' as ' + ''''+'DATA_TYPE'+''''+', '
+ ''''+COLUMN_NAME+'''' + ' as ' + ''''+'COLUMN_NAME'+''''+', '
+ ''''+cast(CHARACTER_MAXIMUM_LENGTH as varchar)+'''' + ' as ' + ''''+'sql_server_assigned_length'+''''+', '
+ 'MAX(LEN([' + COLUMN_NAME  + ']))' + ' as ' + ''''+'MAXLEN'+''''+
+ 'from ' + TABLE_SCHEMA + '.' + TABLE_NAME + ' union all '
FROM
information_schema.COLUMNS 
where data_type in ('char','nvarchar','varchar','text', 'nchar')  
And table_name = 'PROVIDERMARGIN_PRIMEWEST';



---------------------------------------------------------

with cte as(


select 'CDO_FINANCE' as 'DB', 'IFM' as 'SCHEMA', 'PROVIDERMARGIN_PRIMEWEST' as 'TABLE_NAME', '1' as 'ORDINAL_POSITION', 'YES' as 'IS_NULLABLE', 'varchar' as 'DATA_TYPE', 'PROVIDER_ID' as 'COLUMN_NAME', '50' as 'sql_server_assigned_length', MAX(LEN([PROVIDER_ID])) as 'MAXLEN'from IFM.PROVIDERMARGIN_PRIMEWEST union all 
select 'CDO_FINANCE' as 'DB', 'IFM' as 'SCHEMA', 'PROVIDERMARGIN_PRIMEWEST' as 'TABLE_NAME', '4' as 'ORDINAL_POSITION', 'YES' as 'IS_NULLABLE', 'varchar' as 'DATA_TYPE', 'Insurance_Company' as 'COLUMN_NAME', '50' as 'sql_server_assigned_length', MAX(LEN([Insurance_Company])) as 'MAXLEN'from IFM.PROVIDERMARGIN_PRIMEWEST union all 
select 'CDO_FINANCE' as 'DB', 'IFM' as 'SCHEMA', 'PROVIDERMARGIN_PRIMEWEST' as 'TABLE_NAME', '5' as 'ORDINAL_POSITION', 'YES' as 'IS_NULLABLE', 'varchar' as 'DATA_TYPE', 'Facility_Name' as 'COLUMN_NAME', '50' as 'sql_server_assigned_length', MAX(LEN([Facility_Name])) as 'MAXLEN'from IFM.PROVIDERMARGIN_PRIMEWEST union all 
select 'CDO_FINANCE' as 'DB', 'IFM' as 'SCHEMA', 'PROVIDERMARGIN_PRIMEWEST' as 'TABLE_NAME', '6' as 'ORDINAL_POSITION', 'YES' as 'IS_NULLABLE', 'varchar' as 'DATA_TYPE', 'PCP_ID' as 'COLUMN_NAME', '50' as 'sql_server_assigned_length', MAX(LEN([PCP_ID])) as 'MAXLEN'from IFM.PROVIDERMARGIN_PRIMEWEST union all 
select 'CDO_FINANCE' as 'DB', 'IFM' as 'SCHEMA', 'PROVIDERMARGIN_PRIMEWEST' as 'TABLE_NAME', '7' as 'ORDINAL_POSITION', 'YES' as 'IS_NULLABLE', 'varchar' as 'DATA_TYPE', 'DESCRIPTION' as 'COLUMN_NAME', '50' as 'sql_server_assigned_length', MAX(LEN([DESCRIPTION])) as 'MAXLEN'from IFM.PROVIDERMARGIN_PRIMEWEST union all 
select 'CDO_FINANCE' as 'DB', 'IFM' as 'SCHEMA', 'PROVIDERMARGIN_PRIMEWEST' as 'TABLE_NAME', '9' as 'ORDINAL_POSITION', 'YES' as 'IS_NULLABLE', 'varchar' as 'DATA_TYPE', 'COMPANY' as 'COLUMN_NAME', '50' as 'sql_server_assigned_length', MAX(LEN([COMPANY])) as 'MAXLEN'from IFM.PROVIDERMARGIN_PRIMEWEST union all 
select 'CDO_FINANCE' as 'DB', 'IFM' as 'SCHEMA', 'PROVIDERMARGIN_PRIMEWEST' as 'TABLE_NAME', '10' as 'ORDINAL_POSITION', 'YES' as 'IS_NULLABLE', 'varchar' as 'DATA_TYPE', 'PRODUCT' as 'COLUMN_NAME', '50' as 'sql_server_assigned_length', MAX(LEN([PRODUCT])) as 'MAXLEN'from IFM.PROVIDERMARGIN_PRIMEWEST union all 
select 'CDO_FINANCE' as 'DB', 'IFM' as 'SCHEMA', 'PROVIDERMARGIN_PRIMEWEST' as 'TABLE_NAME', '11' as 'ORDINAL_POSITION', 'YES' as 'IS_NULLABLE', 'varchar' as 'DATA_TYPE', 'TAXONOMY' as 'COLUMN_NAME', '50' as 'sql_server_assigned_length', MAX(LEN([TAXONOMY])) as 'MAXLEN'from IFM.PROVIDERMARGIN_PRIMEWEST union all 
select 'CDO_FINANCE' as 'DB', 'IFM' as 'SCHEMA', 'PROVIDERMARGIN_PRIMEWEST' as 'TABLE_NAME', '12' as 'ORDINAL_POSITION', 'YES' as 'IS_NULLABLE', 'varchar' as 'DATA_TYPE', 'GROUPER_ID' as 'COLUMN_NAME', '100' as 'sql_server_assigned_length', MAX(LEN([GROUPER_ID])) as 'MAXLEN'from IFM.PROVIDERMARGIN_PRIMEWEST


),
final as (select 
*,

CASE WHEN MAXLEN BETWEEN 0 and 10 THEN 25 
WHEN MAXLEN BETWEEN 11 and 40 THEN 50 
WHEN MAXLEN BETWEEN 41 and 85 THEN 100 
WHEN MAXLEN BETWEEN 86 and 150 THEN 200 
WHEN MAXLEN BETWEEN 151 and 220 THEN 255 
WHEN MAXLEN BETWEEN 221 and 275 THEN 300 
WHEN MAXLEN BETWEEN 276 and 450 THEN 500  
WHEN MAXLEN IS NULL THEN	
	case when sql_server_assigned_length is not null THEN sql_server_assigned_length
	end
ELSE 16777216 
END AS NEW_UNIFORM_LEN 
from cte)

select 
-- *
COLUMN_NAME,NEW_UNIFORM_LEN 
from final
order by COLUMN_NAME;


--------------------------------------


COLUMN_NAME,NEW_UNIFORM_LEN
Company,25
Description,50
Facility_Name,50
GrouperID,25
Insurance_Company,25
Market,255
PCP_ID,50
Product,25
Risk,10
Risk_Type,255
SF_PCP_Nname,50
Taxonomy,50