USE [TranscendAnalytics]
GO
/****** Object:  StoredProcedure [dbo].[ifm_SF_CW_United_PIPC_NC]    Script Date: 6/6/2024 12:48:21 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ifm_SF_CW_United_PIPC_NC] 
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


--FEED				FILE				DDS_DATA_fEED_ID
--UHC-NC-CLAIMS		CENTERWELL_CLAIMS	 1583
--UHC-NC-REVENUE	CENTERWELL_REVENUE	 1584
--UHC-NC-RX		    CENTERWELL_RX		 1585	
--UHC-NC-STOP-LOSS  CENTERWELL_STOP_LOSS 1586



----Reminder
--print 'Do not forget to update dbo.uhc_PIPC_NC_PMPM table!'
print 'If you forgot to update PMPMs, go in, update, and re-run. DO NOT FORGET'

declare @AdvPmt23 as float 
declare @HomeAssmt23 as float 
declare @AdvPmt24 as float 
declare @HomeAssmt24 as float 
--declare @AdvPmt25 as float 
--declare @HomeAssmt25 as float 

/************************************************* User Input ****/ 
set @HomeAssmt23 =		14.34
set @AdvPmt23 =			14.12 

set @HomeAssmt24 =		36.87
set @AdvPmt24 =			39.09

--set @AdvPmt25 = 14.54
--set @HomeAssmt25 = 20.26
/************************************************ End User Input ****/ 
--select @AdvPmt23, @HomeAssmt23 
--select @AdvPmt24, @HomeAssmt24 
drop table if exists #tmpPMPM;
select '2023' as CovYear, @AdvPmt23 AdvPmt, @HomeAssmt23 HomeAssmt into #tmpPMPM
union all 
select '2024' as CovYear, @AdvPmt24 AdvPmt, @HomeAssmt24 HomeAssmt
--union all 
--select '2025' as CovYear, @AdvPmt24 AdvPmt, @HomeAssmt24 HomeAssmt
-- select * from #tmpPMPM


/** Below logic was inserted to pull max event ID per coverage year. United sends a file per coverage year and we only need to pull the last file for each year **/

-- inventory all events for feed ID 
DROP TABLE IF EXISTS #events;
    SELECT tb_dfe.DDS_Data_Feed_Event_Id
        ,convert(DATE, tb_dfe.Event_Src_Date) AS Event_Src_Date
    INTO #events
    FROM PHM_DDS.DDS.DDS_Data_Feed_Event tb_dfe
    WHERE tb_dfe.DDS_Data_Feed_Id = 1584
        AND tb_dfe.DDS_Data_Feed_Event_Status = 3
		and Event_Src_Date > '2024-05-01';
--select * from #events

-- grab all events for related cov year 
drop table if exists #temp_1584_maxCovMth;
create table #temp_1584_maxCovMth
([REVENUE_YEAR] VARCHAR(250), [REVENUE_MONTH] VARCHAR(250),  DDS_Data_Feed_Event_Id varchar(250), Event_Src_Date date) 

