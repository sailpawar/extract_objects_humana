
--use this in sql server


-- Modify 4 places with same values of tables (without db and schema)



BEGIN
DECLARE @objectname VARCHAR(MAX)
declare @delimiter nvarchar(2)=char(10);
DECLARE mycursor CURSOR FOR 
SELECT  OBJECT_SCHEMA_NAME(p.object_id) +'.'+o.name 
FROM sys.sql_modules p inner join sys.sysobjects o on o.id=p.object_id
WHERE (p.[definition] like '%risk%' or p.[definition] like '%risk%')  order by OBJECT_SCHEMA_NAME(p.object_id) ,o.name
OPEN mycursor
FETCH NEXT FROM mycursor INTO @objectname
WHILE @@FETCH_STATUS=0
BEGIN
print @objectname
print '=========================================='
;with CTE as (
	select 
	0 as linenr
	,OBJECT_DEFINITION(OBJECT_ID(@objectname)) as def
	,convert(nvarchar(max),N'') as line
	union all
	select 
	linenr + 1
	,substring(def,charindex(@delimiter,def)+len(@delimiter),len(def)-(charindex(@delimiter,def)))
	,left(def,charindex(@delimiter,def)) as line
	from CTE
	where charindex(@delimiter,def)<>0
	)
	select line
	from CTE
	where linenr >= 1
	and (line like '%risk%' or line like '%risk%')
	OPTION (MAXRECURSION 0);

FETCH NEXT FROM mycursor INTO @objectname
END
CLOSE mycursor
DEALLOCATE mycursor
END
