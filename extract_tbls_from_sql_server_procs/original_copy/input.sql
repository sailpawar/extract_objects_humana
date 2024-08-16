USE [TranscendAnalytics]
GO
/****** Object:  StoredProcedure [dbo].[ifm_SF_CCS_Humana_CCS_Elite_Amicus]    Script Date: 6/6/2024 12:48:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[ifm_SF_CCS_Humana_CCS_Elite_Amicus] 


AS
BEGIN

                                SET NOCOUNT ON;

Declare @Close_Month as date

set @Close_Month = (SELECT        DATEADD(mm, 0, MAX(b.Date)) AS Expr1
FROM           (select distinct MBR_PROV_EFF_DATE,MBR_PROV_END_DATE from TranscendAnalytics.dbo.IFM_SF_MTH_CAP_FUNDING  where 
(TranscendAnalytics.dbo.IFM_SF_MTH_CAP_FUNDING.CURR_MBR_MTH_CNT > 0)) a inner JOIN
                         dbo.DaysOfTheMonth b 
on         (CONVERT(VARCHAR(10), b.Date, 112) BETWEEN a.MBR_PROV_EFF_DATE AND a.MBR_PROV_END_DATE)             
)

--select @Close_Month

drop table if exists #Temp_Month_Zero_Fix

SELECT        PROV_CTRCT_ID, MIN(INCURRED_MTH_NBR) AS MinMonth, LEFT(RTRIM(LTRIM(INCURRED_MTH_NBR)), 4) AS YYYY
Into #Temp_Month_Zero_Fix
FROM            IFM_SF_MTH_BALANCE
WHERE        (SRC_CHG_CD = 'AFT') AND (RIGHT(RTRIM(LTRIM(INCURRED_MTH_NBR)), 2) <> '00')
AND (NOT (FUND_TYPE_CD IN ('EXCL', 'STLS')))
and MBR_FULL_MTH_CNT > 0
GROUP BY PROV_CTRCT_ID, LEFT(RTRIM(LTRIM(INCURRED_MTH_NBR)), 4)
ORDER BY YYYY

drop table if exists #BM

select *,Contract_Key_No_Spaces = replace(PROVIDER_ID,' ','') into #BM from  CDO_FINANCE.ifm.PROVIDERMARGIN_BUSINESSMAPPING where  ORG IN ('CCS','Prime West')

--select * from #bm where org = 'prime west'


----LOAD THE MAIN SERVICE FUND TABLE---

truncate table   STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite

INSERT INTO STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
            (InsuranceCompany,
             MemberID,
             Cov_Month,
             Close_Month,
             MemberName,
             PCPID,
             SFGender,
             IPAName,
             PlanCode,
             PlanName,
             PBP,
             LOB,
             Product,
             Company,
             OfficeName,
             SFPCPName,
			 LoadDate,
			 Market,
			 Cohort,
			 Region,
			 Org,
			 Contract)
SELECT DISTINCT 
                         'Humana' AS Expr1, fnd.IDCARD_MBR_ID, C.Date, @close_month, LTRIM(RTRIM(fnd.MBR_LAST_NAME)) + ', ' + LTRIM(RTRIM(fnd.MBR_FIRST_NAME)) AS MemberName, fnd.PROV_CTRCT_ID, fnd.MBR_GENDER_CD, '' AS Expr2, 
                         fnd.PLAN_BENEFIT_PACKAGE_ID, fnd.PLAN_BENEFIT_PACKAGE_ID AS Expr4, fnd.PLAN_BENEFIT_PACKAGE_ID AS Expr5, fnd.SF_PROD_LOB_CD, 
                         CASE WHEN SF_PROD_LOB_CD = 'MER' THEN 'HMO' WHEN SF_PROD_LOB_CD = 'MEP' THEN 'PPO' ELSE SF_PROD_LOB_CD END AS Expr6, CASE WHEN bm.SUB_REGION IN ('AMI', 'AMICUS') 
                         THEN 'AMICUS' WHEN bm.SUB_REGION IN ('CHM', 'CMCM') THEN 'CCS' WHEN bm.SUB_REGION = 'ELITE' THEN 'ELITE' ELSE bm.SUB_REGION END AS Expr3, BM.CENTER, '' AS Expr7,
						 getdate(), bm.MARKET, bm.COHORT, bm.REGION, bm.ORG, fnd.MCO_CONTRACT_NBR
FROM            TranscendAnalytics.dbo.IFM_SF_MTH_CAP_FUNDING AS fnd INNER JOIN
                         #BM AS BM ON REPLACE(fnd.PROV_CTRCT_ID, ' ', '') = BM.Contract_Key_No_Spaces INNER JOIN
                         DaysOfTheMonth AS C ON C.Date BETWEEN CAST(fnd.MBR_PROV_EFF_DATE AS date) AND CAST(fnd.MBR_PROV_END_DATE AS date)
WHERE        (fnd.CURR_MBR_MTH_CNT > 0) AND (BM.SUB_REGION IN ('AMICUS', 'AMI', 'CHM', 'CMCM', 'Elite', 'CCS', 'Prime West'))
--AND (fnd.FUNDED_PROV_CTRCT_ID = '000104364  PCP310')
GROUP BY fnd.IDCARD_MBR_ID, C.Date, LTRIM(RTRIM(fnd.MBR_LAST_NAME)) + ', ' + LTRIM(RTRIM(fnd.MBR_FIRST_NAME)), fnd.PROV_CTRCT_ID, fnd.MBR_GENDER_CD, fnd.GROUPER_ID, fnd.PLAN_BENEFIT_PACKAGE_ID, 
                         fnd.SF_PROD_LOB_CD, BM.SUB_ORG, BM.CENTER, BM.PRACTICE, fnd.MBR_PROV_EFF_DATE, fnd.MBR_PROV_END_DATE, CASE WHEN bm.SUB_REGION IN ('AMI', 'AMICUS') 
                         THEN 'AMICUS' WHEN bm.SUB_REGION IN ('CHM', 'CMCM') THEN 'CCS' WHEN bm.SUB_REGION = 'ELITE' THEN 'ELITE' ELSE bm.SUB_REGION END, BM.EFF_DATE, BM.END_DATE,
						 BM.COHORT, BM.REGION, bm.ORG, bm.MARKET, bm.COHORT, bm.REGION, bm.ORG, MCO_CONTRACT_NBR
HAVING        (C.Date BETWEEN BM.EFF_DATE AND BM.END_DATE)



UPDATE STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
SET                ProductType = Prod.Product_Type
FROM STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite INNER JOIN
                         Industry_Product AS Prod ON STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite.PBP = Prod.PBP 
						 AND STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite.Contract = Prod.Contract_Number
						 AND STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite.Product = Prod.Plan_type


----************************
----FUNDING
----************************

---GET THE FUNDING TYPES---

drop table if exists #Fund_Codes_CCS

CREATE TABLE #Fund_Codes_CCS(
	[IDCARD_MBR_ID] [varchar](9) NULL,
	[MBR_PROV_EFF_DATE] [varchar](8) NULL,
	[MBR_PROV_END_DATE] [varchar](8) NULL,
	[GROUPER_ID] [varchar](8) NULL,
	[PROV_CTRCT_ID] [varchar](17) NULL,
	[FUNDED_PROV_CTRCT_ID] [varchar](17) NULL,
	[FUND_TYPE_CD_1] [varchar](4) NULL,
	[FUND_TYPE_CD_2] [varchar](4) NULL,
	[FUND_TYPE_CD_3] [varchar](4) NULL,
	[FUND_TYPE_CD_4] [varchar](4) NULL,
	[FUND_TYPE_CD_5] [varchar](4) NULL,
	[FUND_TYPE_CD_6] [varchar](4) NULL,
	[CharDate] [varchar](8) NULL
	--,	[Contract_Key_No_Spaces] [varchar](8000) NULL
)

TRUNCATE TABLE #Fund_Codes_CCS

INSERT INTO  #Fund_Codes_CCS

--select distinct IDCARD_MBR_ID from #Fund_Codes_CCS where PROV_CTRCT_ID = '000151442  PCP329' and MBR_PROV_EFF_DATE = '20200101'

SELECT DISTINCT 
fnd.IDCARD_MBR_ID, 
fnd.MBR_PROV_EFF_DATE, 
fnd.MBR_PROV_END_DATE, 
fnd.GROUPER_ID, 
fnd.PROV_CTRCT_ID, 
fnd.FUNDED_PROV_CTRCT_ID, 
fnd.FUND_TYPE_CD_1, 
fnd.FUND_TYPE_CD_2, 
fnd.FUND_TYPE_CD_3, 
fnd.FUND_TYPE_CD_4, 
fnd.FUND_TYPE_CD_5, 
fnd.FUND_TYPE_CD_6, 
--trim(fnd.Contract_Key_No_Spaces),
C.CharDate
FROM   TranscendAnalytics.dbo.IFM_SF_MTH_CAP_FUNDING AS fnd
INNER JOIN #BM AS ORG on replace(fnd.FUNDED_PROV_CTRCT_ID,' ','') = ORG.Contract_Key_No_Spaces
INNER JOIN dbo.DaysOfTheMonth C 
ON C.Date BETWEEN cast(fnd.MBR_PROV_EFF_DATE as date) AND cast(fnd.MBR_PROV_END_DATE as date)
WHERE  (fnd.CURR_MBR_MTH_CNT > 0) 
and (fnd.FILE_SRC_DESC = 'RE610')

---SPIN THE TABLE TO BE TALL--

drop table if exists #Temp_Fund1_CCS

CREATE TABLE #Temp_Fund1_CCS(
	[IDCARD_MBR_ID] [varchar](9) NULL,
	[MBR_PROV_EFF_DATE] [varchar](8) NULL,
	[MBR_PROV_END_DATE] [varchar](8) NULL,
	[grpr_comp_name] [nvarchar](255) NULL,
	[grouper_ID] [varchar](8) NULL,
	[FUNDED_PROV_CTRCT_ID] [varchar](17) NULL,
	[FundNo] [nvarchar](128) NULL,
	[FundName] [varchar](4) NULL,
	[FUNDRte] [decimal](11, 2) NULL,
	[CharDate] [varchar](8) NULL
)

truncate table #Temp_Fund1_CCS

insert into #Temp_Fund1_CCS
(IDCARD_MBR_ID,MBR_PROV_EFF_DATE, MBR_PROV_END_DATE,grouper_ID,FUNDED_PROV_CTRCT_ID, CharDate, FundNo, FundName )
SELECT IDCARD_MBR_ID,MBR_PROV_EFF_DATE, MBR_PROV_END_DATE, grouper_ID,funded_prov_ctrct_ID, CharDate , FundNo, FundName
FROM
(SELECT IDCARD_MBR_ID,MBR_PROV_EFF_DATE, MBR_PROV_END_DATE,GROUPER_ID, FUNDED_PROV_CTRCT_ID, CharDate,
FUND_TYPE_CD_1, FUND_TYPE_CD_2, FUND_TYPE_CD_3, FUND_TYPE_CD_4, FUND_TYPE_CD_5, FUND_TYPE_CD_6
FROM #Fund_Codes_CCS
)FUND
--group by IDCARD_MBR_ID,MBR_PROV_EFF_DATE, MBR_PROV_END_DATE,GROUPER_ID, _prov_ctrct_ID,
UNPIVOT
(FundName FOR FundNo IN (FUND_TYPE_CD_1, FUND_TYPE_CD_2, FUND_TYPE_CD_3, FUND_TYPE_CD_4, FUND_TYPE_CD_5, FUND_TYPE_CD_6)
) AS mrks


delete from #Temp_Fund1_CCS where  FundName in ( '','EXCL','OTHB')

---UPDATE EACH FUNDING TYPE WITH THE AMOUNTS--

UPDATE #Temp_Fund1_CCS
SET FUNDRte = F.FUND_RATE_1
FROM  #Temp_Fund1_CCS INNER JOIN
TranscendAnalytics.dbo.IFM_SF_MTH_CAP_FUNDING f
ON #Temp_Fund1_CCS.IDCARD_MBR_ID = F.IDCARD_MBR_ID AND #Temp_Fund1_CCS.MBR_PROV_EFF_DATE = F.MBR_PROV_EFF_DATE 
AND #Temp_Fund1_CCS.MBR_PROV_END_DATE <= F.MBR_PROV_END_DATE 
AND #Temp_Fund1_CCS.grouper_ID = F.GROUPER_ID 
AND replace(#Temp_Fund1_CCS.FUNDED_PROV_CTRCT_ID,' ','') = replace(F.FUNDED_PROV_CTRCT_ID,' ', '') 
AND #Temp_Fund1_CCS.FundName = F.FUND_TYPE_CD_1
WHERE (F.CURR_MBR_MTH_CNT > 0)


UPDATE #Temp_Fund1_CCS
SET FundRte = F.FUND_RATE_2
FROM #Temp_Fund1_CCS INNER JOIN
TranscendAnalytics.dbo.IFM_SF_MTH_CAP_FUNDING f
ON #Temp_Fund1_CCS.IDCARD_MBR_ID = F.IDCARD_MBR_ID AND #Temp_Fund1_CCS.MBR_PROV_EFF_DATE = F.MBR_PROV_EFF_DATE 
AND #Temp_Fund1_CCS.MBR_PROV_END_DATE <= F.MBR_PROV_END_DATE 
AND #Temp_Fund1_CCS.grouper_ID = F.GROUPER_ID 
AND replace(#Temp_Fund1_CCS.FUNDED_PROV_CTRCT_ID,' ','') = replace(F.FUNDED_PROV_CTRCT_ID,' ', '') 
AND #Temp_Fund1_CCS.FundName = F.FUND_TYPE_CD_2
WHERE        (F.CURR_MBR_MTH_CNT > 0)

UPDATE #Temp_Fund1_CCS
SET FundRte = F.FUND_RATE_3
FROM  #Temp_Fund1_CCS INNER JOIN
TranscendAnalytics.dbo.IFM_SF_MTH_CAP_FUNDING f
ON #Temp_Fund1_CCS.IDCARD_MBR_ID = F.IDCARD_MBR_ID 
AND #Temp_Fund1_CCS.MBR_PROV_EFF_DATE = F.MBR_PROV_EFF_DATE 
AND #Temp_Fund1_CCS.MBR_PROV_END_DATE <= F.MBR_PROV_END_DATE 
AND #Temp_Fund1_CCS.grouper_ID = F.GROUPER_ID 
AND replace(#Temp_Fund1_CCS.FUNDED_PROV_CTRCT_ID,' ','') = replace(F.funded_PROV_CTRCT_ID,' ', '') 
AND #Temp_Fund1_CCS.FundName = F.FUND_TYPE_CD_3
WHERE (F.CURR_MBR_MTH_CNT > 0)

UPDATE #Temp_Fund1_CCS
SET FundRte = F.FUND_RATE_4
FROM #Temp_Fund1_CCS INNER JOIN
TranscendAnalytics.dbo.IFM_SF_MTH_CAP_FUNDING f
ON #Temp_Fund1_CCS.IDCARD_MBR_ID = F.IDCARD_MBR_ID 
AND #Temp_Fund1_CCS.MBR_PROV_EFF_DATE = F.MBR_PROV_EFF_DATE 
AND #Temp_Fund1_CCS.MBR_PROV_END_DATE <= F.MBR_PROV_END_DATE 
AND #Temp_Fund1_CCS.grouper_ID = F.GROUPER_ID 
AND replace(#Temp_Fund1_CCS.FUNDED_PROV_CTRCT_ID,' ','') = replace(F.funded_PROV_CTRCT_ID,' ', '') 
AND #Temp_Fund1_CCS.FundName = F.FUND_TYPE_CD_4
WHERE        (F.CURR_MBR_MTH_CNT > 0)

UPDATE #Temp_Fund1_CCS
SET  FundRte = F.FUND_RATE_5
FROM #Temp_Fund1_CCS INNER JOIN
TranscendAnalytics.dbo.IFM_SF_MTH_CAP_FUNDING f  
ON #Temp_Fund1_CCS.IDCARD_MBR_ID = F.IDCARD_MBR_ID 
AND #Temp_Fund1_CCS.MBR_PROV_EFF_DATE = F.MBR_PROV_EFF_DATE 
AND #Temp_Fund1_CCS.MBR_PROV_END_DATE <= F.MBR_PROV_END_DATE 
AND #Temp_Fund1_CCS.grouper_ID = F.GROUPER_ID 
AND replace(#Temp_Fund1_CCS.FUNDED_PROV_CTRCT_ID,' ','') = replace(F.FUNDED_PROV_CTRCT_ID,' ', '') 
AND #Temp_Fund1_CCS.FundName = F.FUND_TYPE_CD_5
WHERE (F.CURR_MBR_MTH_CNT > 0)

UPDATE #Temp_Fund1_CCS
SET FundRte = F.FUND_RATE_6
FROM #Temp_Fund1_CCS INNER JOIN
TranscendAnalytics.dbo.IFM_SF_MTH_CAP_FUNDING f 
ON #Temp_Fund1_CCS.IDCARD_MBR_ID = F.IDCARD_MBR_ID
AND #Temp_Fund1_CCS.MBR_PROV_EFF_DATE = F.MBR_PROV_EFF_DATE 
AND #Temp_Fund1_CCS.MBR_PROV_END_DATE <= F.MBR_PROV_END_DATE 
AND #Temp_Fund1_CCS.grouper_ID = F.GROUPER_ID 
AND replace(#Temp_Fund1_CCS.FUNDED_PROV_CTRCT_ID,' ','') = replace(F.FUNDED_PROV_CTRCT_ID,' ' ,'') 
AND #Temp_Fund1_CCS.FundName = F.FUND_TYPE_CD_6
WHERE(F.CURR_MBR_MTH_CNT > 0)

drop table if exists #Temp_Fund2_CCS

CREATE TABLE #Temp_Fund2_CCS(
	[IDCARD_MBR_ID] [varchar](9) NULL,
	[Date] [datetime] NULL,
	[MBR_PROV_EFF_DATE] [varchar](8) NULL,
	[MBR_PROV_END_DATE] [varchar](8) NULL,
	[grpr_comp_name] [nvarchar](255) NULL,
	[grouper_ID] [varchar](8) NULL,
	[FUNDED_PROV_CTRCT_ID] [varchar](17) NULL,
	[FundNo] [nvarchar](128) NULL,
	[FundName] [varchar](4) NULL,
	[FUNDRte] [decimal](11, 2) NULL
)

truncate table #Temp_Fund2_CCS                                                                                         

INSERT INTO #Temp_Fund2_CCS
                         (IDCARD_MBR_ID, Date, MBR_PROV_EFF_DATE, MBR_PROV_END_DATE, grouper_ID, FUNDED_PROV_CTRCT_ID, FundNo, FundName, FUNDRte)
SELECT        F1.IDCARD_MBR_ID, DaysOfTheMonth.Date, F1.MBR_PROV_EFF_DATE, F1.MBR_PROV_END_DATE, F1.grouper_ID, F1.FUNDED_PROV_CTRCT_ID, F1.FundNo, F1.FundName, F1.FUNDRte
FROM            #Temp_Fund1_CCS AS F1 CROSS JOIN
                         DaysOfTheMonth
WHERE        (CONVERT(VARCHAR(10), DaysOfTheMonth.Date, 112) BETWEEN F1.MBR_PROV_EFF_DATE AND F1.MBR_PROV_END_DATE)
group by IDCARD_MBR_ID, Date, MBR_PROV_EFF_DATE, MBR_PROV_END_DATE, grouper_ID, FUNDED_PROV_CTRCT_ID, FundNo, FundName, FUNDRte

--SUMMARIZE THE TOTAL FUNDING BY MONTH--

drop table if exists #Temp_FundingTotal

CREATE TABLE #Temp_FundingTotal(
	[IDCARD_MBR_ID] [varchar](9) NULL,
	[Date] [datetime] NULL,
	[FUNDED_PROV_CTRCT_ID] [varchar](17) NULL,
	[TotalFunding] [decimal](38, 2) NULL
)

truncate   table  #Temp_FundingTotal

insert  into #Temp_FundingTotal
SELECT 
IDCARD_MBR_ID,  
DATE,
FUNDED_PROV_CTRCT_ID,
SUM(FUNDRte) AS TotalFunding 
FROM   #Temp_Fund2_CCS 
group by IDCARD_MBR_ID, Date, FUNDED_PROV_CTRCT_ID


                                               
---LOAD TOTAL FUNDING INTO THE MASTER SERVICE FUND TABLE


UPDATE STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
SET ProviderTotalFunding =  #Temp_FundingTotal.TotalFunding
FROM STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite INNER JOIN
#Temp_FundingTotal      
ON STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite.MemberID =  #Temp_FundingTotal.IDCARD_MBR_ID 
AND STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite.Cov_Month =  #Temp_FundingTotal.Date
and Replace(STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite.PCPID,' ', '')  =  replace(#Temp_FundingTotal.FUNDED_PROV_CTRCT_ID,' ','')

-- GET THE PCP CAP
 
drop table if exists #IFM_Temp_PCPCap

CREATE TABLE #IFM_Temp_PCPCap(
	[FUNDED_PROV_CTRCT_ID] [varchar](17) NULL,
	[IDCARD_MBR_ID] [varchar](9) NULL,
	[CharDate] [varchar](08) NULL,
	[Date] [datetime] NULL,
	[FUNDRte] [decimal](38, 2) NULL
)

TRUNCATE TABLE  #IFM_Temp_PCPCap

INSERT INTO  #IFM_Temp_PCPCap

SELECT 
FUNDED_PROV_CTRCT_ID,
IDCARD_MBR_ID, 
CharDate, 
cast(chardate as date) as Date,
Sum(FUNDRte) as FUNDRte
FROM #Temp_Fund1_CCS
WHERE (FundName in ('PCRE', 'CCFE'))
--and IDCARD_MBR_ID = 'H66896559'
group by
FUNDED_PROV_CTRCT_ID,
IDCARD_MBR_ID, 
CharDate


UPDATE STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
SET   PCPCap = #IFM_Temp_PCPCap.FUNDRte
FROM  STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite INNER JOIN
#IFM_Temp_PCPCap ON STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite.MemberID = #IFM_Temp_PCPCap.IDCARD_MBR_ID 
AND STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite.Cov_Month = #IFM_Temp_PCPCap.Date
and STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite.PCPID = #IFM_Temp_PCPCap.FUNDED_PROV_CTRCT_ID


--GET THE STOPLOSS

drop table if exists #IFM_Temp_StopLossFee

 -- have to use #Temp_Fund2_CCS


CREATE TABLE #IFM_Temp_StopLossFee(
	[IDCARD_MBR_ID] [varchar](9) NULL,
	[Date] [datetime] NULL,
	[FUNDED_PROV_CTRCT_ID] [varchar](17) NULL,
	[FUNDRte] [decimal](38, 2) NULL
	
)

TRUNCATE TABLE  #IFM_Temp_StopLossFee

INSERT INTO  #IFM_Temp_StopLossFee
SELECT  
IDCARD_MBR_ID, 
c.Date, 
FUNDED_PROV_CTRCT_ID,
FUNDRte 
FROM #Temp_Fund2_CCS
INNER JOIN
dbo.DaysOfTheMonth C
ON C.Date BETWEEN cast(#Temp_Fund2_CCS.MBR_PROV_EFF_DATE as date) AND cast(#Temp_Fund2_CCS.MBR_PROV_END_DATE as date)
 WHERE (FundName in ('STLS')) --and PROV_CTRCT_ID = '000172028  PCP312' and IDCARD_MBR_ID = 'H00339086'
group by 
IDCARD_MBR_ID, 
c.Date,
FUNDED_PROV_CTRCT_ID,
FUNDRte


UPDATE   STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
SET  StopLossFee = #IFM_Temp_StopLossFee.FUNDRte
FROM  STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite INNER JOIN
#IFM_Temp_StopLossFee ON STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite.MemberID = #IFM_Temp_StopLossFee.IDCARD_MBR_ID 
AND STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite.Cov_Month = #IFM_Temp_StopLossFee.Date

----************************
----Claims
----************************

drop table if exists IFM_Temp_Claims1

--CREATE TABLE IFM_temp_claims1(
--	[UMID] [varchar](25) NULL,
--	[FUND_EXPN_DATE] [varchar](8) NULL,
--	[Contract_Key_No_Spaces] [varchar](50) NULL,
--	[PROV_CTRCT_ID] [varchar](17) NULL,
--	[SF_PROD_LOB_CD] [varchar](5) NULL,
--	[Cov_Month] [date] NULL,
--	[CLMTYP] [varchar](15) NULL,
--	[FUND_Month] [varchar](20) NULL,
--	[Type] [varchar](10) NULL,
--	[AMT] [numeric](38, 2) NULL,
--	[GROUPER_ID] [varchar](15) NULL,
--	[POT_CD] [varchar](3) NULL,
--	[PROCESS_DATE_CONV] [datetime] NULL,
--	[FUND_TYPE_CD] [varchar](15) NULL,
--	[COMPANY] [varchar](100) NULL,
--	[INCUR_DATE_CONV][datetime] NULL,
--	[SRC_CLAIM_NBR] [Varchar] (50) NULL
--)

--truncate table IFM_temp_claims1

--insert INTO IFM_temp_claims1
SELECT  SRC_CLAIM_NBR,  LEFT(UMID, 9) AS UMID, FUND_EXPN_DATE, a.Contract_Key_No_Spaces,
PROV_CTRCT_ID, SF_PROD_LOB_CD,
Cov_Month,
CLMTYP,
CASE WHEN RIGHT(rtrim(ltrim(FUND_EXPN_DATE)), 2) = '00' THEN concat(LEFT(rtrim(ltrim(FUND_EXPN_DATE)), 4), 
 replace(RIGHT(rtrim(ltrim(FUND_EXPN_DATE)), 2), '00', '01')) ELSE FUND_EXPN_DATE END AS FUND_Month,
CASE WHEN CLMTYP = 'NONRX' AND  PROV_TYPE_CD = 'HS' AND CAST(POT_CD AS varchar) in ('1', 'X', 'Z') THEN 'PRTA_IP' 
WHEN CLMTYP = 'NONRX' AND PROV_TYPE_CD = 'HS' AND CAST(POT_CD AS varchar) in ('2', 'R', 'W') THEN 'PRTA_OP' 
WHEN CLMTYP = 'NONRX' AND PROV_TYPE_CD = 'HS' AND CAST(POT_CD AS varchar) NOT IN ('1', '2', 'X', 'Z', 'R', 'W') THEN 'PRTA_Other' 
WHEN CLMTYP = 'NONRX' AND PROV_TYPE_CD <> 'HS' THEN 'PRTB' 
WHEN CLMTYP = 'RX' AND POST_PAY4_CD = 'D' AND SF_CAUSE_CD NOT IN ('RXCGD', 'RXLIS', 'RXREI') THEN 'PRTD' 
-- added line for MCD Part D
WHEN CLMTYP = 'RX' AND SF_PROD_LOB_CD = 'MCD' and PROV_SPCLT_CD = '52' THEN 'PRTD' 
WHEN CLMTYP = 'RX' AND POST_PAY4_CD <> 'D' THEN 'RX_PartB' 
WHEN SF_CAUSE_CD IN ('RXCGD', 'RXLIS', 'RXREI') THEN SF_CAUSE_CD END AS Type, 
SUM(CLM_EXPN_AMT) AS AMT, GROUPER_ID, POT_CD,
DATEADD(mm, DATEDIFF(mm, 0, PROCESS_DATE_CONV), 0) as PROCESS_DATE_CONV, FUND_TYPE_CD,
case when b.SUB_REGION in ('AMI', 'AMICUS') then 'AMICUS' when b.SUB_REGION in ('CHM', 'CMCM') then 'CCS' when b.SUB_REGION = 'ELITE' then 'ELITE' else b.SUB_REGION end as Company,
INCUR_DATE_CONV
into IFM_Temp_Claims1
FROM  TranscendAnalytics.dbo.IFM_SF_MTH_CLAIMS_LINES a
inner join #BM b
on a.Contract_Key_No_Spaces = b.Contract_Key_No_Spaces
and a.Cov_Month between b.EFF_DATE and b.END_DATE
where 
-- put the below line back in per meeting with Finance 4/12/2024 email from emily an same date
FUND_TYPE_CD not in ( 'EXCL') and 
FUND_EXPN_DATE <> 000000
GROUP BY SRC_CLAIM_NBR, UMID, 
FUND_EXPN_DATE, 
a.Contract_Key_No_Spaces,
CLMTYP, 
CASE WHEN CLMTYP = 'NONRX' 
AND PROV_TYPE_CD = 'HS' 
AND CAST(POT_CD AS varchar) in ('1', 'X', 'Z') THEN 'PRTA_IP' WHEN CLMTYP = 'NONRX' AND PROV_TYPE_CD = 'HS' 
AND CAST(POT_CD AS varchar) in ('2', 'R', 'W') THEN 'PRTA_OP' WHEN CLMTYP = 'NONRX' AND PROV_TYPE_CD = 'HS' 
AND CAST(POT_CD AS varchar) NOT IN ('1', '2', 'X', 'Z', 'R', 'W') THEN 'PRTA_Other' WHEN CLMTYP = 'NONRX' 
AND PROV_TYPE_CD <> 'HS' THEN 'PRTB' WHEN CLMTYP = 'RX' 
AND POST_PAY4_CD = 'D' AND SF_CAUSE_CD NOT IN ('RXCGD', 'RXLIS', 'RXREI') THEN 'PRTD'
-- added line for MCD Part D
WHEN CLMTYP = 'RX' AND SF_PROD_LOB_CD = 'MCD' and PROV_SPCLT_CD = '52' THEN 'PRTD'
WHEN CLMTYP = 'RX' 
AND POST_PAY4_CD <> 'D' THEN 'RX_PartB' WHEN SF_CAUSE_CD IN ('RXCGD', 'RXLIS', 'RXREI') THEN SF_CAUSE_CD END, GROUPER_ID, PROV_CTRCT_ID, SF_PROD_LOB_CD, 
POT_CD, Cov_Month, CASE WHEN RIGHT(rtrim(ltrim(FUND_EXPN_DATE)), 2) = '00' THEN concat(LEFT(rtrim(ltrim(FUND_EXPN_DATE)), 4), replace(RIGHT(rtrim(ltrim(FUND_EXPN_DATE)), 2), '00', '01')) 
ELSE FUND_EXPN_DATE END, CASE WHEN CLMTYP = 'NONRX' AND PROV_TYPE_CD = 'HS' THEN 'PRTA'
WHEN CLMTYP = 'NONRX' AND PROV_TYPE_CD = 'HS' AND CAST(POT_CD AS varchar) 
in ( '1', 'X', 'Z') THEN 'PRTA_IP'
WHEN CLMTYP = 'NONRX' AND PROV_TYPE_CD = 'HS' AND CAST(POT_CD AS varchar) in ('2', 'R', 'W') THEN 'PRTA_OP'
WHEN CLMTYP = 'NONRX' AND PROV_TYPE_CD = 'HS' AND CAST(POT_CD AS varchar) 
NOT IN ('1', '2', 'X', 'Z', 'R', 'W') THEN 'PRTA_Other'
WHEN CLMTYP = 'NONRX' AND PROV_TYPE_CD <> 'HS' THEN 'PRTB' WHEN CLMTYP = 'RX' AND POST_PAY4_CD = 'D' AND SF_CAUSE_CD NOT IN ('RXCGD', 'RXLIS', 'RXREI') 
THEN 'PRTD' WHEN CLMTYP = 'RX' AND POST_PAY4_CD <> 'D' THEN 'RX_PartB' WHEN SF_CAUSE_CD IN ('RXCGD', 'RXLIS', 'RXREI') THEN SF_CAUSE_CD END, LEFT(UMID, 9),
DATEADD(mm, DATEDIFF(mm, 0, PROCESS_DATE_CONV), 0), FUND_TYPE_CD,
case when b.SUB_REGION in ('AMI', 'AMICUS') then 'AMICUS' when b.SUB_REGION in ('CHM', 'CMCM') then 'CCS' when b.SUB_REGION = 'ELITE' then 'ELITE' else b.SUB_REGION end, INCUR_DATE_CONV

update IFM_Temp_Claims1
set --FUND_EXPN_DATE = left(trim(fund_expn_date),4) + '01',
Cov_Month = CONVERT(date, CONCAT(Fund_Month, '01'))
--Cov_Month = DATEADD(yyyy,1,Cov_Month)
from IFM_Temp_Claims1 where right(trim(fund_expn_date),2) = 00

drop table if exists IFM_Temp_Claims_excl

-- excl claims only

SELECT  SRC_CLAIM_NBR,  LEFT(UMID, 9) AS UMID, FUND_EXPN_DATE, a.Contract_Key_No_Spaces,
PROV_CTRCT_ID, SF_PROD_LOB_CD,
Cov_Month,
CLMTYP,
CASE WHEN RIGHT(rtrim(ltrim(FUND_EXPN_DATE)), 2) = '00' THEN concat(LEFT(rtrim(ltrim(FUND_EXPN_DATE)), 4), 
 replace(RIGHT(rtrim(ltrim(FUND_EXPN_DATE)), 2), '00', '01')) ELSE FUND_EXPN_DATE END AS FUND_Month,
CASE WHEN CLMTYP = 'NONRX' AND  PROV_TYPE_CD = 'HS' AND CAST(POT_CD AS varchar) in ('1', 'X', 'Z') THEN 'PRTA_IP' 
WHEN CLMTYP = 'NONRX' AND PROV_TYPE_CD = 'HS' AND CAST(POT_CD AS varchar) in ('2', 'R', 'W') THEN 'PRTA_OP' 
WHEN CLMTYP = 'NONRX' AND PROV_TYPE_CD = 'HS' AND CAST(POT_CD AS varchar) NOT IN ('1', '2', 'X', 'Z', 'R', 'W') THEN 'PRTA_Other' 
WHEN CLMTYP = 'NONRX' AND PROV_TYPE_CD <> 'HS' THEN 'PRTB' 
WHEN CLMTYP = 'RX' AND POST_PAY4_CD = 'D' AND SF_CAUSE_CD NOT IN ('RXCGD', 'RXLIS', 'RXREI') THEN 'PRTD' 
-- added line for MCD Part D
WHEN CLMTYP = 'RX' AND SF_PROD_LOB_CD = 'MCD' and PROV_SPCLT_CD = '52' THEN 'PRTD' 
WHEN CLMTYP = 'RX' AND POST_PAY4_CD <> 'D' THEN 'RX_PartB' 
WHEN SF_CAUSE_CD IN ('RXCGD', 'RXLIS', 'RXREI') THEN SF_CAUSE_CD END AS Type, 
SUM(CLM_EXPN_AMT) AS AMT, GROUPER_ID, POT_CD,
DATEADD(mm, DATEDIFF(mm, 0, PROCESS_DATE_CONV), 0) as PROCESS_DATE_CONV, FUND_TYPE_CD,
case when b.SUB_REGION in ('AMI', 'AMICUS') then 'AMICUS' when b.SUB_REGION in ('CHM', 'CMCM') then 'CCS' when b.SUB_REGION = 'ELITE' then 'ELITE' else b.SUB_REGION end as Company,
INCUR_DATE_CONV
into IFM_Temp_Claims_excl
FROM  TranscendAnalytics.dbo.IFM_SF_MTH_CLAIMS_LINES a
inner join #BM b
on a.Contract_Key_No_Spaces = b.Contract_Key_No_Spaces
and a.Cov_Month between b.EFF_DATE and b.END_DATE
where 
-- put the below line back in per meeting with Finance 4/12/2024 email from emily an same date
FUND_TYPE_CD = ( 'EXCL') and 
FUND_EXPN_DATE <> 000000
GROUP BY SRC_CLAIM_NBR, UMID, 
FUND_EXPN_DATE, 
a.Contract_Key_No_Spaces,
CLMTYP, 
CASE WHEN CLMTYP = 'NONRX' 
AND PROV_TYPE_CD = 'HS' 
AND CAST(POT_CD AS varchar) in ('1', 'X', 'Z') THEN 'PRTA_IP' WHEN CLMTYP = 'NONRX' AND PROV_TYPE_CD = 'HS' 
AND CAST(POT_CD AS varchar) in ('2', 'R', 'W') THEN 'PRTA_OP' WHEN CLMTYP = 'NONRX' AND PROV_TYPE_CD = 'HS' 
AND CAST(POT_CD AS varchar) NOT IN ('1', '2', 'X', 'Z', 'R', 'W') THEN 'PRTA_Other' WHEN CLMTYP = 'NONRX' 
AND PROV_TYPE_CD <> 'HS' THEN 'PRTB' WHEN CLMTYP = 'RX' 
AND POST_PAY4_CD = 'D' AND SF_CAUSE_CD NOT IN ('RXCGD', 'RXLIS', 'RXREI') THEN 'PRTD'
-- added line for MCD Part D
WHEN CLMTYP = 'RX' AND SF_PROD_LOB_CD = 'MCD' and PROV_SPCLT_CD = '52' THEN 'PRTD'
WHEN CLMTYP = 'RX' 
AND POST_PAY4_CD <> 'D' THEN 'RX_PartB' WHEN SF_CAUSE_CD IN ('RXCGD', 'RXLIS', 'RXREI') THEN SF_CAUSE_CD END, GROUPER_ID, PROV_CTRCT_ID, SF_PROD_LOB_CD, 
POT_CD, Cov_Month, CASE WHEN RIGHT(rtrim(ltrim(FUND_EXPN_DATE)), 2) = '00' THEN concat(LEFT(rtrim(ltrim(FUND_EXPN_DATE)), 4), replace(RIGHT(rtrim(ltrim(FUND_EXPN_DATE)), 2), '00', '01')) 
ELSE FUND_EXPN_DATE END, CASE WHEN CLMTYP = 'NONRX' AND PROV_TYPE_CD = 'HS' THEN 'PRTA'
WHEN CLMTYP = 'NONRX' AND PROV_TYPE_CD = 'HS' AND CAST(POT_CD AS varchar) 
in ( '1', 'X', 'Z') THEN 'PRTA_IP'
WHEN CLMTYP = 'NONRX' AND PROV_TYPE_CD = 'HS' AND CAST(POT_CD AS varchar) in ('2', 'R', 'W') THEN 'PRTA_OP'
WHEN CLMTYP = 'NONRX' AND PROV_TYPE_CD = 'HS' AND CAST(POT_CD AS varchar) 
NOT IN ('1', '2', 'X', 'Z', 'R', 'W') THEN 'PRTA_Other'
WHEN CLMTYP = 'NONRX' AND PROV_TYPE_CD <> 'HS' THEN 'PRTB' WHEN CLMTYP = 'RX' AND POST_PAY4_CD = 'D' AND SF_CAUSE_CD NOT IN ('RXCGD', 'RXLIS', 'RXREI') 
THEN 'PRTD' WHEN CLMTYP = 'RX' AND POST_PAY4_CD <> 'D' THEN 'RX_PartB' WHEN SF_CAUSE_CD IN ('RXCGD', 'RXLIS', 'RXREI') THEN SF_CAUSE_CD END, LEFT(UMID, 9),
DATEADD(mm, DATEDIFF(mm, 0, PROCESS_DATE_CONV), 0), FUND_TYPE_CD,
case when b.SUB_REGION in ('AMI', 'AMICUS') then 'AMICUS' when b.SUB_REGION in ('CHM', 'CMCM') then 'CCS' when b.SUB_REGION = 'ELITE' then 'ELITE' else b.SUB_REGION end, INCUR_DATE_CONV

update IFM_Temp_Claims_excl
set --FUND_EXPN_DATE = left(trim(fund_expn_date),4) + '01',
Cov_Month = CONVERT(date, CONCAT(Fund_Month, '01'))
--Cov_Month = DATEADD(yyyy,1,Cov_Month)
from IFM_Temp_Claims_excl where right(trim(fund_expn_date),2) = 00


drop table if exists #IFM_Temp_Claims2

CREATE TABLE #IFM_Temp_Claims2(
	[PROV_CTRCT_ID] [varchar](17) NULL,
	[UMID] [varchar](9) NULL,
	[SF_PROD_LOB_CD] [varchar](3) NULL,
	[Product] [varchar](10) NULL,
	[Cov_Month] [date] NULL,
	[Type] [varchar](10) NULL,
	[AMT] [numeric](38, 2) NULL,
	[GROUPER_ID] [varchar](8) NULL
)

truncate table  #IFM_Temp_Claims2
insert INTO  #IFM_Temp_Claims2
SELECT  
IFM_temp_claims1.PROV_CTRCT_ID, 
IFM_temp_claims1.UMID, 
IFM_temp_claims1.SF_PROD_LOB_CD, 
CASE WHEN IFM_temp_claims1.SF_PROD_LOB_CD = 'MER' THEN 'HMO' WHEN IFM_temp_claims1.SF_PROD_LOB_CD = 'MEP' THEN 'PPO' ELSE IFM_temp_claims1.SF_PROD_LOB_CD END,
IFM_temp_claims1.Cov_Month, 
IFM_temp_claims1.Type, 
SUM(IFM_temp_claims1.AMT) AS AMT, 
IFM_temp_claims1.GROUPER_ID
FROM IFM_temp_claims1 
GROUP BY IFM_temp_claims1.PROV_CTRCT_ID, 
IFM_temp_claims1.UMID, 
IFM_temp_claims1.Cov_Month, 
IFM_temp_claims1.Type, 
IFM_temp_claims1.SF_PROD_LOB_CD, 
IFM_temp_claims1.GROUPER_ID

drop table if exists #Claim_MMs
select umid,PROV_CTRCT_ID, Cov_Month
into #Claim_MMs
from #IFM_Temp_Claims2
group by umid, PROV_CTRCT_ID, Cov_Month

drop table if exists #SF_MMS
select memberid, PCPID, cov_month
Into #SF_MMS
from STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
group by memberid, PCPID, cov_month

drop table if exists #Missing_Members
SELECT        cl.UMID, cl.PROV_CTRCT_ID,  cl.Cov_Month
into #Missing_Members
FROM    [#Claim_MMs] AS cl LEFT OUTER JOIN
     [#SF_MMS] AS sf ON cl.UMID = sf.memberID AND cl.Cov_Month = sf.cov_month and cl.PROV_CTRCT_ID = sf.PCPID
WHERE     sf.memberid is null  

insert into STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
(
MemberID,
cov_month,
close_Month,
pcpID,
IPAName,
--memberName,
InsuranceCompany,
ZeroPrem,
Product,
LOB
)
select mis.UMID,  mis.Cov_Month,
@Close_Month,
cl.PROV_CTRCT_ID, GROUPER_ID,
--rtrim(ltrim(mbr_last_name)) + ', ' + rtrim(ltrim(mbr_first_name)) as MemberName,
'Humana',
'Yes',
--CASE WHEN SF_PROD_LOB_CD = 'MER' THEN 'HMO' WHEN SF_PROD_LOB_CD = 'MEP' THEN 'PPO' END as Product,
Product,
SF_PROD_LOB_CD
from #IFM_Temp_Claims2 CL inner join #Missing_Members mis on left(cl.UMID,9) = mis.UMID
and cl.cov_month = mis.Cov_Month
--where right(rtrim(cl.FUND_EXPN_DATE),2) <> 00
--where mis.UMID = 'H76956302'
group by  mis.UMID, mis.cov_month,cl.PROV_CTRCT_ID, GROUPER_ID,
--rtrim(ltrim(mbr_last_name)) + ', ' + rtrim(ltrim(mbr_first_name)),
SF_PROD_LOB_CD,Product

-- missing members company

update SF
set Company = case when bm.SUB_REGION in ('AMI', 'AMICUS') then 'AMICUS' when bm.SUB_REGION in ('CHM', 'CMCM') then 'CCS' when bm.SUB_REGION = 'ELITE' then 'ELITE' else bm.SUB_REGION end
from #BM BM inner join STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite SF on bm.Contract_Key_No_Spaces = replace(sf.PCPID,' ', '') and sf.Cov_Month between bm.EFF_DATE and bm.END_DATE
where Company is null

update STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
set ClaimsPartA_IP = hc.Amt
from #IFM_Temp_Claims2 HC inner join STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite SF on hc.UMID = sf.MemberID and hc.Cov_Month = SF.Cov_Month
and  replace(hc.PROV_CTRCT_ID,' ','') = replace(sf.PCPID,' ','')
where HC.Type = 'PRTA_IP'

update STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
set ClaimsPartA_OP = hc.Amt
from #IFM_Temp_Claims2 HC inner join STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite SF on hc.UMID = sf.MemberID and hc.Cov_Month = SF.Cov_Month
and  replace(hc.PROV_CTRCT_ID,' ','') = replace(sf.PCPID,' ','')
where HC.Type = 'PRTA_OP'

update STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
set ClaimsPartA_Other = hc.Amt
from #IFM_Temp_Claims2 HC inner join STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite SF on hc.UMID = sf.MemberID and hc.Cov_Month = SF.Cov_Month
and  replace(hc.PROV_CTRCT_ID,' ','') = replace(sf.PCPID,' ','')
where HC.Type = 'PRTA_Other'

update STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
set ClaimsPartA = isnull(ClaimsPartA_IP,0)+ isnull(ClaimsPartA_OP,0) + isnull(ClaimsPartA_Other,0)  

update STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
set ClaimsPartB = hc.Amt
from #IFM_Temp_Claims2 HC inner join STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite SF on hc.UMID = sf.MemberID and hc.Cov_Month =sf.Cov_Month and sf.lob = hc.SF_PROD_LOB_CD
and  replace(hc.PROV_CTRCT_ID,' ','') = replace(sf.PCPID,' ','')
where HC.Type = 'PRTB' 

update STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
set [RX_B_Claims] = hc.Amt
from #IFM_Temp_Claims2 HC inner join STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite SF on hc.UMID = sf.MemberID and hc.Cov_Month =sf.Cov_Month and sf.lob = hc.SF_PROD_LOB_CD
and  replace(hc.PROV_CTRCT_ID,' ','') = replace(sf.PCPID,' ','')
where HC.Type = 'RX_PartB' 

update STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
set RX_GDCA =  hc.Amt
from #IFM_Temp_Claims2 HC inner join STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite SF on hc.UMID = sf.MemberID and hc.Cov_Month =sf.Cov_Month and sf.lob = hc.SF_PROD_LOB_CD
and  replace(hc.PROV_CTRCT_ID,' ','') = replace(sf.PCPID,' ','')
where HC.Type = 'RXCGD' 

update STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
set RX_LICS = hc.Amt
from #IFM_Temp_Claims2 HC inner join STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite SF on hc.UMID = sf.MemberID and hc.Cov_Month =sf.Cov_Month and sf.lob = hc.SF_PROD_LOB_CD
and  replace(hc.PROV_CTRCT_ID,' ','') = replace(sf.PCPID,' ','')
where HC.Type = 'RXLIS' 

update STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
set RX_Stoploss = hc.Amt
from #IFM_Temp_Claims2 HC inner join STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite SF on hc.UMID = sf.MemberID and hc.Cov_Month =sf.Cov_Month and sf.lob = hc.SF_PROD_LOB_CD
and  replace(hc.PROV_CTRCT_ID,' ','') = replace(sf.PCPID,' ','')
where HC.Type = 'RXREI' 

update STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
set RX_D_Claims = hc.Amt
from #IFM_Temp_Claims2 HC inner join STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite SF on hc.UMID = sf.MemberID and hc.Cov_Month =sf.Cov_Month and sf.lob = hc.SF_PROD_LOB_CD
and  replace(hc.PROV_CTRCT_ID,' ','') = replace(sf.PCPID,' ','')
where HC.Type = 'PRTD' 


----************************
----Cap
----************************

drop table if exists #IFM_Temp_SpecCap

CREATE TABLE #IFM_Temp_SpecCap(
	[PROVIDER_ID] [varchar](17) NULL,
	[Cov_Month] [date] NULL,
	[SpecCap] [numeric](38, 2) NULL
)


truncate table #IFM_Temp_SpecCap
insert INTO #IFM_Temp_SpecCap
SELECT 
PROVIDER_ID, 
CONVERT(Date, RTRIM(MON_FUN_C) + '01') AS Cov_Month, 
SUM(EXP_CAP_EXP) AS SpecCap
FROM            TranscendAnalytics.dbo.IFM_SF_SPEC_CAP_EXP_OPEN_FUNDING
where fund_type_cd not in  ('excl', 'STLS')
GROUP BY PROVIDER_ID, 
CONVERT(Date, RTRIM(MON_FUN_C) + '01')

drop table if exists #IFM_Temp_mms 

CREATE TABLE #IFM_Temp_mms(
	[pcpid] [varchar](50) NULL,
	[Cov_Month] [date] NOT NULL,
	[MMS] [int] NULL
)

truncate table #IFM_Temp_mms
insert Into #IFM_Temp_mms
select pcpid, Cov_Month, count(Memberid) as MMS
from STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
where ZeroPrem is null
group by  pcpid,Cov_Month

drop table if exists #IFM_Temp_SpecCapPMPM

CREATE TABLE #IFM_Temp_SpecCapPMPM(
	[pcpid] [varchar](50) NULL,
	[Cov_Month] [date] NOT NULL,
	[MMS] [int] NULL,
	[SpecCap] [numeric](38, 2) NULL,
	[SpecCapPMPM] [numeric](38, 6) NULL
)


truncate table #IFM_Temp_SpecCapPMPM

insert into #IFM_Temp_SpecCapPMPM
SELECT #IFM_Temp_mms.pcpid, 
#IFM_Temp_mms.Cov_Month, 
#IFM_Temp_mms.MMS, 
#IFM_Temp_SpecCap.SpecCap, 
#IFM_Temp_SpecCap.SpecCap / #IFM_Temp_mms.MMS AS SpecCapPMPM
FROM  #IFM_Temp_mms INNER JOIN
#IFM_Temp_SpecCap 
 ON #IFM_Temp_mms.pcpid = #IFM_Temp_SpecCap.PROVIDER_ID 
 AND #IFM_Temp_mms.Cov_Month = #IFM_Temp_SpecCap.Cov_Month

UPDATE STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
SET   SpecCap = -#IFM_Temp_SpecCapPMPM.SpecCapPMPM
FROM  STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite INNER JOIN
#IFM_Temp_SpecCapPMPM 
 ON STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite.PCPID = #IFM_Temp_SpecCapPMPM.PCPID 
 AND STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite.Cov_Month = #IFM_Temp_SpecCapPMPM.Cov_Month

----************************
----IBNR
----************************

drop table if exists #IFM_Temp_IBNR

CREATE TABLE #IFM_Temp_IBNR(
	[PROV_CTRCT_ID] [varchar](17) NULL,
	[Cov_Month] [date] NULL,
	[IBNR] [numeric](38, 2) NULL,
	[MAN_ADJ] [numeric](38, 2) NULL
)

TRUNCATE TABLE #IFM_Temp_IBNR

-- I think we need to take out Excluded lines

INSERT INTO #IFM_Temp_IBNR
SELECT        B.PROV_CTRCT_ID, CONVERT(date, CASE WHEN RIGHT(rtrim(ltrim(INCURRED_MTH_NBR)), 2) = '00' THEN concat(LEFT(rtrim(ltrim(MinMonth)), 4), replace(RIGHT(rtrim(ltrim(INCURRED_MTH_NBR)), 2), '00', RIGHT(MinMonth, 2))) 
                         ELSE INCURRED_MTH_NBR END + '01') AS Cov_Month, SUM(B.IBNR_AMT) AS IBNR, SUM(B.MANL_ADJ_AMT) AS MAN_ADJ
FROM            IFM_SF_MTH_BALANCE AS B INNER JOIN
                         [#Temp_Month_Zero_Fix] AS F ON B.PROV_CTRCT_ID = F.PROV_CTRCT_ID AND LEFT(RTRIM(LTRIM(B.INCURRED_MTH_NBR)), 4) = F.YYYY
WHERE        (B.SRC_CHG_CD = 'AFT') AND (B.FUND_TYPE_CD NOT IN ('EXCL', 'STLS')) 
GROUP BY B.PROV_CTRCT_ID, MinMonth, CONVERT(date, CASE WHEN RIGHT(rtrim(ltrim(INCURRED_MTH_NBR)), 2) = '00' THEN
concat(LEFT(rtrim(ltrim(MinMonth)), 4), replace(RIGHT(rtrim(ltrim(INCURRED_MTH_NBR)), 2), '00', 
                         RIGHT(MinMonth, 2))) ELSE INCURRED_MTH_NBR END + '01')

drop table if exists #IFM_Temp_ADJ_IB_PM

CREATE TABLE #IFM_Temp_ADJ_IB_PM(
	[PCPID] [varchar](50) NULL,
	[Cov_Month] [date] NOT NULL,
	[IBNR] [numeric](38, 2) NULL,
	[IBPM] [numeric](38, 6) NULL,
	[MAN_ADJ] [numeric](38, 2) NULL,
	[ADPM] [numeric](38, 6) NULL
) 

TRUNCATE TABLE  #IFM_Temp_ADJ_IB_PM

INSERT into #IFM_Temp_ADJ_IB_PM
select 
mms.PCPID,
mms.Cov_Month, 
b.IBNR,
b.IBNR/mms.MMS as IBPM, 
b.MAN_ADJ, 
b.MAN_ADJ/MMS.MMS as ADPM
from #IFM_Temp_mms mms 
inner join #IFM_Temp_IBNR b
on mms.PCPID = b.PROV_CTRCT_ID 
and mms.Cov_Month = b.Cov_Month

UPDATE STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
SET  Adjustment = #IFM_Temp_ADJ_IB_PM.ADPM,
                IBNR = #IFM_Temp_ADJ_IB_PM.IBPM
FROM  STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite INNER JOIN
#IFM_Temp_ADJ_IB_PM 
 ON STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite.PCPID = #IFM_Temp_ADJ_IB_PM.PCPID 
 AND STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite.Cov_Month = #IFM_Temp_ADJ_IB_PM.Cov_Month

----************************
----STOPLOSS
----************************

drop table if exists #IFM_Temp_Stoploss

CREATE TABLE #IFM_Temp_Stoploss(
	[UMID] [varchar](9) NULL,
	--[FUND_EXPN_DATE] [varchar](8) NULL,
	[Cov_Month] [varchar](8000) NOT NULL,
	[FUND_TYPE_CD] [varchar](4) NULL,
	[CLM_EXPN_AMT] [float] NULL,
	[GROUPER_ID] [varchar](8) NULL
)

TRUNCATE TABLE #IFM_Temp_Stoploss
INSERT INTO #IFM_Temp_Stoploss
SELECT 
left(UMID,9) as UMID ,
--FUND_EXPN_DATE,
case when right(rtrim(ltrim(FUND_EXPN_DATE)),2) = '00' then
concat(concat(left(rtrim(ltrim(FUND_EXPN_DATE)),4), replace(right(rtrim(ltrim(FUND_EXPN_DATE)),2),'00','01')),'01')
else concat(rtrim(ltrim(FUND_EXPN_DATE)),'01') end as Cov_Month,
FUND_TYPE_CD, SUM(cast(CLM_EXPN_AMT as float)) AS CLM_EXPN_AMT,
GROUPER_ID
FROM TranscendAnalytics.dbo.IFM_SF_MTH_CLAIMS_LINES
WHERE Rtrim(Ltrim(FUND_EXPN_DATE)) <> '000000'
GROUP BY UMID, FUND_TYPE_CD, 
--FUND_EXPN_DATE,
case when right(rtrim(ltrim(FUND_EXPN_DATE)),2) = '00' then
concat(concat(left(rtrim(ltrim(FUND_EXPN_DATE)),4), replace(right(rtrim(ltrim(FUND_EXPN_DATE)),2),'00','01')),'01')
else concat(rtrim(ltrim(FUND_EXPN_DATE)),'01') end,
GROUPER_ID
HAVING        (FUND_TYPE_CD = 'stls') 

update STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
set ReinRecoveries = HC.CLM_EXPN_AMT
from #IFM_Temp_Stoploss HC 
inner join STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite SF 
on hc.UMID = sf.MemberID 
and cast(hc.Cov_Month as date) = sf.Cov_Month

declare @ThreeMonthDelete as date

set @ThreeMonthDelete =
(select  
dateadd("M", -2, max(case when right(rtrim(ltrim(INCURRED_MTH_NBR)),2) = '00' then
concat(concat(left(rtrim(ltrim(INCURRED_MTH_NBR)),4), replace(right(rtrim(ltrim(INCURRED_MTH_NBR)),2),'00','01')),'01')
else concat(rtrim(ltrim(INCURRED_MTH_NBR)),'01') end))
FROM  TranscendAnalytics.dbo.IFM_SF_MTH_BALANCE
WHERE (SRC_CHG_CD = 'AFT') and FUND_TYPE_CD = 'STLS' )

drop table if exists #IFM_Temp_Humana_IBNR_STLS

CREATE TABLE #IFM_Temp_Humana_IBNR_STLS(
	[INCURRED_MTH_NBR] [varchar](6) NULL,
	[Cov_Month] Date NULL,
	[IBNR] [numeric](38, 2) NULL,
	[MAN_ADJ] [numeric](38, 2) NULL,
	[grouper_id] [varchar](8) NULL,
	[PROV_CTRCT_ID] [varchar](17) NULL,
	[MMs] [numeric](38, 0) NULL
) 

TRUNCATE TABLE #IFM_Temp_Humana_IBNR_STLS

INSERT INTO #IFM_Temp_Humana_IBNR_STLS
SELECT 
INCURRED_MTH_NBR, 
case when right(rtrim(ltrim(INCURRED_MTH_NBR)),2) = '00' then
concat(concat(left(rtrim(ltrim(INCURRED_MTH_NBR)),4), replace(right(rtrim(ltrim(INCURRED_MTH_NBR)),2),'00','01')),'01')
else concat(rtrim(ltrim(INCURRED_MTH_NBR)),'01') end as Cov_Month,
SUM(IBNR_amt) AS IBNR, 
SUM(MANL_ADJ_AMT) AS MAN_ADJ, 
grouper_id, 
PROV_CTRCT_ID, 
sum(MBR_FULL_MTH_CNT) as MMs
FROM  TranscendAnalytics.dbo.IFM_SF_MTH_BALANCE
WHERE (SRC_CHG_CD = 'AFT') and FUND_TYPE_CD = 'STLS' 
GROUP BY INCURRED_MTH_NBR, GROUPER_ID, PROV_CTRCT_ID

DROP table if exists #Temp_STLS_MMS

select MemberID, Year(Cov_Month) as Cov_Year , PCPID, Count(MemberID) as MMs, sum(ReinRecoveries) as ReinRecoveries
into #Temp_STLS_MMS
from STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
where cast(reinrecoveries as float) is not null
and abs(cast(reinrecoveries as float)) > 0
group by MemberID, Year(Cov_Month), PCPID 

drop table if exists #Temp_STLS_MMS2

select MM.MemberID, Cov_Month, MM.PCPID
into #Temp_STLS_MMS2
from #Temp_STLS_MMS MM inner join STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite SF	
on MM.MemberID = SF.MemberID and MM.Cov_Year =  Year(SF.Cov_Month)
--where mm.PCPID = '000104243  PCP310'

drop table if exists #Temp_STLS_MMS3

select PCPID, Cov_Month, Count(MemberID) as MMs
Into #Temp_STLS_MMS3
from #Temp_STLS_MMS2
--where PCPID = '000104243  PCP310'
group by PCPID, Cov_Month
order by Cov_Month

drop table if exists #IFM_Temp_Humana_STLS_IBNR_PMPM

CREATE TABLE #IFM_Temp_Humana_STLS_IBNR_PMPM(
	[GROUPER_ID] [varchar](8) NULL,
	[PROV_CTRCT_ID] [varchar](17) NULL,
	[INCURRED_MTH_NBR] [varchar](6) NULL,
	[Cov_Month] [date] NULL,
	[IBNR] [numeric](38, 2) NULL,
	[mms] [numeric](38, 0) NULL,
	[PMPM] [numeric](38, 6) NULL
)

TRUNCATE TABLE  #IFM_Temp_Humana_STLS_IBNR_PMPM

INSERT into #IFM_Temp_Humana_STLS_IBNR_PMPM
select GROUPER_ID, PROV_CTRCT_ID, INCURRED_MTH_NBR, M.Cov_Month, IBNR, M.MMs, IBNR / M.MMs as PMPM
from #IFM_Temp_Humana_IBNR_STLS S inner join #Temp_STLS_MMS3 M
on S.PROV_CTRCT_ID = M.PCPID and S.Cov_Month = M.Cov_Month	
where ABS(cast(ibnr as float)) > 0
and S.Cov_Month < @ThreeMonthDelete

-- add STLS IBNR To Recoveries
-- not adding to recoveried any more any more per finance 4/12/2024

update SF
set --ReinRecoveries = isnull(SF.ReinRecoveries,0) - HC.PMPM,
Humana_STLS_IBNR = -HC.PMPM
from #IFM_Temp_Humana_STLS_IBNR_PMPM HC inner join STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite SF on hc.INCURRED_MTH_NBR =LEFT(CONVERT(varchar,sf.Cov_Month, 112), 6)
and hc.PROV_CTRCT_ID = sf.PCPID
inner join #Temp_STLS_MMS2 MM on SF.MemberID = MM.MemberID and SF.Cov_Month = MM.Cov_Month

drop table if exists #IFM_Temp_Humana_STLS_IBNR_PMPM_2

CREATE TABLE #IFM_Temp_Humana_STLS_IBNR_PMPM_2(
	[GROUPER_ID] [varchar](8) NULL,
	[PROV_CTRCT_ID] [varchar](17) NULL,
	[INCURRED_MTH_NBR] [varchar](6) NULL,
	[Cov_Month] [date] NULL,
	[IBNR] [numeric](38, 2) NULL,
	[mms] [numeric](38, 0) NULL,
	[PMPM] [numeric](38, 6) NULL
)

TRUNCATE TABLE  #IFM_Temp_Humana_STLS_IBNR_PMPM_2

INSERT into #IFM_Temp_Humana_STLS_IBNR_PMPM_2
select GROUPER_ID, PROV_CTRCT_ID, INCURRED_MTH_NBR, Cov_Month, IBNR, mms, IBNR / MMs as PMPM
from #IFM_Temp_Humana_IBNR_STLS 
where mms <> 0
and Cov_Month >= @ThreeMonthDelete

-- add STLS IBNR To Recoveries
-- not doing any more per finance 4/12/2024

update SF
set --ReinRecoveries = isnull(SF.ReinRecoveries,0) - HC.PMPM,
Humana_STLS_IBNR = -HC.PMPM
from #IFM_Temp_Humana_STLS_IBNR_PMPM_2 HC 
inner join STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite SF
on hc.Cov_Month =sf.Cov_Month
and hc.PROV_CTRCT_ID = sf.PCPID

drop table if exists #IFM_Temp_Humana_STLS_ADJ_PMPM

CREATE TABLE #IFM_Temp_Humana_STLS_ADJ_PMPM(
	[GROUPER_ID] [varchar](8) NULL,
	[PROV_CTRCT_ID] [varchar](17) NULL,
	[INCURRED_MTH_NBR] [varchar](6) NULL,
	[ADJ] [numeric](38, 2) NULL,
	[mms] [numeric](38, 0) NULL,
	[PMPM] [numeric](38, 6) NULL
)

TRUNCATE TABLE  #IFM_Temp_Humana_STLS_ADJ_PMPM


INSERT INTO #IFM_Temp_Humana_STLS_ADJ_PMPM
select GROUPER_ID, PROV_CTRCT_ID, INCURRED_MTH_NBR, MAN_ADJ, mms, MAN_ADJ / MMs as PMPM
from #IFM_Temp_Humana_IBNR_STLS
where MMs <> 0

-- no longer putting Adj into recoveries

--update STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
--set ReinRecoveries = isnull(ReinRecoveries,0) - HC.PMPM
--from #IFM_Temp_Humana_STLS_ADJ_PMPM HC inner join STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite SF on hc.INCURRED_MTH_NBR =LEFT(CONVERT(varchar,sf.Cov_Month, 112), 6)
--and hc.GROUPER_ID = sf.IPAName
--and hc.PROV_CTRCT_ID = sf.PCPID

drop table if exists #IFM_Temp_SpecCap_STLS

CREATE TABLE #IFM_Temp_SpecCap_STLS(
	[PROVIDER_ID] [varchar](17) NULL,
	[Cov_Month] [date] NULL,
	[SpecCap] [numeric](38, 2) NULL
)


truncate table #IFM_Temp_SpecCap_STLS
insert INTO #IFM_Temp_SpecCap_STLS
SELECT 
PROVIDER_ID, 
CONVERT(Date, RTRIM(MON_FUN_C) + '01') AS Cov_Month, 
SUM(EXP_CAP_EXP) AS SpecCap
FROM            TranscendAnalytics.dbo.IFM_SF_SPEC_CAP_EXP_OPEN_FUNDING
where fund_type_cd = 'STLS'
GROUP BY PROVIDER_ID, 
CONVERT(Date, RTRIM(MON_FUN_C) + '01')

drop table if exists #IFM_Temp_SpecCapPMPM_STLS

CREATE TABLE #IFM_Temp_SpecCapPMPM_STLS(
	[pcpid] [varchar](50) NULL,
	[Cov_Month] [date] NOT NULL,
	[MMS] [int] NULL,
	[SpecCap] [numeric](38, 2) NULL,
	[SpecCapPMPM] [numeric](38, 6) NULL
)

truncate table #IFM_Temp_SpecCapPMPM_STLS

insert into #IFM_Temp_SpecCapPMPM_STLS
SELECT #IFM_Temp_mms.pcpid, 
#IFM_Temp_mms.Cov_Month, 
#IFM_Temp_mms.MMS, 
#IFM_Temp_SpecCap_STLS.SpecCap, 
#IFM_Temp_SpecCap_STLS.SpecCap / #IFM_Temp_mms.MMS AS SpecCapPMPM
FROM  #IFM_Temp_mms INNER JOIN
#IFM_Temp_SpecCap_STLS 
 ON #IFM_Temp_mms.pcpid = #IFM_Temp_SpecCap_STLS.PROVIDER_ID 
 AND #IFM_Temp_mms.Cov_Month = #IFM_Temp_SpecCap_STLS.Cov_Month

-- no longer putting Spec Cap in Recoveries

-- update SF
--set ReinRecoveries = isnull(SF.ReinRecoveries,0) - HC.SpecCapPMPM
--from #IFM_Temp_SpecCapPMPM_STLS HC inner join STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite SF on hc.Cov_Month= sf.Cov_Month
--and hc.pcpid = sf.PCPID

----************************
----IDS
----************************

drop table if exists #IFM_Temp_Alt_IDs

CREATE TABLE #IFM_Temp_Alt_IDs(
	[memberid] [varchar](15) NOT NULL,
	[MEDICARE_ID] [varchar](30) NULL,
	[SRC_ALT_MBR_ID] [varchar](11) NULL,
	[MBR_PROV_EFF_CYMD_DATE] [varchar](8) NULL,
	[MBR_PROV_END_CYMD_DATE] [varchar](8) NULL,
	[Cov_Month] [date] NOT NULL,
	[FundMth] [char](6) NULL,
	[GROUPER_ID] [varchar](8) NULL,
	[PROD_LOB_CD] [varchar](3) NULL
)

TRUNCATE TABLE #IFM_Temp_Alt_IDs

INSERT INTO #IFM_Temp_Alt_IDs
SELECT   
sf.memberid, 
ELG.MEDICARE_ID, 
ELG.SRC_ALT_MBR_ID, 
ELG.MBR_PROV_EFF_CYMD_DATE, 
ELG.MBR_PROV_END_CYMD_DATE, 
Cov_Month, 
CONVERT(char(6), Cov_Month, 112) AS FundMth, 
ELG.GROUPER_ID,
elg.PROD_LOB_CD
FROM  STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite AS SF INNER JOIN
TranscendAnalytics.dbo.IFM_SF_DLY_MEMBER_PCP_ELIG_HIST AS ELG 
on left(ELG.UMID,9) = SF.MemberID
AND Cast(ELG.MBR_PROV_EFF_CYMD_DATE as date) <= SF.Cov_Month 
AND cast(ELG.MBR_PROV_END_CYMD_DATE as date) >= SF.Cov_Month 
and replace(ELG.SRC_CTRCT_ID,' ','') = replace(SF.PCPID,' ','')
and ELG.PROD_LOB_CD = SF.LOB

UPDATE       STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
SET                MCARE_ID = #IFM_Temp_Alt_IDs.medicare_ID
from STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
INNER JOIN                         #IFM_Temp_Alt_IDs ON STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite.MemberID = #IFM_Temp_Alt_IDs.memberid
AND STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite.Cov_Month = #IFM_Temp_Alt_IDs.Cov_Month
 where MCARE_ID is null
 and Company in ('CCS', 'Amicus', 'Elite')

----************************
----SNP Funding
----************************

drop table if exists #IFM_Temp_SNPFunding

CREATE TABLE #IFM_Temp_SNPFunding(
	[MemberID] [varchar](15) NOT NULL,
	[Cov_Month] [date] NOT NULL,
	[SNPFunding] [numeric](38, 2) NULL,
	[GROUPER_ID] [varchar](8) NULL,
	[prov_ctrct_ID] [varchar](17) NULL,
	[prod_lob_cd] [varchar](5) NULL,
	[LOB] [varchar](5) NULL,
	[Product] [varchar](10) NULL

)

TRUNCATE TABLE #IFM_Temp_SNPFunding
INSERT INTO #IFM_Temp_SNPFunding
select 
MemberID, 
Cov_Month, 
sum(MAN_ADJ_AMT) as SNPFunding, 
ids.GROUPER_ID, 
prov_ctrct_ID,
Adj.PROD_LOB_CD,
Adj.PROD_LOB_CD as LOB,
case when adj.PROD_LOB_CD = 'MER' then 'HMO' when adj.PROD_LOB_CD = 'MEP' then 'PPO' else adj.PROD_LOB_CD end as Product
from #IFM_Temp_Alt_IDs IDs 
inner join TranscendAnalytics.dbo.IFM_SF_MANUAL_ADJUSTMENTS_OPEN_FUNDING ADJ on IDs.SRC_ALT_MBR_ID = adj.MEMBER_ID+'00'
and ids.FundMth = adj.FUND_MTHYM and ids.GROUPER_ID = adj.GRPR_ID 
where ADJ_REA_CD = '967'  
--and FUND_TY_CD <> 'EXCL'
group by 
MemberID, 
Cov_Month,
GROUPER_ID, 
prov_ctrct_ID,
adj.PROD_LOB_CD

update STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
set Humana_SNP_Funding = hc.SNPFunding
from #IFM_Temp_SNPFunding HC 
inner join STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite SF 
on hc.MemberID = sf.MemberID 
and hc.Cov_Month =sf.Cov_Month 
and hc.LOB = sf.LOB
and replace(hc.prov_ctrct_ID, ' ' , '') = replace(sf.PCPID,' ' ,'')

update STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
set ProviderTotalFunding = isnull(ProviderTotalFunding,0) + isnull(Humana_SNP_Funding,0)

----************************
----RX REBATES
----************************

drop table if exists #IFM_Temp_Rebates

CREATE TABLE #IFM_Temp_Rebates(
	[MemberID] [varchar](15) NOT NULL,
	[Cov_Month] [date] NOT NULL,
	[RX_Rebates] [numeric](38, 2) NULL,
	[GROUPER_ID] [varchar](8) NULL,
	[prov_ctrct_ID] [varchar](17) NULL,
	[prod_lob_cd] [varchar](5) NULL,
	[LOB] [varchar](5) NULL,
	[Product] [varchar](10) NULL

)

TRUNCATE TABLE #IFM_Temp_Rebates
INSERT INTO #IFM_Temp_Rebates
select 
MemberID, 
Cov_Month, 
sum(MAN_ADJ_AMT) as RX_Rebates, 
ids.GROUPER_ID, 
prov_ctrct_ID,
Adj.PROD_LOB_CD,
Adj.PROD_LOB_CD as LOB,
case when adj.PROD_LOB_CD = 'MER' then 'HMO' when adj.PROD_LOB_CD = 'MEP' then 'PPO' else adj.PROD_LOB_CD end as Product
from #IFM_Temp_Alt_IDs IDs 
inner join TranscendAnalytics.dbo.IFM_SF_MANUAL_ADJUSTMENTS_OPEN_FUNDING ADJ on IDs.SRC_ALT_MBR_ID = adj.MEMBER_ID+'00'
and ids.FundMth = adj.FUND_MTHYM and ids.GROUPER_ID = adj.GRPR_ID 
where ADJ_REA_CD = '888'  
and FUND_TY_CD not in ('EXCL', 'STLS')
group by 
MemberID, 
Cov_Month,
GROUPER_ID, 
prov_ctrct_ID,
adj.PROD_LOB_CD

update STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
set RX_Rebates = -hc.RX_Rebates
from #IFM_Temp_Rebates HC 
inner join STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite SF 
on hc.MemberID = sf.MemberID 
and hc.Cov_Month =sf.Cov_Month 
and hc.LOB = sf.LOB
and replace(hc.prov_ctrct_ID, ' ' , '') = replace(sf.PCPID,' ' ,'')

----************************
----RX Quality
----************************

drop table if exists #IFM_Temp_RX_Quality

CREATE TABLE #IFM_Temp_RX_Quality(
	[PROV_CTRCT_ID] [varchar](17) NULL,
	[FUND_MTHYM] [varchar](6) NULL,
	[Cov_Montth] [date] NULL,
	[MAN_ADJ_AMT] [numeric](38, 2) NULL,
	[GRPR_ID] [varchar](8) NULL,
	[PROD_LOB_CD] [varchar](5) NULL,
	[LOB] [varchar](5) NULL
)

TRUNCATE TABLE #IFM_Temp_RX_Quality

INSERT INTO #IFM_Temp_RX_Quality
SELECT
PROV_CTRCT_ID, 
FUND_MTHYM, 
CONVERT(date, FUND_MTHYM + '01') AS Cov_Montth, 
SUM(MAN_ADJ_AMT) AS MAN_ADJ_AMT, 
GRPR_ID, 
PROD_LOB_CD, 
CASE WHEN PROD_LOB_CD = 'MER' THEN 'HMO' WHEN PROD_LOB_CD = 'MEP' THEN 'PPO' ELSE PROD_LOB_CD END AS LOB
FROM TranscendAnalytics.dbo.IFM_SF_MANUAL_ADJUSTMENTS_OPEN_FUNDING AS ADJ
WHERE     (ADJ_REA_CD IN ('889', '890')) 
and FUND_TY_CD not in ('EXCL', 'STLS')
GROUP BY PROV_CTRCT_ID, FUND_MTHYM, CONVERT(date, FUND_MTHYM + '01'), 
GRPR_ID, 
PROD_LOB_CD

drop table if exists #IFM_Temp_RX_Quality2

CREATE TABLE #IFM_Temp_RX_Quality2(
	[PROV_CTRCT_ID] [varchar](17) NULL,
	[FUND_MTHYM] [varchar](6) NULL,
	[Cov_Montth] [date] NULL,
	[MAN_ADJ_AMT] [numeric](38, 2) NULL,
	[GRPR_ID] [varchar](8) NULL,
	[PROD_LOB_CD] [varchar](5) NULL,
	[LOB] [varchar](5) NULL,
	[pcpid] [varchar](50) NULL,
	[Cov_Month] [date] NOT NULL,
	[MMS] [int] NULL,
	[PMPM] [numeric](38, 6) NULL
)

TRUNCATE TABLE #IFM_Temp_RX_Quality2

INSERT INTO #IFM_Temp_RX_Quality2
select * , MAN_ADJ_AMT / MMs as PMPM 
from #IFM_Temp_RX_Quality Qual 
inner join #IFM_Temp_mms MMs 
on Qual.PROV_CTRCT_ID = MMs.PCPID 
and qual.Cov_Montth = mms.Cov_Month

update STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
set RX_Quality = -hc.PMPM
from #IFM_Temp_RX_Quality2 HC 
inner join STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite SF 
on replace(hc.prov_ctrct_ID, ' ' , '') = replace(sf.PCPID,' ' ,'')
and hc.Cov_Month =sf.Cov_Month 

update STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
set Adjustment = isnull(Adjustment,0) + isnull(RX_Quality,0) + isnull(RX_Rebates,0) - isnull(Humana_SNP_Funding,0)

-- adding this line on 20221006 to flip the adj + / - sign

update STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
set Adjustment = Adjustment * -1

-- adding this line on 20221006 to flip the adj + / - sign

update STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
set IBNR = IBNR * -1

--ROLL UP THE PART D EXPENSE

update STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
set RX_D__EXP = isnull(RX_D_Claims,0)
+ isnull(RX_GDCA,0) + isnull(RX_LICS,0) +  isnull(RX_Stoploss,0)
+ isnull(RX_Quality,0) + isnull(RX_Rebates,0)

----************************
----RISK SCORES
----************************

drop table if exists #IFM_Temp_risk

CREATE TABLE #IFM_Temp_risk(
	[IDCARD_MBR_ID] [varchar](9) NULL,
	[MCARE_ID] [varchar](12) NULL,
	[INCURRED_MTH_NBR] [varchar](6) NULL,
	[Cov_Month] [date] NULL,
	[PRTB_HCC_RSK_SCR] [numeric](7, 4) NULL,
	[HOSPICE_IND] [varchar](1) NULL,
	[ESRD_IND] [varchar](1) NULL
)

TRUNCATE TABLE #IFM_Temp_risk

INSERT INTO  #IFM_Temp_risk
SELECT left(IDCARD_MBR_ID,9) as IDCARD_MBR_ID, 
MCARE_ID, 
INCURRED_MTH_NBR, 
CONVERT(date, INCURRED_MTH_NBR + '01') AS Cov_Month, PRTB_HCC_RSK_SCR, HOSPICE_IND, ESRD_IND
FROM  TranscendAnalytics.dbo.IFM_SF_MTH_PREM_CMS_MATCHED

update sf
set MCARE_ID = r.MCARE_ID,
RiskScoreC = r.PRTB_HCC_RSK_SCR,
Hospice = r.HOSPICE_IND,
ESRD = r.ESRD_IND
from STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite sf inner join 
#IFM_Temp_risk R on sf.MemberID = r.IDCARD_MBR_ID and sf.Cov_Month = r.Cov_Month
                               
UPDATE STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite 
SET  ProductType = Prod.Product_Type
FROM  STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite sf INNER JOIN
   dbo.Industry_Product AS Prod 
   ON sf.PBP = Prod.PBP 
   AND sf.Contract = Prod.Contract_Number 
   AND sf.Product = Prod.Plan_type

update STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
set CurrentMember = 'Y'
FROM            [#BM] AS org INNER JOIN
                         STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite ON REPLACE(org.PROVIDER_ID, ' ', '') = REPLACE(STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite.PCPID, ' ', '') 
						 AND STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite.Cov_Month >= ORG.EFF_DATE and STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite.Cov_Month <= org.END_DATE

UPDATE       STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
SET TotalClaims = isnull(ClaimsPartA,0) + Isnull(ClaimsPartB,0) + isnull(RX_B_Claims,0) + isnull(RX_D_Claims,0)
from STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite

drop table if exists #IFM_Temp_EXCL

select UMID, PROV_CTRCT_ID, REPLACE(PROV_CTRCT_ID,' ', '') as PCPID, Cov_Month,
CASE WHEN SF_PROD_LOB_CD = 'MER' THEN 'HMO' WHEN SF_PROD_LOB_CD = 'MEP' THEN 'PPO' ELSE SF_PROD_LOB_CD END AS Product,
sum(cast(amt as float)) as AMT
into #IFM_Temp_EXCL
from IFM_temp_claims_excl
where FUND_TYPE_CD = 'EXCL'
group by UMID, PROV_CTRCT_ID, REPLACE(PROV_CTRCT_ID,' ', ''), Cov_Month,
CASE WHEN SF_PROD_LOB_CD = 'MER' THEN 'HMO' WHEN SF_PROD_LOB_CD = 'MEP' THEN 'PPO' ELSE SF_PROD_LOB_CD END

update STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
set  Humana_EXCL_Claims = hc.Amt
from #IFM_Temp_EXCL HC inner join STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite SF on hc.UMID = sf.MemberID and hc.Cov_Month = SF.Cov_Month and hc.Product = sf.Product

--update STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
--set  Humana_EXCL_Claims = hc.Amt
--from #IFM_Temp_EXCL HC inner join STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite SF on hc.UMID = sf.MemberID and hc.Cov_Month = SF.Cov_Month and hc.Product = sf.Product


update STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
set Net = 
cast(isnull(ProviderTotalFunding,0) as float) -
(cast(isnull(ClaimsPartA,0) as float) +
cast(isnull(ClaimsPartB,0) as float) +
cast(isnull(RX_B_Claims,0) as float) +
cast(isnull(RX_D_Claims,0) as float) +
cast(isnull(IBNR,0) as float) +
cast(isnull(SpecCap,0) as float) +
cast(isnull(StopLossFee,0) as float) - 
cast(isnull(ReinRecoveries,0) as float) +
cast(isnull(Adjustment,0) as float) +
cast(isnull(RX_Stoploss,0) as float) +
cast(isnull(RX_Rebates,0) as float) +
cast(isnull(RX_LICS,0) as float) +
cast(isnull(RX_Quality,0) as float) +
cast(isnull(RX_GDCA,0) as float) +
cast(isnull(RX_REP_GAP_DSCNT,0) as float)
)
from STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite

update STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
set Tot_Exp = 
(cast(isnull(ClaimsPartA,0) as float) +
cast(isnull(ClaimsPartB,0) as float) +
cast(isnull(RX_B_Claims,0) as float) +
cast(isnull(RX_D_Claims,0) as float) +
cast(isnull(IBNR,0) as float) +
cast(isnull(SpecCap,0) as float) +
cast(isnull(StopLossFee,0) as float) - 
cast(isnull(ReinRecoveries,0) as float) +
cast(isnull(Adjustment,0) as float) +
cast(isnull(RX_Stoploss,0) as float) +
cast(isnull(RX_Rebates,0) as float) +
cast(isnull(RX_LICS,0) as float) +
cast(isnull(RX_Quality,0) as float) +
cast(isnull(RX_GDCA,0) as float) +
cast(isnull(RX_REP_GAP_DSCNT,0) as float)
)
from STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite

					 						 
delete from STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite where ZeroPrem is not null

-- change signs 4/25/2023 for Part D Credits to align with all other payers - Jody
-- Doing it after all else  done to no blow up everything that was previously working.

update STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
set RX_Stoploss = -1 * cast(isnull(RX_Stoploss,0) as float) 
, RX_Rebates = -1 * cast(isnull(RX_Rebates,0) as float) 
, RX_LICS = -1 * cast(isnull(RX_LICS,0) as float) 
, RX_Quality = -1 * cast(isnull(RX_Quality,0) as float) 
, RX_GDCA = -1 * cast(isnull(RX_GDCA,0) as float) 
, RX_REP_GAP_DSCNT = -1 * cast(isnull(RX_REP_GAP_DSCNT,0) as float)
from STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite

--  triangle

delete from STG.CLM_TRIANGLE_CCS_POT where PAYER = 'Humana'


INSERT INTO STG.CLM_TRIANGLE_CCS_POT
(PAYER, COV_MONTH, PAID_MONTH, PAID_AMT, CLAIM_CLASS,  UPDATE_DATE, --Company,
PRODUCT, PCP_ID, POT_CD, TAXONOMY)
SELECT 'Humana' AS Payer, C.Cov_Month,  DATEADD(mm, DATEDIFF(mm, 0, PROCESS_DATE_CONV), 0) AS Paid_Month, AMT AS Paid_Amt, 
case when Type = 'PRTA_IP' then 'PARTA'
	 when Type = 'PRTA_OP' then 'PARTA'
	 when Type = 'PRTA_Other' then 'PARTA'
	 when Type = 'PRTB' then 'PARTB'
	 else Type end as Claim_Class, 
GETDATE() AS Update_Date, --'CCS' AS Company,
case when SF_PROD_LOB_CD = 'MER' then 'HMO' WHEN SF_PROD_LOB_CD = 'MEP' THEN 'PPO' ELSE SF_PROD_LOB_CD END  as Product,
Contract_Key_No_Spaces, POT_CD,
CASE WHEN Type = 'PRTA_IP' THEN 'Hospital Inpatient' WHEN Type = 'PRTA_OP' THEN 'Hospital Outpatient' WHEN Type = 'PRTA_Other' THEN 'Other' WHEN Type = 'RX_PartB' THEN 'RX_B' WHEN Type = 'PRTD' THEN
'RX_D' WHEN Type = 'PRTB' THEN 'Physician' ELSE Type END AS Taxonomy
FROM IFM_temp_claims1 C inner join STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite S
on C.UMID = s.MemberID and C.PROV_CTRCT_ID = S.PCPID and C.Cov_Month = S.Cov_Month


UPDATE       STG.CLM_TRIANGLE_CCS_POT
SET                Facility_Name = sf.OfficeName, CLOSE_MONTH = sf.Close_Month, UPDATE_DATE = GETDATE(), Company = sf.Company
FROM            
(select InsuranceCompany, PCPID, OfficeName, Close_Month, Cov_Month, Product, Company from STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite
group by InsuranceCompany, PCPID, OfficeName, Close_Month, Cov_Month, Product, Company)
AS sf INNER JOIN
                         STG.CLM_TRIANGLE_CCS_POT ON sf.InsuranceCompany = STG.CLM_TRIANGLE_CCS_POT.PAYER AND replace(sf.PCPID, ' ' ,'') = STG.CLM_TRIANGLE_CCS_POT.PCP_ID AND 
                         sf.Cov_Month = STG.CLM_TRIANGLE_CCS_POT.COV_MONTH AND sf.Product = STG.CLM_TRIANGLE_CCS_POT.PRODUCT
where PAYER = 'Humana'


delete  from STG.CLM_TRIANGLE_CCS_POT where facility_name is null

delete  from STG.CLM_TRIANGLE_CCS_POT where TAXONOMY
not in (
'Hospital Inpatient', 'Hospital Outpatient',	'Other', 'Physician'
)

-- add 2020 closed months to the triangle and 2021 as of July 2023

INSERT INTO STG.CLM_TRIANGLE_CCS_POT
                         (PAYER, COV_MONTH, PAID_MONTH, PAID_AMT, CLAIM_CLASS, CLOSE_MONTH, UPDATE_DATE, Company, PRODUCT, PCP_ID, Facility_Name, POT_CD, POT_CD_DESC, TAXONOMY)
SELECT        PAYER, COV_MONTH, PAID_MONTH, PAID_AMT, CLAIM_CLASS, @Close_Month AS Expr1, GETDATE() AS Expr2, Company, PRODUCT, PCP_ID, Facility_Name, POT_CD, POT_CD_DESC, TAXONOMY
FROM            STG.CLM_TRIANGLE_CCS_POT_2020_Archive

-- Admit Triangle

drop table if exists #Admit_Humana_Claims

SELECT --top(10)
left(c.UMID,9) as UMID,
'Humana' AS Payer, C.Cov_Month,  Min(DATEADD(mm, DATEDIFF(mm, 0, PROCESS_DATE_CONV), 0)) AS Paid_Month, Sum(cast(AMT as float)) AS Paid_Amt, 
case when Type = 'PRTA_IP' then 'PARTA'
	 when Type = 'PRTA_OP' then 'PARTA'
	 when Type = 'PRTA_Other' then 'PARTA'
	 when Type = 'PRTB' then 'PARTB'
	 else Type end as Claim_Class, 
GETDATE() AS Update_Date, --'CCS' AS Company,
case when SF_PROD_LOB_CD = 'MER' then 'HMO' WHEN SF_PROD_LOB_CD = 'MEP' THEN 'PPO' ELSE SF_PROD_LOB_CD END  as Product,
Contract_Key_No_Spaces, POT_CD,
CASE WHEN Type = 'PRTA_IP' THEN 'Hospital Inpatient' WHEN Type = 'PRTA_OP' THEN 'Hospital Outpatient' WHEN Type = 'PRTA_Other' THEN 'Other' WHEN Type = 'RX_PartB' THEN 'RX_B' WHEN Type = 'PRTD' THEN
'RX_D' WHEN Type = 'PRTB' THEN 'Physician' ELSE Type END AS Taxonomy, 
c.PROV_CTRCT_ID, src_claim_nbr,
s.Company, s.Close_Month, s.PCPID, s.OfficeName
into #Admit_Humana_Claims
FROM IFM_Temp_Claims1 C inner join STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite S
on C.UMID = s.MemberID and C.PROV_CTRCT_ID = S.PCPID and C.Cov_Month = S.Cov_Month
where C.clmtyp = 'NONRX'
group by 
C.Cov_Month, UMID, Contract_Key_No_Spaces, PROV_CTRCT_ID, SRC_CLAIM_NBR, Type, SF_PROD_LOB_CD, POT_CD,
s.Company, s.Close_Month, s.PCPID, s.OfficeName

--select distinct company from #Admit_Humana_Claims

drop table if exists #Admit_Count_Triangle

CREATE TABLE #Admit_Count_Triangle(
	[PAYER] [varchar](8) NOT NULL,
	[COV_MONTH] [datetime] NULL,
	[PAID_MONTH] [datetime] NULL,
	[PAID_AMT] [float] NULL,
	[CLAIM_CLASS] [varchar](20) NOT NULL,
	[CLOSE_MONTH] [datetime] NULL,
	[UPDATE_DATE] [datetime] NULL,
	[Company] [varchar](50) NULL,
	[PRODUCT] [varchar](50) NULL,
	[PCP_ID] [varchar](50) NULL,
	[Facility_Name] [varchar](250) NULL,
	[POT_CD] [varchar](5) NULL,
	[POT_CD_DESC] [varchar](100) NULL,
	[TAXONOMY] [varchar](25) NULL,
	[SRC_CLAIM_NBR] [varchar](25) NULL,
	[UMID] [varchar](11) NULL,
)

INSERT INTO #Admit_Count_Triangle
                        (PAYER, COV_MONTH, PAID_MONTH, PAID_AMT, CLAIM_CLASS, CLOSE_MONTH, UPDATE_DATE, Company, product, PCP_ID, Facility_Name,
						POT_CD, taxonomy, SRC_CLAIM_NBR , UMID)
SELECT        'Humana' AS Expr1, CL.Cov_Month, Paid_Month, SUM(CL.Paid_Amt) AS Paid_AMT, CL.Claim_Class, CL.close_month, getdate(),
org.SUB_Region, cl.Product,CL.PROV_CTRCT_ID,  cl.OfficeName,
	 cl.POT_CD, cl.Taxonomy, cl.SRC_CLAIM_NBR, UMID
FROM            #Admit_Humana_Claims CL JOIN
                         #BM as ORG ON (ORG.PROVIDER_ID = trim(substring(CL.PROV_CTRCT_ID,1,10))
										 or ORG.PROVIDER_ID = trim(CL.PROV_CTRCT_ID))
										AND (EOMonth(CL.Cov_Month)  BETWEEN org.EFF_DATE AND org.END_DATE)
GROUP BY COV_MONTH, PAID_MONTH,  CLAIM_CLASS, CLOSE_MONTH, 
org.CENTER, org.SUB_REGION, product,CL.PROV_CTRCT_ID, SRC_CLAIM_NBR, Officename,  POT_CD, taxonomy, SRC_CLAIM_NBR , UMID

--select * from #Admit_Count_Triangle




drop table if exists #bm2

select * 
into #BM2
from CDO_Finance.dbo.CPB9220_MCCI_Mapping$ 
where SUB_ORG in ('CHM', 'CMCM', 'Amicus', 'Elite')

--select * from #BM2 where CTRCT_KEY like '000063421B%' order by CTRCT_KEY
--select * from CDO_Finance.dbo.CPB9220_MCCI_Mapping$  where CTRCT_KEY like '000110299%' order by CTRCT_KEY



--select a.Payer, cast(Cov_Month as date) as Cov_Month , Paid_Month, Claim_Class, Close_Month, UpdateDate, Company,Product,PCPID,OfficeName, POS,Taxonomy,Paid_Amount, Claim_Count
--from dbo.STG_CLM_TRIANGLE_Test_POT_With_Count A
--INNER JOIN #BM B on a.pcpid  = b.provider_id and a.cov_month between b.eff_date and b.end_date
--where A.payer =  'humana'

insert into STG_CLM_TRIANGLE_Test_POT_With_Count
(PAYER, COV_MONTH, PAID_MONTH, CLAIM_CLASS, CLOSE_MONTH, UPDATEDATE, Company, M.PRODUCT, PCPID, OfficeName ,POS, TAXONOMY,
Paid_Amount, Claim_Count)
select 
PAYER, COV_MONTH, PAID_MONTH, CLAIM_CLASS, CLOSE_MONTH, UPDATE_DATE, Company, M.PRODUCT, PCP_ID, Facility_Name,POT_CD, TAXONOMY,
sum(cast(PAID_AMT as float)) as Paid, Count(SRC_CLAIM_NBR) as ClaimCount
from  #Admit_Count_Triangle AS M 
--INNER JOIN
--                         #BM2 AS b ON REPLACE(M.PCP_ID, ' ', '') = REPLACE(b.CTRCT_KEY, ' ', '') 
WHERE        (M.PAYER = 'humana')
--			  AND (b.FIN_FLAG = 'Y') 
--			  AND (LEFT(CONVERT(varchar, M.Cov_Month, 112), 6) BETWEEN b.CENTER_FACILITY_BEG_DATE AND b.CENTER_FACILITY_END_DATE) --AND (M.Company = 'Elite')
--			  and m.Cov_Month >= '2021-01-01' -- and Company = 'Elite'
--and  company in ('CCS', 'Amicus', 'Elite')
group by PAYER, COV_MONTH, PAID_MONTH, CLAIM_CLASS, CLOSE_MONTH, UPDATE_DATE, Company, M.PRODUCT, PCP_ID, Facility_Name,POT_CD, TAXONOMY

--select * from #Admit_Count_Triangle




END

-------> Below is to support IFM Automation 

IF 
	(SELECT COUNT(*) FROM transcendanalytics.STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite where InsuranceCompany = 'Humana' and Company in ('elite','amicus','ccs') ) > 0 
BEGIN 
	INSERT INTO TRANSCENDANALYTICS.dbo.ifm_StoredProcedure_Log
	(Payor_Provider, Close_Month, [StoredProc], Last_Updt, Row_Cnt) 
	VALUES 
		(
			'Humana_CCS_Elite_Amicus', (SELECT CONVERT(VARCHAR(6), MAX(CLOSE_MONTH),112) FROM transcendanalytics.STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite where InsuranceCompany = 'Humana' and Company in ('elite','amicus','ccs')),
			'SF', GETDATE(), (SELECT COUNT(*) FROM transcendanalytics.STG.IFM_ServiceFund_Hum_CCS_Amicus_Elite where InsuranceCompany = 'Humana' and Company in ('elite','amicus','ccs') )
		) 
END 

 --select * from STG_CLM_TRIANGLE_Test_POT_With_Count where CLOSE_MONTH = '2024-01-01'
 --and PAYER = 'humana'




GO