DECLARE @event_id INT, @src_date DATE;
WHILE (SELECT count(*) FROM #events ) > 0

BEGIN
	SELECT TOP 1 @event_id = DDS_Data_Feed_Event_Id
		--SELECT TOP 1 @event_id = 41876
		,@src_date = Event_Src_Date
	FROM #events order by DDS_Data_Feed_Event_Id asc;

insert into #temp_1584_maxCovMth 
SELECT distinct 
J.[REVENUE_YEAR], J.[REVENUE_MONTH],  d.DDS_Data_Feed_Event_Id, d.Event_Src_Date 
from 
[PHM_DDS].[DDS].DDS_Data D with (NOLOCK)
 CROSS APPLY OPENJSON(D.Json) WITH(
[REVENUE_YEAR] VARCHAR(250),
[REVENUE_MONTH] VARCHAR(250)
) AS J 

WHERE DDS_DATA_FEED_EVENT_Id = @event_id
		AND Event_Src_Date = @src_date;

	DELETE #events WHERE DDS_Data_Feed_Event_Id = @event_id
END;

-- keep max event per year 
drop table if exists #temp_1584_YrEvents; 
select distinct  a.*, b.Event_Src_Date
into #temp_1584_YrEvents 
from (
select REVENUE_YEAR, max(dds_data_feed_event_id) max_event  
from #temp_1584_maxCovMth a 
group by REVENUE_YEAR
	 ) a 
inner join #temp_1584_maxCovMth b on a.max_event  = b.DDS_Data_Feed_Event_Id
where a.REVENUE_YEAR > 2022;

-- run loop for JSON to pull each max event per cov year 

--select @event_idREV, @src_dateREV
--Revenue--UHC-KC-REVENUE	CENTERWELL_REVENUE	1584
Drop table if exists #UNC_PIPC_NC_REV_01;

create table #UNC_PIPC_NC_REV_01
([PAYMENT_DATE] VARCHAR(250),
[REVENUE_YEAR] VARCHAR(250),
[REVENUE_MONTH] VARCHAR(250),
[NETWORK] VARCHAR(250),
[NETWORK_NAME] VARCHAR(250),
[PCP] VARCHAR(250),
[PCP_NAME] VARCHAR(250),
[GROUP] VARCHAR(250),
[MEMBER_ALT_ID] VARCHAR(250),
[AGE] VARCHAR(250),
[GENDER] VARCHAR(250),
[MEMBER_NAME] VARCHAR(250),
[APPLY_DATE] VARCHAR(250),
[GROSS_REVENUE] VARCHAR(250),
[RISK_ADJUSTER_FACTOR_A] VARCHAR(250),
[MEMBER_FIRST_NAME] VARCHAR(250),
[MEMBER_LAST_NAME] VARCHAR(250),
[ADJUSTMENT_REASON_CODE] VARCHAR(250),
[COUNTY] VARCHAR(250),
[DATE_OF_BIRTH] VARCHAR(250),
[MBI] VARCHAR(250),
[DIV] VARCHAR(250),
[Contract_nbr] VARCHAR(250),
[PBP] VARCHAR(250),
[Segment_Nbr] VARCHAR(250),
[SCC] VARCHAR(250),
[CMS_State] VARCHAR(250),
[PCP_TIN] VARCHAR(250),
[PCP_Spec_cd] VARCHAR(250),
[PCP_Spec_cd_desc] VARCHAR(250),
[Default_Risk_Adj_flg] VARCHAR(250),
[Esrd_Mbr_Msp_Flg] VARCHAR(250),
[ESRD_Flg] VARCHAR(250),
[Mcaid_Status_Flg] VARCHAR(250),
[Risk_Adj_Factor_Typ_Cd] VARCHAR(250),
[Risk_Adj_Factor_Typ_Cd_Desc] VARCHAR(250),
[Frailty_Flg] VARCHAR(250),
[Orig_Rsn_For_Entitlement] VARCHAR(250),
[Employer_Group_Flg] VARCHAR(250),
[Part_C_Frailty_Score_Fctr] VARCHAR(250),
[Working_Aged_Flg] VARCHAR(250),
[LTI] VARCHAR(250),
[Institutional_Flg] VARCHAR(250),
[Hospice_Flg] VARCHAR(250),
[iteration] VARCHAR(250),
DDS_Data_Feed_Event_Id VARCHAR(250), Event_Src_Date date) 


DECLARE @event_idREV INT, @src_dateREV DATE;
WHILE (SELECT count(*) FROM #temp_1584_YrEvents ) > 0

BEGIN
	SELECT TOP 1 @event_idREV = max_event
		,@src_dateREV = Event_Src_Date
	FROM #temp_1584_YrEvents order by max_event asc;

insert into #UNC_PIPC_NC_REV_01
SELECT 
J.* , DDS_Data_Feed_Event_Id, Event_Src_Date 
--into #UNC_PIPC_NC_REV_01
FROM [PHM_DDS].[DDS].DDS_Data D with (NOLOCK)
 CROSS APPLY OPENJSON(D.Json) WITH(
[PAYMENT_DATE] VARCHAR(250),
[REVENUE_YEAR] VARCHAR(250),
[REVENUE_MONTH] VARCHAR(250),
[NETWORK] VARCHAR(250),
[NETWORK_NAME] VARCHAR(250),
[PCP] VARCHAR(250),
[PCP_NAME] VARCHAR(250),
[GROUP] VARCHAR(250),
[MEMBER_ALT_ID] VARCHAR(250),
[AGE] VARCHAR(250),
[GENDER] VARCHAR(250),
[MEMBER_NAME] VARCHAR(250),
[APPLY_DATE] VARCHAR(250),
[GROSS_REVENUE] VARCHAR(250),
[RISK_ADJUSTER_FACTOR_A] VARCHAR(250),
[MEMBER_FIRST_NAME] VARCHAR(250),
[MEMBER_LAST_NAME] VARCHAR(250),
[ADJUSTMENT_REASON_CODE] VARCHAR(250),
[COUNTY] VARCHAR(250),
[DATE_OF_BIRTH] VARCHAR(250),
[MBI] VARCHAR(250),
[DIV] VARCHAR(250),
[Contract_nbr] VARCHAR(250),
[PBP] VARCHAR(250),
[Segment_Nbr] VARCHAR(250),
[SCC] VARCHAR(250),
[CMS_State] VARCHAR(250),
[PCP_TIN] VARCHAR(250),
[PCP_Spec_cd] VARCHAR(250),
[PCP_Spec_cd_desc] VARCHAR(250),
[Default_Risk_Adj_flg] VARCHAR(250),
[Esrd_Mbr_Msp_Flg] VARCHAR(250),
[ESRD_Flg] VARCHAR(250),
[Mcaid_Status_Flg] VARCHAR(250),
[Risk_Adj_Factor_Typ_Cd] VARCHAR(250),
[Risk_Adj_Factor_Typ_Cd_Desc] VARCHAR(250),
[Frailty_Flg] VARCHAR(250),
[Orig_Rsn_For_Entitlement] VARCHAR(250),
[Employer_Group_Flg] VARCHAR(250),
[Part_C_Frailty_Score_Fctr] VARCHAR(250),
[Working_Aged_Flg] VARCHAR(250),
[LTI] VARCHAR(250),
[Institutional_Flg] VARCHAR(250),
[Hospice_Flg] VARCHAR(250),
[iteration] VARCHAR(250)) AS J 
--WHERE (
--(DDS_Data_Feed_Event_Id= (select max(DDS_Data_Feed_Event_Id) from PHM_DDS.DDS.DDS_Data_Feed_Event where DDS_Data_Feed_Id = '1584' and DDS_Data_Feed_Event_Status = '3')
--AND Event_Src_Date= (select max(Event_Src_Date) from PHM_DDS.DDS.DDS_Data_Feed_Event where DDS_Data_Feed_Id = '1584' and DDS_Data_Feed_Event_Status = '3')
--) 
--or 
--(DDS_Data_Feed_Event_Id = 37348) 
--)

WHERE DDS_DATA_FEED_EVENT_Id = @event_idREV
		AND Event_Src_Date = @src_dateREV;

	DELETE #temp_1584_YrEvents WHERE max_event = @event_idREV
END
;

--select * from #UNC_PIPC_NC_REV_01
--select DDS_Data_Feed_Event_Id, count(*) from #UNC_PIPC_NC_REV_01 group by DDS_Data_Feed_Event_Id

--OPTION (MAXDOP 3);
--WHERE DDS_Data_Feed_Event_Id=68687
--AND Event_Src_Date= '2022/11/30'
--OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'));


--select * from #UNC_PIPC_NC_REV_01 where member_name = 'GREGORY WADE' and revenue_month = '6';


-------------------------------------
--Insert Revenue Data

--truncate table [TranscendAnalytics].[CDO].[ServiceFund_IFM_CW];

--select * from [TranscendAnalytics].[CDO].[ServiceFund_IFM_CW_All]

Declare @Close_Month as date

set @Close_Month = (select dateadd(month,1,max(cast([PAYMENT_DATE]+'01' as date))) from #UNC_PIPC_NC_REV_01)

--select cast(revenue_year+iif(len(revenue_month)=2,revenue_month,'0'+revenue_month)+'01' as date) from #UNC_PIPC_NC_REV_01
--select distinct  cast([PAYMENT_DATE]+'01' as date) from #UNC_PIPC_NC_REV_01 order by cast([PAYMENT_DATE]+'01' as date)

drop table if exists #UNC_PIPC_NC_REV_02

select 
cast(revenue_year+iif(len(revenue_month)=2,revenue_month,'0'+revenue_month)+'01' as date) As Cov_Month,
[MEMBER_ALT_ID] as Subscriber_id,
MBI as medicare_ID,
[MEMBER_NAME] as Member_Name,
'' as NETWORK_NAME,
[PCP] as PCP_ID,
cast(Date_Of_Birth as date) as Birth_Date,
gender,
'' as IPA_ID,
[ESRD_Flg] as ESRD,
Contract_nbr,
PBP,
sum(cast(Gross_Revenue as decimal(12,4))) AS CMSFundingC,
0 AS CMSFundingD,
sum(cast(Gross_Revenue as decimal(12,4)))*.82 AS FPGFundingC
into #UNC_PIPC_NC_REV_02
from #UNC_PIPC_NC_REV_01
group by 
cast(revenue_year+iif(len(revenue_month)=2,revenue_month,'0'+revenue_month)+'01' as date),
[MEMBER_ALT_ID],
MBI,
[MEMBER_NAME],
[PCP],
cast(Date_Of_Birth as date),
gender,
Contract_nbr,
PBP,
[ESRD_Flg]


truncate table TranscendAnalytics.cdo.serviceFund_IFM_CW

insert into TranscendAnalytics.cdo.serviceFund_IFM_CW
(
Cov_Month,
Close_Month,
MemberID,
MemberName,
MCARE_ID,
SFBirthDate,
PCPID,
CMSFundingC,
CMSFundingD,
FPGFundingC,
InsuranceCompany,
IPAName,
ESRD,
Contract,
PBP
)
select
cov_month,
@Close_Month,
subscriber_id,member_name,medicare_id,birth_date, pcp_id, cmsfundingc, cmsfundingd, FPGFundingC, 'United', IPA_ID, ESRD,
Contract_nbr,
PBP
from #UNC_PIPC_NC_REV_02

--Update ESRD
drop table if exists #United_PIPC_NC_ESRD
select 
cast(revenue_year+iif(len(revenue_month)=2,revenue_month,'0'+revenue_month)+'01' as date) As Cov_Month,
[MEMBER_ALT_ID] as Subscriber_id,
Esrd_flg
into #United_PIPC_NC_ESRD
from #UNC_PIPC_NC_REV_01
where esrd_flg = 'Y'
group by 
cast(revenue_year+iif(len(revenue_month)=2,revenue_month,'0'+revenue_month)+'01' as date),
[MEMBER_ALT_ID],
Esrd_flg

update a
set a.ESRD = e.esrd_flg
from TranscendAnalytics.cdo.serviceFund_IFM_CW a
join #United_PIPC_NC_ESRD e on e.Subscriber_id = a.MemberID
			and e.Cov_Month = a.Cov_Month


-------------------------------------------------------------------------
--UHC-KC-CLAIMS		CENTERWELL_CLAIMS	1583
------------------------------------------------ Claims Loop for Max Year 


-- inventory all events for feed ID 
DROP TABLE IF EXISTS #events1583;
    SELECT tb_dfe.DDS_Data_Feed_Event_Id
        ,convert(DATE, tb_dfe.Event_Src_Date) AS Event_Src_Date
    INTO #events1583
    FROM PHM_DDS.DDS.DDS_Data_Feed_Event tb_dfe
    WHERE tb_dfe.DDS_Data_Feed_Id = 1583
        AND tb_dfe.DDS_Data_Feed_Event_Status = 3
		and Event_Src_Date > '2024-05-01';

--select * from #events1583
-- grab all events for related cov year 
drop table if exists #temp_1583_maxCovMth;
create table #temp_1583_maxCovMth
([BEGIN_DOS] VARCHAR(250), DDS_Data_Feed_Event_Id varchar(250), Event_Src_Date date) 

DECLARE @event_id1583 INT, @src_date1583 DATE;
WHILE (SELECT count(*) FROM #events1583 ) > 0

BEGIN
	SELECT TOP 1 @event_id1583 = DDS_Data_Feed_Event_Id
	--SELECT @event_id1583 = 41874
		,@src_date1583 = Event_Src_Date
	FROM #events1583 order by DDS_Data_Feed_Event_Id asc;

insert into #temp_1583_maxCovMth 
SELECT distinct 
J.[BEGIN_DOS],  d.DDS_Data_Feed_Event_Id, d.Event_Src_Date 
from 
[PHM_DDS].[DDS].DDS_Data D with (NOLOCK)
 CROSS APPLY OPENJSON(D.Json) WITH(
[BEGIN_DOS] VARCHAR(250)
) AS J 
--where year([BEGIN_DOS]) > 2022
WHERE DDS_DATA_FEED_EVENT_Id = @event_id1583
		AND Event_Src_Date = @src_date1583;

	DELETE #events1583 WHERE DDS_Data_Feed_Event_Id = @event_id1583
END;

-- keep max event per year 
drop table if exists #temp_1583_YrEvents; 
select distinct  a.[BEGIN_DOS], a.max_event, b.Event_Src_Date
into #temp_1583_YrEvents 
from (
select year([BEGIN_DOS]) [BEGIN_DOS], max(dds_data_feed_event_id) max_event  
from #temp_1583_maxCovMth 
group by year([BEGIN_DOS])
	 ) a 
inner join #temp_1583_maxCovMth b on a.max_event  = b.DDS_Data_Feed_Event_Id
where a.[BEGIN_DOS] > 2022

--select * from #temp_1583_YrEvents
----select distinct year(begin_dos), DDS_Data_Feed_Event_Id from #temp_1583_maxCovMth order by 1
--select  year(begin_dos), max(DDS_Data_Feed_Event_Id) maxEvent from #temp_1583_maxCovMth group by year(begin_dos) order by 1 

SELECT max(DDS_Data_Feed_Event_Id) from #temp_1583_maxCovMth

drop table if exists #UNC_PIPC_NC_Claims_01;
create table #UNC_PIPC_NC_Claims_01 
([NETWORK_NO] VARCHAR(250),
[NETWORK_NAME] VARCHAR(250),
[PCP_NO] VARCHAR(250),
[PCP_NAME] VARCHAR(250),
[MEMBER_GROUP] VARCHAR(250),
[MEMBER_ALT_ID] VARCHAR(250),
[MEMBER_LAST_NAME] VARCHAR(250),
[MEMBER_FIRST_NAME] VARCHAR(250),
[MEMBER_MI] VARCHAR(250),
[PROVIDER_NO] VARCHAR(250),
[PROVIDER_NAME] VARCHAR(250),
[REFERRAL_PROV_NO_FACILITY_CODE] VARCHAR(250),
[POOL] VARCHAR(250),
[CC_CODE] VARCHAR(250),
[SITE_CODE] VARCHAR(250),
[AUDIT_NO] VARCHAR(250),
[AUDIT_SUB] VARCHAR(250),
[CPT_REVENUE_CODE] VARCHAR(250),
[PROCEDURE_CODE] VARCHAR(250),
[DESCRIPTION_OF_SERVICE] VARCHAR(250),
[PROCEDURE_MOD_CODE_1] VARCHAR(250),
[PROCEDURE_MOD_DESCRIPTION_1] VARCHAR(250),
[PROCEDURE_MOD_CODE_2] VARCHAR(250),
[PROCEDURE_MOD_DESCRIPTION_2] VARCHAR(250),
[DENIAL_REASON_CODE] VARCHAR(250),
[CAP_FLAG] VARCHAR(250),
[BEGIN_DOS] VARCHAR(250),
[END_DOS] VARCHAR(250),
[PAID_DATE] VARCHAR(250),
[CLAIMED_AMOUNT] VARCHAR(250),
[PAID_AMOUNT] VARCHAR(250),
[PCR_AMOUNT] VARCHAR(250),
[PRIMARY_DIAGNOSIS_CODE] VARCHAR(250),
[PRIMARY_DIAGNOSIS_DESCRIPTION] VARCHAR(250),
[DIAGNOSIS_CODE_2] VARCHAR(250),
[DIAGNOSIS_2_DESCRIPTION] VARCHAR(250),
[DIAGNOSIS_CODE_3] VARCHAR(250),
[DIAGNOSIS_3_DESCRIPTION] VARCHAR(250),
[DIAGNOSIS_CODE_4] VARCHAR(250),
[DIAGNOSIS_4_DESCRIPTION] VARCHAR(250),
[RECEIVED_DATE] VARCHAR(250),
[RECORD_ID] VARCHAR(250),
[GENDER] VARCHAR(250),
[PAR_STATUS] VARCHAR(250),
[MEMBER_AGE] VARCHAR(250),
[AUTHORIZATION_NUMBER] VARCHAR(250),
[NUMBER_OF_UNITS] VARCHAR(250),
[DISCHARGE_STATUS] VARCHAR(250),
[CLINIC_NAME] VARCHAR(250),
[CY_PY] VARCHAR(250),
[CLMO] VARCHAR(250),
[CLAIM_LOCATION_CODE] VARCHAR(250),
[Srvc_Provider_NPI_Number] VARCHAR(250),
[DATE_OF_BIRTH] VARCHAR(250),
[DRG] VARCHAR(250),
[DETAIL_LINE_NO] VARCHAR(250),
[DIAGNOSIS_CODE_5] VARCHAR(250),
[DIAGNOSIS_CODE_6] VARCHAR(250),
[DIAGNOSIS_CODE_7] VARCHAR(250),
[DIAGNOSIS_CODE_8] VARCHAR(250),
[DIAGNOSIS_CODE_9] VARCHAR(250),
[DIAGNOSIS_CODE_10] VARCHAR(250),
[DIAGNOSIS_CODE_11] VARCHAR(250),
[DIAGNOSIS_CODE_12] VARCHAR(250),
[DIAGNOSIS_CODE_13] VARCHAR(250),
[DIAGNOSIS_CODE_14] VARCHAR(250),
[DIAGNOSIS_CODE_15] VARCHAR(250),
[DIAGNOSIS_CODE_16] VARCHAR(250),
[DIAGNOSIS_CODE_17] VARCHAR(250),
[DIAGNOSIS_CODE_18] VARCHAR(250),
[DIAGNOSIS_CODE_19] VARCHAR(250),
[DIAGNOSIS_CODE_20] VARCHAR(250),
[DIAGNOSIS_CODE_21] VARCHAR(250),
[DIAGNOSIS_CODE_22] VARCHAR(250),
[DIAGNOSIS_CODE_23] VARCHAR(250),
[DIAGNOSIS_CODE_24] VARCHAR(250),
[DIAGNOSIS_CODE_25] VARCHAR(250),
[BILL_TYPE_CODE] VARCHAR(250),
[MBI] VARCHAR(250),
[DIV] VARCHAR(250),
[Contract_nbr] VARCHAR(250),
[PBP] VARCHAR(250),
[Segment_Nbr] VARCHAR(250),
[iteration] VARCHAR(250),
DDS_Data_Feed_Event_Id VARCHAR(250), Event_Src_Date date) 

DECLARE @event_idCLM INT, @src_dateCLM DATE;
WHILE (SELECT count(*) FROM #temp_1583_YrEvents ) > 0

BEGIN
	SELECT TOP 1 @event_idCLM = max_event
		,@src_dateCLM = Event_Src_Date
	FROM #temp_1583_YrEvents order by max_event asc;

insert into #UNC_PIPC_NC_Claims_01
--drop table if exists #UNC_PIPC_NC_Claims_01;
SELECT
J.*, DDS_Data_Feed_Event_Id, Event_Src_Date 
--into #UNC_PIPC_NC_Claims_01
FROM [PHM_DDS].[DDS].DDS_Data D with (NOLOCK)
 CROSS APPLY OPENJSON(D.Json) WITH(
[NETWORK_NO] VARCHAR(250),
[NETWORK_NAME] VARCHAR(250),
[PCP_NO] VARCHAR(250),
[PCP_NAME] VARCHAR(250),
[MEMBER_GROUP] VARCHAR(250),
[MEMBER_ALT_ID] VARCHAR(250),
[MEMBER_LAST_NAME] VARCHAR(250),
[MEMBER_FIRST_NAME] VARCHAR(250),
[MEMBER_MI] VARCHAR(250),
[PROVIDER_NO] VARCHAR(250),
[PROVIDER_NAME] VARCHAR(250),
[REFERRAL_PROV_NO_FACILITY_CODE] VARCHAR(250),
[POOL] VARCHAR(250),
[CC_CODE] VARCHAR(250),
[SITE_CODE] VARCHAR(250),
[AUDIT_NO] VARCHAR(250),
[AUDIT_SUB] VARCHAR(250),
[CPT_REVENUE_CODE] VARCHAR(250),
[PROCEDURE_CODE] VARCHAR(250),
[DESCRIPTION_OF_SERVICE] VARCHAR(250),
[PROCEDURE_MOD_CODE_1] VARCHAR(250),
[PROCEDURE_MOD_DESCRIPTION_1] VARCHAR(250),
[PROCEDURE_MOD_CODE_2] VARCHAR(250),
[PROCEDURE_MOD_DESCRIPTION_2] VARCHAR(250),
[DENIAL_REASON_CODE] VARCHAR(250),
[CAP_FLAG] VARCHAR(250),
[BEGIN_DOS] VARCHAR(250),
[END_DOS] VARCHAR(250),
[PAID_DATE] VARCHAR(250),
[CLAIMED_AMOUNT] VARCHAR(250),
[PAID_AMOUNT] VARCHAR(250),
[PCR_AMOUNT] VARCHAR(250),
[PRIMARY_DIAGNOSIS_CODE] VARCHAR(250),
[PRIMARY_DIAGNOSIS_DESCRIPTION] VARCHAR(250),
[DIAGNOSIS_CODE_2] VARCHAR(250),
[DIAGNOSIS_2_DESCRIPTION] VARCHAR(250),
[DIAGNOSIS_CODE_3] VARCHAR(250),
[DIAGNOSIS_3_DESCRIPTION] VARCHAR(250),
[DIAGNOSIS_CODE_4] VARCHAR(250),
[DIAGNOSIS_4_DESCRIPTION] VARCHAR(250),
[RECEIVED_DATE] VARCHAR(250),
[RECORD_ID] VARCHAR(250),
[GENDER] VARCHAR(250),
[PAR_STATUS] VARCHAR(250),
[MEMBER_AGE] VARCHAR(250),
[AUTHORIZATION_NUMBER] VARCHAR(250),
[NUMBER_OF_UNITS] VARCHAR(250),
[DISCHARGE_STATUS] VARCHAR(250),
[CLINIC_NAME] VARCHAR(250),
[CY_PY] VARCHAR(250),
[CLMO] VARCHAR(250),
[CLAIM_LOCATION_CODE] VARCHAR(250),
[Srvc_Provider_NPI_Number] VARCHAR(250),
[DATE_OF_BIRTH] VARCHAR(250),
[DRG] VARCHAR(250),
[DETAIL_LINE_NO] VARCHAR(250),
[DIAGNOSIS_CODE_5] VARCHAR(250),
[DIAGNOSIS_CODE_6] VARCHAR(250),
[DIAGNOSIS_CODE_7] VARCHAR(250),
[DIAGNOSIS_CODE_8] VARCHAR(250),
[DIAGNOSIS_CODE_9] VARCHAR(250),
[DIAGNOSIS_CODE_10] VARCHAR(250),
[DIAGNOSIS_CODE_11] VARCHAR(250),
[DIAGNOSIS_CODE_12] VARCHAR(250),
[DIAGNOSIS_CODE_13] VARCHAR(250),
[DIAGNOSIS_CODE_14] VARCHAR(250),
[DIAGNOSIS_CODE_15] VARCHAR(250),
[DIAGNOSIS_CODE_16] VARCHAR(250),
[DIAGNOSIS_CODE_17] VARCHAR(250),
[DIAGNOSIS_CODE_18] VARCHAR(250),
[DIAGNOSIS_CODE_19] VARCHAR(250),
[DIAGNOSIS_CODE_20] VARCHAR(250),
[DIAGNOSIS_CODE_21] VARCHAR(250),
[DIAGNOSIS_CODE_22] VARCHAR(250),
[DIAGNOSIS_CODE_23] VARCHAR(250),
[DIAGNOSIS_CODE_24] VARCHAR(250),
[DIAGNOSIS_CODE_25] VARCHAR(250),
[BILL_TYPE_CODE] VARCHAR(250),
[MBI] VARCHAR(250),
[DIV] VARCHAR(250),
[Contract_nbr] VARCHAR(250),
[PBP] VARCHAR(250),
[Segment_Nbr] VARCHAR(250),
[iteration] VARCHAR(250)) AS J 

WHERE DDS_DATA_FEED_EVENT_Id = @event_idCLM
		AND Event_Src_Date = @src_dateCLM;

	DELETE #temp_1583_YrEvents WHERE max_event = @event_idCLM
END
;


select distinct dds_data_feed_event_id from #UNC_PIPC_NC_Claims_01

--WHERE (
--(DDS_Data_Feed_Event_Id= (select max(DDS_Data_Feed_Event_Id) from PHM_DDS.DDS.DDS_Data_Feed_Event where DDS_Data_Feed_Id = '1583' and DDS_Data_Feed_Event_Status = '3')
--AND Event_Src_Date= (select max(Event_Src_Date) from PHM_DDS.DDS.DDS_Data_Feed_Event where DDS_Data_Feed_Id = '1583' and DDS_Data_Feed_Event_Status = '3')
--) 
--or 
--(DDS_Data_Feed_Event_Id = 37347) 
--)



--OPTION (MAXDOP 3);
--WHERE DDS_Data_Feed_Event_Id=66501
--AND Event_Src_Date= '2022/10/31'
--OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'));

--select  pool, sum(cast([PAID_AMOUNT] as float)) as Amt  from #UNC_PIPC_NC_Claims_01 group by pool
--select * from #UNC_PIPC_NC_Claims_01

drop table if exists #UNC_PIPC_NC_Claims_02;
---Used for Triangles
select [MEMBER_ALT_ID] as MemberID,
dateadd(day, 1,Eomonth(cast([BEGIN_DOS] as date),-1)) as Cov_Month,
sum(cast([PAID_AMOUNT] as float)) as Paid_Amt,
dateadd(day, 1,Eomonth(cast([PAID_DATE]as date),-1)) as Paid_Month,
[POOL]
--,[CLAIM_LOCATION_CODE]
into #UNC_PIPC_NC_Claims_02
from #UNC_PIPC_NC_Claims_01
group by [MEMBER_ALT_ID],
dateadd(day, 1,Eomonth(cast([BEGIN_DOS] as date),-1)),
POOL,
dateadd(day, 1,Eomonth(cast([PAID_DATE]as date),-1))
having sum(cast([PAID_AMOUNT] as float)) <> 0


drop table if exists #UNC_PIPC_NC_Claims_NoPaidMth;

select [MEMBER_ALT_ID] as MemberID,
dateadd(day, 1,Eomonth(cast([BEGIN_DOS] as date),-1)) as Cov_Month,
sum(cast([PAID_AMOUNT] as float)) as Paid_Amt,
[POOL]
--,[CLAIM_LOCATION_CODE]
into #UNC_PIPC_NC_Claims_NoPaidMth
from #UNC_PIPC_NC_Claims_01
group by [MEMBER_ALT_ID],
dateadd(day, 1,Eomonth(cast([BEGIN_DOS] as date),-1)),
POOL
having sum(cast([PAID_AMOUNT] as float)) <> 0

--select cov_month, pool,  sum(cast([PAID_AMT] as float)) from #UNC_PIPC_NC_Claims_02 group by cov_month, pool

update a
set A.ClaimsPartA_IP = E.Paid_Amt
from TranscendAnalytics.cdo.serviceFund_IFM_CW a
join #UNC_PIPC_NC_Claims_NoPaidMth e on e.MemberID = a.MemberID
			and e.Cov_Month = a.Cov_Month
WHERE E.POOL = 'INPATIENT'




update a
set A.ClaimsPartA_OP= E.Paid_Amt
from TranscendAnalytics.cdo.serviceFund_IFM_CW a
join #UNC_PIPC_NC_Claims_NoPaidMth e on e.MemberID = a.MemberID
			and e.Cov_Month = a.Cov_Month
WHERE E.POOL = 'OUTPATIENT'


update a
set A.ClaimsPartB = E.Paid_Amt
from TranscendAnalytics.cdo.serviceFund_IFM_CW a
join #UNC_PIPC_NC_Claims_NoPaidMth e on e.MemberID = a.MemberID
			and e.Cov_Month = a.Cov_Month
WHERE E.POOL = 'PHYSICIAN'

--select distinct pool from #UNC_PIPC_NC_Claims_02 e



-----------------------------------------------------   RX
-- inventory all events for feed ID 
DROP TABLE IF EXISTS #eventsRX;
    SELECT tb_dfe.DDS_Data_Feed_Event_Id
        ,convert(DATE, tb_dfe.Event_Src_Date) AS Event_Src_Date
    INTO #eventsRX
    FROM PHM_DDS.DDS.DDS_Data_Feed_Event tb_dfe
    WHERE tb_dfe.DDS_Data_Feed_Id = 1585
        AND tb_dfe.DDS_Data_Feed_Event_Status = 3
		and Event_Src_Date > '2024-05-01';
--select * from #eventsRX

-- grab all events for related cov year 
drop table if exists #temp_1585_maxCovMth;
create table #temp_1585_maxCovMth
([FILLYMD] VARCHAR(250),  DDS_Data_Feed_Event_Id varchar(250), Event_Src_Date date) -- select * from #temp_1585_maxCovMth

DECLARE @event_id1585 INT, @src_date1585 DATE;
WHILE (SELECT count(*) FROM #eventsRX ) > 0

BEGIN
	SELECT TOP 1 @event_id1585 = DDS_Data_Feed_Event_Id
		--SELECT TOP 1 @event_id1585 = 41878

		,@src_date1585 = Event_Src_Date
	FROM #eventsRX order by DDS_Data_Feed_Event_Id asc;

insert into #temp_1585_maxCovMth 
SELECT distinct 
J.[FILLYMD],  d.DDS_Data_Feed_Event_Id, d.Event_Src_Date 
from 
[PHM_DDS].[DDS].DDS_Data D with (NOLOCK)
 CROSS APPLY OPENJSON(D.Json) WITH(
[FILLYMD] VARCHAR(250) 
) AS J 

WHERE DDS_DATA_FEED_EVENT_Id = @event_id1585
		AND Event_Src_Date = @src_date1585

	DELETE #eventsRX WHERE DDS_Data_Feed_Event_Id = @event_id1585
END;

--select * from #temp_1585_maxCovMth order by 2

-- keep max event per year 
 
drop table if exists #temp_1585_YrEvents; 
select distinct  a.[FILLYMD], a.max_event, b.Event_Src_Date
into #temp_1585_YrEvents 
from (
select year([FILLYMD]) [FILLYMD], max(dds_data_feed_event_id) max_event  
from #temp_1585_maxCovMth 
group by year([FILLYMD])
	 ) a 
inner join #temp_1585_maxCovMth b on a.max_event  = b.DDS_Data_Feed_Event_Id
where a.[FILLYMD] > 2022


--select * from #temp_1585_YrEvents

drop table if exists #UNC_PIPC_NC_RX_01;
create table #UNC_PIPC_NC_RX_01 ( 
[NETWORKNBR] VARCHAR(250),
[NETWORKNAME] VARCHAR(250),
[PCP] VARCHAR(250),
[PCPNAME] VARCHAR(250),
[MEMBERGROUP] VARCHAR(250),
[MEMBER_ALT_ID] VARCHAR(250),
[MEMBERLASTNAME] VARCHAR(250),
[MEMBERFIRSTNAME] VARCHAR(250),
[AGE] VARCHAR(250),
[DRUGNAME] VARCHAR(250),
[GENERIC] VARCHAR(250),
[FORMULARYSTATUS] VARCHAR(250),
[FORMULARYTIER] VARCHAR(250),
[PARTBORD] VARCHAR(250),
[FILLYMD] VARCHAR(250),
[REFILL] VARCHAR(250),
[AUDNBR] VARCHAR(250),
[AMTPAID] VARCHAR(250),
[DAYSSUPP] VARCHAR(250),
[QTYDRUG] VARCHAR(250),
[NDC] VARCHAR(250),
[STDGENERICTHERACLASSDESC] VARCHAR(250),
[STDTHERACLASSDESC] VARCHAR(250),
[STDHIC3DESC] VARCHAR(250),
[DOB] VARCHAR(250),
[PAIDYMD] VARCHAR(250),
[MBI] VARCHAR(250),
[DIV] VARCHAR(250),
[Contract_nbr] VARCHAR(250),
[PBP] VARCHAR(250),
[Segment_Nbr] VARCHAR(250),
[iteration] VARCHAR(250),
DDS_Data_Feed_Event_Id VARCHAR(250), Event_Src_Date date) ;


--UHC-KC-RX			CENTERWELL_RX		1585
--drop table if exists #UNC_PIPC_NC_RX_01;
DECLARE @event_idRX INT, @src_dateRX DATE;
WHILE (SELECT count(*) FROM #temp_1585_YrEvents ) > 0

BEGIN
	SELECT TOP 1 @event_idRX = max_event
		,@src_dateRX = Event_Src_Date
	FROM #temp_1585_YrEvents order by max_event asc;

insert into #UNC_PIPC_NC_RX_01


SELECT  J.*, DDS_Data_Feed_Event_Id, Event_Src_Date 
--into #UNC_PIPC_NC_RX_01
FROM [PHM_DDS].[DDS].DDS_Data D with (NOLOCK)
 CROSS APPLY OPENJSON(D.Json) WITH(
[NETWORKNBR] VARCHAR(250),
[NETWORKNAME] VARCHAR(250),
[PCP] VARCHAR(250),
[PCPNAME] VARCHAR(250),
[MEMBERGROUP] VARCHAR(250),
[MEMBER_ALT_ID] VARCHAR(250),
[MEMBERLASTNAME] VARCHAR(250),
[MEMBERFIRSTNAME] VARCHAR(250),
[AGE] VARCHAR(250),
[DRUGNAME] VARCHAR(250),
[GENERIC] VARCHAR(250),
[FORMULARYSTATUS] VARCHAR(250),
[FORMULARYTIER] VARCHAR(250),
[PARTBORD] VARCHAR(250),
[FILLYMD] VARCHAR(250),
[REFILL] VARCHAR(250),
[AUDNBR] VARCHAR(250),
[AMTPAID] VARCHAR(250),
[DAYSSUPP] VARCHAR(250),
[QTYDRUG] VARCHAR(250),
[NDC] VARCHAR(250),
[STDGENERICTHERACLASSDESC] VARCHAR(250),
[STDTHERACLASSDESC] VARCHAR(250),
[STDHIC3DESC] VARCHAR(250),
[DOB] VARCHAR(250),
[PAIDYMD] VARCHAR(250),
[MBI] VARCHAR(250),
[DIV] VARCHAR(250),
[Contract_nbr] VARCHAR(250),
[PBP] VARCHAR(250),
[Segment_Nbr] VARCHAR(250),
[iteration] VARCHAR(250)) AS J 


WHERE DDS_DATA_FEED_EVENT_Id = @event_idRX
		AND Event_Src_Date = @src_dateRX;

	DELETE #temp_1585_YrEvents WHERE max_event = @event_idRX
END
;

--select top 100 * from #UNC_PIPC_NC_RX_01
--select distinct DDS_DATA_FEED_EVENT_Id from #UNC_PIPC_NC_RX_01 


--WHERE (
--(DDS_Data_Feed_Event_Id= (select max(DDS_Data_Feed_Event_Id) from PHM_DDS.DDS.DDS_Data_Feed_Event where DDS_Data_Feed_Id = '1585' and DDS_Data_Feed_Event_Status = '3')
--AND Event_Src_Date= (select max(Event_Src_Date) from PHM_DDS.DDS.DDS_Data_Feed_Event where DDS_Data_Feed_Id = '1585' and DDS_Data_Feed_Event_Status = '3')
--) 
--or 
--(DDS_Data_Feed_Event_Id = 37349) 
--)
--OPTION (MAXDOP 3);
--WHERE DDS_Data_Feed_Event_Id=68688
--AND Event_Src_Date= '2022/11/30'
--OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'));


--select * from #UNC_PIPC_NC_RX_01

drop table if exists #UNC_PIPC_NC_RX_02;

select [MEMBER_ALT_ID] as MemberID,
dateadd(day, 1,Eomonth(cast([FILLYMD] as date),-1)) as Cov_Month,
sum(cast([AMTPAID] as float)) as Paid_Amt,
PartBorD
into #UNC_PIPC_NC_RX_02
from #UNC_PIPC_NC_RX_01
group by [MEMBER_ALT_ID],
dateadd(day, 1,Eomonth(cast([FILLYMD] as date),-1)),
PartBorD
having sum(cast([AMTPAID]  as float)) <> 0


--select * from #UNC_PIPC_NC_RX_02

update a
set A.RX_D_Claims = E.Paid_Amt
from TranscendAnalytics.cdo.serviceFund_IFM_CW a
join #UNC_PIPC_NC_RX_02 e on e.MemberID = a.MemberID
			and e.Cov_Month = a.Cov_Month
where e.PartBorD = 'D'

update a
set A.RX_B_Claims = E.Paid_Amt
from TranscendAnalytics.cdo.serviceFund_IFM_CW a
join #UNC_PIPC_NC_RX_02 e on e.MemberID = a.MemberID
			and e.Cov_Month = a.Cov_Month
where e.PartBorD = 'B'

---------------------------------------------------------------
--Add Part A Total
update a
set a.ClaimsPartA = cast(a.ClaimsPartA_IP as float) + cast(a.ClaimsPartA_OP as float) + cast(a.ClaimsPartA_Other as float)
from TranscendAnalytics.cdo.serviceFund_IFM_CW a




----------------------------------------------------------------------------
--Reins Recoveries
--UHC-KC-STOP-LOSS  CENTERWELL_STOP_LOSS 1586
--Since the cov mth is not given the Reins Recov is divided across the members months

DECLARE @max_src_date DATE
	,@max_event_id INT;

SELECT TOP 1 @max_event_id = DDS_DATA_FEED_EVENT_ID
	,@max_src_date = convert(DATE, Event_Src_Date)
FROM PHM_DDS.DDS.DDS_DATA_FEED_EVENT
WHERE DDS_DATA_FEED_ID = 1586
	AND DDS_DATA_FEED_EVENT_STATUS = 3
ORDER BY DDS_Data_Feed_Event_Id DESC;


drop table if exists #Temp_UNC_PIPC_NC_STOPLOSS

SELECT J.*
into #Temp_UNC_PIPC_NC_STOPLOSS
FROM [PHM_DDS].[DDS].DDS_Data D with (NOLOCK)
 CROSS APPLY OPENJSON(D.Json) WITH(
[network_number] VARCHAR(250),
[network_name] VARCHAR(250),
[PCP] VARCHAR(250),
[PCP_Name] VARCHAR(250),
[GROUP_NUMBER] VARCHAR(250),
[Alt_ID] VARCHAR(250),
[Member_Last_Name] VARCHAR(250),
[Member_First_Name] VARCHAR(250),
[Recovery_year] VARCHAR(250),
[Qtr_RecRecovery] VARCHAR(250),
[YTD_Recovery] VARCHAR(250),
[PCP_NPI] VARCHAR(250),
[iteration] VARCHAR(250)) AS J 

WHERE DDS_Data_Feed_Event_Id = @max_event_id
	AND Event_Src_Date = @max_src_date
	;
--WHERE (
--(DDS_Data_Feed_Event_Id= (select max(DDS_Data_Feed_Event_Id) from PHM_DDS.DDS.DDS_Data_Feed_Event where DDS_Data_Feed_Id = '1586' and DDS_Data_Feed_Event_Status = '3')
--AND Event_Src_Date= (select max(Event_Src_Date) from PHM_DDS.DDS.DDS_Data_Feed_Event where DDS_Data_Feed_Id = '1586' and DDS_Data_Feed_Event_Status = '3')
--) )
----or 
----(DDS_Data_Feed_Event_Id = 37234) 
----)

--OPTION (MAXDOP 3);

--select * from #Temp_UNC_PIPC_NC_STOPLOSS


drop table if exists #Temp_UNC_PIPC_NC_STOPLOSS_SUM

select PCP, Alt_ID as MbrID, sum(cast(YTD_Recovery as float)) as ReinsRecovery
into #Temp_UNC_PIPC_NC_STOPLOSS_SUM
from #Temp_UNC_PIPC_NC_STOPLOSS
group by PCP, Alt_ID

drop table if exists #Temp_UNC_PIPC_NC_STOPLOSS_AVG

select a.MbrID, a.ReinsRecovery/b.MbrMthCount as ReinsAvgMth, b.MbrMthCount as MonthCount
into #Temp_UNC_PIPC_NC_STOPLOSS_AVG
from #Temp_UNC_PIPC_NC_STOPLOSS_SUM a
join (select MemberID, Count(MemberID) as MbrMthCount 
	  from cdo.serviceFund_IFM_CW
	  where Cov_Month < (select max(Cov_Month) from cdo.serviceFund_IFM_CW) group by memberID) b on a.MbrID = b.MemberID


--select * from #Temp_UNC_PIPC_NC_STOPLOSS_AVG

Update a
set a.ReinRecoveries = b.ReinsAvgMth
from cdo.serviceFund_IFM_CW a
join #Temp_UNC_PIPC_NC_STOPLOSS_AVG b on a.MemberID = b.MbrID
where a.Cov_Month < (select max(Cov_Month) from cdo.serviceFund_IFM_CW)



-- select top 10 *  from cdo.serviceFund_IFM_CW  select * from #tmpPMPM
----------------------------------------------------------------------------
--HOME ASSESSMENT (PMPM Based)


--select * from dbo.uhc_PIPC_NC_PMPM


update a
set a.Adjustment = isnull(cast(a.adjustment as float),0.00) + b.HomeAssmt -- cast(b.[HOME_ASSESSMENTS] as float)
from cdo.serviceFund_IFM_CW a
--join dbo.uhc_PIPC_NC_PMPM b on a.Cov_Month = b.cov_Month
inner join #tmpPMPM b on year(a.cov_month) = b.CovYear 

--select distinct 

----------------------------------------------------------------------------
--Advanced Payment (PCP CAP) (PMPM Based)

--select sum(cast(PCPCap as float))  from cdo.serviceFund_IFM_CW


update a
set a.PCPCap = isnull(cast(a.PCPCap as float),0.00) +  b.AdvPmt--+ cast(b.[Advanced_Payments] as float) 
from cdo.serviceFund_IFM_CW a
--join dbo.uhc_PIPC_NC_PMPM b on a.Cov_Month = b.cov_Month
inner join #tmpPMPM b on year(a.cov_month) = b.CovYear 

----------------------------------------------------------------------------

--------Update Company
drop table if exists #UNC_Company_xref;

select 
 distinct a.Facility_Name,
cast(a.oracle_fin_company_id as varchar) as oracle_fin_company_id,
b.PROVIDER_ID,
b.EFF_DATE,
b.END_DATE,
a.RollupMarket
into #UNC_Company_xref
from cdo_finance.ifm.Market a
inner join CDO_FINANCE.ifm.PROVIDERMARGIN_BUSINESSMAPPING b on a.Facility_Name = b.CENTER
where a.oracle_fin_company_id in ('656')
and (b.PAYER = 'UHC/PIPC' or b.PAYER = 'UNITED HEALTH CARE') and b.SUB_ORG = 'PIPC'

--select * from #UNC_Company_xref where provider_id = '10782164'
--select * from CDO_FINANCE.ifm.PROVIDERMARGIN_BUSINESSMAPPING b where PAYER = 'UHC/PIPC'
--select * from  cdo_finance.ifm.Market

----------Update Company
--drop table if exists #UNC_Company_xref_alt;
--select 
--a.Facility_Name,
--cast(a.oracle_fin_company_id as varchar) as oracle_fin_company_id,
--b.PROVIDER_ID,
--b.COV_MTH
--into #UNC_Company_xref_alt
--from cdo_finance.ifm.Market a
--inner join TRANSCENDANALYTICS.dbo.PROVIDERMARGIN_BUSINESSMAPPING_CWtest11282022 b on a.Facility_Name = b.CENTER
--where a.oracle_fin_company_id in ('660','658')
--and (b.PAYOR = 'UHC/PIPC' or b.PAYOR = 'UNITED HEALTH CARE')



--select * from TRANSCENDANALYTICS.dbo.PROVIDERMARGIN_BUSINESSMAPPING_CWtest11282022 where PAYOR = 'UNITED HEALTH CARE'

--select distinct payer, ORG, SUB_ORG from CDO_FINANCE.ifm.PROVIDERMARGIN_BUSINESSMAPPING where (PAYER = 'UHC/PIPC' or PAYER = 'UNITED HEALTH CARE') and SUB_ORG = 'PIPC'

--select * from #UNC_Company_xref
--select * from cdo_finance.ifm.Market

Update a
set a.Company = 'PIPC_' + x.oracle_fin_company_id,
	a.OfficeName = x.Facility_Name
from TranscendAnalytics.cdo.serviceFund_IFM_CW a
 join #UNC_Company_xref x on a.PCPID = x.PROVIDER_ID
						and a.Cov_Month between x.EFF_DATE and x.END_DATE
where InsuranceCompany = 'United'
and company is null

--select * from TranscendAnalytics.cdo.serviceFund_IFM_CW where PCPID like '%00040528391%'
--select * from #UNC_Company_xref where PROVIDER_ID like '%00040528391%'


Update a
set a.Company = 'PIPC_' + x.oracle_fin_company_id,
	a.OfficeName = x.Facility_Name,
	a.Market = 'KENTUCKY'
from TranscendAnalytics.cdo.serviceFund_IFM_CW a
 join #UNC_Company_xref x on '000'+ a.PCPID = x.PROVIDER_ID
						and a.Cov_Month between x.EFF_DATE and x.END_DATE
where InsuranceCompany = 'United' 
and company is null

--select * from TranscendAnalytics.cdo.serviceFund_IFM_CW where InsuranceCompany = 'United' and company is null

--Update a
--set a.Company = 'PIPC_' + x.oracle_fin_company_id,
--	a.OfficeName = x.Facility_Name
--from TranscendAnalytics.cdo.serviceFund_IFM_CW a
-- join #UNC_Company_xref_alt x on a.PCPID = x.PROVIDER_ID
--						and a.Cov_Month = x.COV_MTH
--where InsuranceCompany = 'United'



--Update a
--set a.Company = 'PIPC_' + x.oracle_fin_company_id,
--	a.OfficeName = x.Facility_Name
--from TranscendAnalytics.cdo.serviceFund_IFM_CW a
-- join #UNC_Company_xref_alt x on '000'+a.PCPID = x.PROVIDER_ID
--						and a.Cov_Month = x.COV_MTH
--where InsuranceCompany = 'United' 
--and company is null


--Default Companies for PCPs that are not in the BM table.
update  a
set Company = 'PIPC_656'
from TranscendAnalytics.cdo.serviceFund_IFM_CW a
where InsuranceCompany = 'United'  
and Company is null


--select * from cdo.serviceFund_IFM_CW where InsuranceCompany = 'United' and Company = 'PIPC_???'
--select distinct PCPID from cdo.serviceFund_IFM_CW where PCPID in('1154612307','1235329764','1982609459','1841396363','1932217296','1639403876','1124018437')
--------------------------------------------------------
--Directionality Notes
--Funding all positive
--Claims all positive
--IBNR always positive
--PCPCap always positive
--SpecCap always positive
--Fee always positive
--Aetna recoveries negative rest postive
--Adjustments go both ways
--Humana RX Stoploss negative rest positive
--Humana RX Rebates negative rest positive
--Humana RX LICS negative rest positive
--Humana RX Quality negative rest positive
--Aetna and Humana RX GDCA negative rest positive
--Aetna and Humana Gap Disc has FPG positive and CCS and Elite negative
--Only Freedom and Opt have values all negative


-------------------------------------------------------------------
--UPDATE PRODUCT
--drop table if exists #UNC_PIPC_NC_ELIG_Summary
--select [CES_ALT_ID] as Subcriber_ID,
--dateadd(day, 1,Eomonth(cast([ENR_EFF] as date),-1)) as ENR_EFF,
--CASE WHEN [MKP_DESCRIPTION] LIKE '%ppo%' THEN 'PPO' when [MKP_DESCRIPTION] like '%hmo%' then 'HMO' else 'PPO' end as Product,
--Max([CR_PER]) as Close_Month
--into #UNC_PIPC_NC_ELIG_Summary
--from #UNC_PIPC_NC_ELIG
--group by [CES_ALT_ID],
--dateadd(day, 1,Eomonth(cast([ENR_EFF] as date),-1)),
--CASE WHEN [MKP_DESCRIPTION] LIKE '%ppo%' THEN 'PPO' when [MKP_DESCRIPTION] like '%hmo%' then 'HMO' else 'PPO' end

--select * from #UNC_PIPC_NC_ELIG_Summary
--select * from TranscendAnalytics.cdo.serviceFund_IFM_CW where Product is null

--update a
--set a.Product = s.Product
--from TranscendAnalytics.cdo.serviceFund_IFM_CW a
--join #UNC_PIPC_NC_ELIG_Summary s on a.MemberID = s.Subcriber_ID
--and a.Cov_Month >= s.ENR_EFF
--where a.Product is null


update a 
set a.product = 'HMO'
from TranscendAnalytics.cdo.serviceFund_IFM_CW a
where a.product is null


-------------------------------------------------------------------

update TranscendAnalytics.cdo.serviceFund_IFM_CW 
set TotalClaims = isnull(ClaimsPartA,0) + isnull(ClaimsPartB,0) + isnull(RX_B_Claims,0)+ isnull(RX_D_Claims,0) 
where TotalClaims is null
and  InsuranceCompany = 'United' 



--Add Spec Cap PMPMs
--Ancillary Cap PMPM	 $69.32 
update TranscendAnalytics.cdo.serviceFund_IFM_CW 
set SpecCap = '283.95' 
where InsuranceCompany = 'United' 

--Add ACO Program Support $1 PMPM
update TranscendAnalytics.cdo.serviceFund_IFM_CW 
set Adjustment = isnull(cast(Adjustment as float),0.00) + '1' 
where InsuranceCompany = 'United' 

--Add Reinsurance Premium PMPM 397.69
--update TranscendAnalytics.cdo.serviceFund_IFM_CW 
--set StopLossFee = '397.69' 
--where InsuranceCompany = 'United' 

--------------------
---remove first three 000 characters if Mbr Number is 11 digits long  --WHY???
--update a
--set a.PCPID = right(a.PCPID,8)
--from TranscendAnalytics.cdo.serviceFund_IFM_CW a
--where len(a.PCPID) = '11'
--and left(a.PCPID,3) = '000'
--and  InsuranceCompany = 'United' and Company in('PIPC_656')





update 
cdo.serviceFund_IFM_CW 
set Tot_Exp =
(cast(isnull(ClaimsPartA,0) as float) +
cast(isnull(ClaimsPartB,0) as float) +
cast(isnull(RX_B_Claims,0) as float) +
cast(isnull(RX_D_Claims,0) as float) +
cast(isnull(IBNR,0) as float) +
cast(isnull(SpecCap,0) as float) +
cast(isnull(StopLossFee,0) as float) -
cast(isnull(ReinRecoveries,0) as float) +
cast(isnull(Adjustment,0) as float) -
cast(isnull(RX_Stoploss,0) as float) -
cast(isnull(RX_Rebates,0) as float) -
cast(isnull(RX_LICS,0) as float) -
cast(isnull(RX_Quality,0) as float) -
cast(isnull(RX_RISK_CORRIDOR,0) as float) -
cast(isnull(RX_GDCA,0) as float) -
cast(isnull(RX_REP_GAP_DSCNT,0) as float)
)
from cdo.serviceFund_IFM_CW 
where InsuranceCompany = 'United' and Company in('PIPC_656')





update 
cdo.serviceFund_IFM_CW 
set RX_D__Exp =
(cast(isnull(RX_D_Claims,0) as float) -
cast(isnull(RX_Stoploss,0) as float) -
cast(isnull(RX_Rebates,0) as float) -
cast(isnull(RX_LICS,0) as float) -
cast(isnull(RX_Quality,0) as float) -
cast(isnull(RX_RISK_CORRIDOR,0) as float) -
cast(isnull(RX_GDCA,0) as float) -
cast(isnull(RX_REP_GAP_DSCNT,0) as float)
)
from cdo.serviceFund_IFM_CW 
where InsuranceCompany = 'United' and Company in('PIPC_656')

update 
cdo.serviceFund_IFM_CW 
set FPGTotalFunding = cast(isnull(FPGFundingC,0) as float)
from cdo.serviceFund_IFM_CW 
where InsuranceCompany = 'United' and Company in('PIPC_656')

update 
cdo.serviceFund_IFM_CW 
set Net = cast(isnull(FPGTotalFunding,0) as float) - cast(isnull(Tot_Exp,0) as float)
from cdo.serviceFund_IFM_CW 
where InsuranceCompany = 'United' and Company in('PIPC_656')

--select * from cdo.serviceFund_IFM_CW where PCPID = '00010544040'
--select distinct len(PCPID), left(PCPID,3) from cdo.serviceFund_IFM_CW 

--update CDO_Finance.cdo.ServiceFund_IFM_All_BU20221019
--set Net =
--case when InsuranceCompany not in ('Humana', 'Aetna')
--then
--cast(FPGTotalFunding as float) -
--(cast(ClaimsPartA as float) +
--cast(ClaimsPartB as float) +
--cast(RX_B_Claims as float) +
--cast(RX_D_Claims as float) +
--cast(IBNR as float) +
--cast(SpecCap as float) +
--cast(StopLossFee as float) -
--cast(ReinRecoveries as float) +
--cast(Adjustment as float) -
--cast(RX_Stoploss as float) -
--cast(RX_Rebates as float) -
--cast(RX_LICS as float) -
--cast(RX_Quality as float) -
--cast(RX_GDCA as float) -
--cast(RX_REP_GAP_DSCNT as float)
--)
--when InsuranceCompany = 'Aetna' and Company = 'FPG'
--then
--cast(FPGTotalFunding as float) -
--(cast(ClaimsPartA as float) +
--cast(ClaimsPartB as float) +
--cast(RX_B_Claims as float) +
--cast(RX_D_Claims as float) +
--cast(IBNR as float) +
--cast(SpecCap as float) +
--cast(StopLossFee as float) -
--cast(ReinRecoveries as float) +
--cast(Adjustment as float) -
--cast(RX_Stoploss as float) -
--cast(RX_Rebates as float) -
--cast(RX_LICS as float) -
--cast(RX_Quality as float) -
--cast(RX_GDCA as float) -
--cast(RX_REP_GAP_DSCNT as float)
--)
--when InsuranceCompany = 'Aetna' and Company <> 'FPG'
--then
--cast(FPGTotalFunding as float) -
--(cast(ClaimsPartA as float) +
--cast(ClaimsPartB as float) +
--cast(RX_B_Claims as float) +
--cast(RX_D_Claims as float) +
--cast(IBNR as float) +
--cast(SpecCap as float) +
--cast(StopLossFee as float) -
--cast(ReinRecoveries as float) +
--cast(Adjustment as float) -
--cast(RX_Stoploss as float) -
--cast(RX_Rebates as float) -
--cast(RX_LICS as float) -
--cast(RX_Quality as float) +
--cast(RX_GDCA as float) +
--cast(RX_REP_GAP_DSCNT as float)
--)
--when InsuranceCompany = 'Humana'
--then
--cast(FPGTotalFunding as float) -
--(cast(ClaimsPartA as float) +
--cast(ClaimsPartB as float) +
--cast(RX_B_Claims as float) +
--cast(RX_D_Claims as float) +
--cast(IBNR as float) +
--cast(SpecCap as float) +
--cast(StopLossFee as float) -
--cast(ReinRecoveries as float) +
--cast(Adjustment as float) +
--cast(RX_Stoploss as float) +
--cast(RX_Rebates as float) +
--cast(RX_LICS as float) +
--cast(RX_Quality as float) +
--cast(RX_GDCA as float) +
--cast(RX_REP_GAP_DSCNT as float)
--)
--end
--from CDO_Finance.cdo.ServiceFund_IFM_All_BU20221019

---------------------------------------------------
--Create Triangle Table
--select distinct claim_class, Taxonomy from [CDO].[Triangle_PIPC_NonHumana_POT]
/*CREATE TABLE [CDO].[Triangle_PIPC_NonHumana_POT](
	[PAYER] [varchar](25) NOT NULL,
	[COMPANY] [varchar](25) NOT NULL,
	[COV_MONTH] [date] NULL,
	[PAID_MONTH] [date] NULL,
	[PAID_AMT] [float] NULL,
	[CLAIM_CLASS] [varchar](10) NOT NULL,
	[CLOSE_MONTH] [date] NULL,
	[UPDATE_DATE] [datetime] NULL,
	[POT_CD] [nvarchar](10) NULL,
	[Taxonomy] [nvarchar](25) NULL,
	[Product] [nvarchar](25) NULL,
	[PCP_ID] [nvarchar](50) NULL,
	[Facility_Name] [nvarchar](250) NULL
)*/
drop table if exists #temp_UHC_xref
select MemberID, PCPID, Cov_Month, OfficeName, Company, InsuranceCompany, Product, close_month
into #temp_UHC_xref
from cdo.serviceFund_IFM_CW

drop table if exists dbo.UHC_PIPC_NC_Triangle

select b.InsuranceCompany,
	b.Company,
	b.Cov_Month,
	a.Paid_Month,
	sum(cast(a.Paid_Amt as Float)) as Paid_Amt,
	Case when a.Pool = 'INPATIENT' then 'PARTA'
	when a.Pool = 'OUTPATIENT' then 'PARTA'
	when a.Pool = 'PHYSICIAN' then 'PARTB'
	else 'N/A' end as Claim_Class,
	b.close_month,
	getdate() as Update_date,
	Case when a.Pool = 'INPATIENT' then 'Hospital Inpatient'
	when a.Pool = 'OUTPATIENT' then 'Hospital Outpatient'
	when a.Pool = 'PHYSICIAN' then 'Physician'
	else 'N/A' end as Taxonomy,
	b.Product,
	b.PCPID as PCP_ID,
	b.OfficeName as Facility_Name
into dbo.UHC_PIPC_NC_Triangle
from #UNC_PIPC_NC_Claims_02 a
join #temp_UHC_xref b on a.MemberID = b.MemberID
						 and a.Cov_Month = b.Cov_Month
where a.POOL is not null
group by b.InsuranceCompany,
	b.Company,
	b.Cov_Month,
	a.Paid_Month,
	Case when a.Pool = 'INPATIENT' then 'PARTA'
	when a.Pool = 'OUTPATIENT' then 'PARTA'
	when a.Pool = 'PHYSICIAN' then 'PARTB'
	else 'N/A' end,
	b.close_month,
	Case when a.Pool = 'INPATIENT' then 'Hospital Inpatient'
	when a.Pool = 'OUTPATIENT' then 'Hospital Outpatient'
	when a.Pool = 'PHYSICIAN' then 'Physician'
	else 'N/A' end,
	b.Product,
	b.PCPID,
	b.OfficeName




-------------------------------------------------
delete from cdo.ServiceFund_IFM_CW_All where InsuranceCompany = 'United' and Company in('PIPC_656')

update cdo.ServiceFund_IFM_CW_All
set Market = 'NORTH CAROLINA'
from cdo.ServiceFund_IFM_CW_All where InsuranceCompany = 'United' and Company in('PIPC_656')


INSERT INTO 
cdo.serviceFund_IFM_CW_All
                         (InsuranceCompany, InsuranceCompanyID, OfficeName, SFPCPName, PCPLastName, PCPFirstName, PCPID, MemberID, MCARE_ID, Cov_Month, Close_Month, RiskScoreC, CMSFundingA, CMSFundingB, 
                         CMSFundingC, CMSFundingD, CMSTotalFunding, FPGFundingA, FPGFundingB, FPGFundingC, FPGFundingD, PartDReserve, FPGTotalFunding, SpecCap, PCPCap, ClaimsPartA, ClaimsPartB, ProfClaims, RX_B_Claims, 
                         RX_D_Claims, RX_Rebates, RX_Stoploss, RX_LICS, RX_Quality, RX_GDCA, RX_REP_GAP_DSCNT, RX_RISK_CORRIDOR, RX_D__EXP, TotalClaims, StopLossFee, ReinRecoveries, Adjustment, FactorMonth, IBNRPartA, 
                         IBNRPartB, IBNR, Tot_Exp, Net, MemberName, SFBirthDate, SFGender, Hospice, ESRD, Institutional, NursingHomeCertifiable, PreviouslyDisabled, CurrentMember, [Level], LOB, PlanCode, PlanName, IPAName, PBP, Age, 
                         Selection1, Selection2, Company, Product,ProductType, ClaimsPartA_IP, ClaimsPartA_OP, ClaimsPartA_Other, Market)
SELECT         
cdo.serviceFund_IFM_CW.InsuranceCompany, 
cdo.serviceFund_IFM_CW.InsuranceCompanyID, 
cdo.serviceFund_IFM_CW.OfficeName, 
cdo.serviceFund_IFM_CW.SFPCPName, 
cdo.serviceFund_IFM_CW.PCPLastName,               
cdo.serviceFund_IFM_CW.PCPFirstName, 
cdo.serviceFund_IFM_CW.PCPID, 
cdo.serviceFund_IFM_CW.MemberID, 
cdo.serviceFund_IFM_CW.MCARE_ID, 
cdo.serviceFund_IFM_CW.Cov_Month, 
cdo.serviceFund_IFM_CW.Close_Month, 
cdo.serviceFund_IFM_CW.RiskScoreC, 
sum(cast(cdo.serviceFund_IFM_CW.CMSFundingA as float)) as CMSFundingA, 
sum(cast(cdo.serviceFund_IFM_CW.CMSFundingB as float)) as CMSFundingB, 
sum(cast(cdo.serviceFund_IFM_CW.CMSFundingC as float)) as CMSFundingC, 
sum(cast(cdo.serviceFund_IFM_CW.CMSFundingD as float)) as CMSFundingD, 
sum(cast(cdo.serviceFund_IFM_CW.CMSTotalFunding as float)) as CMSTotalFunding, 
sum(cast(cdo.serviceFund_IFM_CW.FPGFundingA as float)) as FPGFundingA,
sum(cast(cdo.serviceFund_IFM_CW.FPGFundingB as float)) as FPGFundingB, 
sum(cast(cdo.serviceFund_IFM_CW.FPGFundingC as float)) as FPGFundingC, 
sum(cast(cdo.serviceFund_IFM_CW.FPGFundingD as float)) as FPGFundingD, 
sum(cast(cdo.serviceFund_IFM_CW.PartDReserve as float)) as PartDReserve, 
sum(cast(cdo.serviceFund_IFM_CW.FPGTotalFunding as float)) as FPGTotalFunding, 
sum(cast(cdo.serviceFund_IFM_CW.SpecCap as float)) as SpecCap, 
sum(cast(cdo.serviceFund_IFM_CW.PCPCap as float)) as PCPCap,
sum(cast(cdo.serviceFund_IFM_CW.ClaimsPartA as float)) as ClaimsPartA, 
sum(cast(cdo.serviceFund_IFM_CW.ClaimsPartB as float)) as ClaimsPartB, 
sum(cast(cdo.serviceFund_IFM_CW.ProfClaims as float)) as ProfClaims, 
sum(cast(cdo.serviceFund_IFM_CW.RX_B_Claims as float)) as RX_B_Claims, 
sum(cast(cdo.serviceFund_IFM_CW.RX_D_Claims as float)) as RX_D_Claims, 
sum(cast(cdo.serviceFund_IFM_CW.RX_Rebates as float)) as RX_Rebates, 
sum(cast(cdo.serviceFund_IFM_CW.RX_Stoploss as float)) as RX_Stoploss, 
sum(cast(cdo.serviceFund_IFM_CW.RX_LICS as float)) as RX_LICS, 
sum(cast(cdo.serviceFund_IFM_CW.RX_Quality as float)) as RX_Quality, 
sum(cast(cdo.serviceFund_IFM_CW.RX_GDCA as float)) as RX_GDCA, 
sum(cast(cdo.serviceFund_IFM_CW.RX_REP_GAP_DSCNT as float)) as RX_REP_GAP_DSCNT, 
sum(cast(cdo.serviceFund_IFM_CW.RX_RISK_CORRIDOR as float)) as RX_RISK_CORRIDOR, 
sum(cast(cdo.serviceFund_IFM_CW.RX_D__EXP as float)) as RX_D__EXP, 
sum(cast(cdo.serviceFund_IFM_CW.TotalClaims as float)) as TotalClaims, 
sum(cast(cdo.serviceFund_IFM_CW.StopLossFee as float)) as StopLossFee, 
sum(cast(cdo.serviceFund_IFM_CW.ReinRecoveries as float)) as ReinRecoveries, 
sum(cast(cdo.serviceFund_IFM_CW.adjustment as float)) as Adjustment, 
sum(cast(cdo.serviceFund_IFM_CW.FactorMonth as float)) as FactorMonth, 
sum(cast(cdo.serviceFund_IFM_CW.IBNRPartA as float)) as IBNRPartA, 
sum(cast(cdo.serviceFund_IFM_CW.IBNRPartB as float)) as IBNRPartB, 
sum(cast(cdo.serviceFund_IFM_CW.IBNR as float)) as IBNR, 
sum(cast(cdo.serviceFund_IFM_CW.Tot_Exp as float)) as Tot_Exp, 
sum(cast(cdo.serviceFund_IFM_CW.Net as float)) as Net, 
MemberName, 
SFBirthDate, 
SFGender, 
Hospice, 
ESRD, 
Institutional, 
NursingHomeCertifiable, 
PreviouslyDisabled, 
CurrentMember, 
[Level], 
LOB, 
PlanCode, 
PlanName, 
IPAName, 
PBP, 
Age, 
Selection1, 
Selection2, 
Company,  Product, ProductType, 
sum(cast(cdo.serviceFund_IFM_CW.ClaimsPartA_IP as float)) as ClaimsPartA_IP, 
sum(cast(cdo.serviceFund_IFM_CW.ClaimsPartA_OP as float)) as ClaimsPartA_OP, 
sum(cast(cdo.serviceFund_IFM_CW.ClaimsPartA_Other as float)) as ClaimsPartA_Other,
Market
FROM            
cdo.serviceFund_IFM_CW
group by 
cdo.serviceFund_IFM_CW.InsuranceCompany, 
cdo.serviceFund_IFM_CW.InsuranceCompanyID, 
cdo.serviceFund_IFM_CW.OfficeName, 
cdo.serviceFund_IFM_CW.SFPCPName, 
cdo.serviceFund_IFM_CW.PCPLastName,               
cdo.serviceFund_IFM_CW.PCPFirstName, 
cdo.serviceFund_IFM_CW.PCPID, 
cdo.serviceFund_IFM_CW.MemberID, 
cdo.serviceFund_IFM_CW.MCARE_ID, 
cdo.serviceFund_IFM_CW.Cov_Month, 
cdo.serviceFund_IFM_CW.Close_Month, 
cdo.serviceFund_IFM_CW.RiskScoreC, 
MemberName, 
SFBirthDate, 
SFGender, 
Hospice, 
ESRD, 
Institutional, 
NursingHomeCertifiable, 
PreviouslyDisabled, 
CurrentMember, 
[Level], 
LOB, 
PlanCode, 
PlanName, 
IPAName, 
PBP, 
Age, 
Selection1, 
Selection2, 
Company,  Product, ProductType , Market


--select * from cdo.serviceFund_IFM_CW
--select * from cdo.serviceFund_IFM_CW_All where InsuranceCompany = 'United' and Company in('PIPC_656') order by product


--select sum(cast(ClaimsPartA_IP as float)) as IP, sum(cast(ClaimsPartA_OP as float)) as OP, sum(cast(ClaimsPartB as float)) as B from cdo.serviceFund_IFM_CW 

END
GO
