-- started working on this on 13thjuly24

USE [TranscendAnalytics]
GO
/****** Object:  StoredProcedure [dbo].[ifm_Transfer_CCS_United_Elite]    Script Date: 6/6/2024 12:48:22 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ifm_Transfer_CCS_United_Elite] 
	-- Add the parameters for the stored procedure here


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

-- Just to see what is there.

--select InsuranceCompany, Company, Close_Month, Product, loadDate,  count(*) as Rows
--from CDO_FINANCE.CDO.ServiceFund_IFM_All where InsuranceCompany = 'united'  and Company = 'Elite'
--group by InsuranceCompany, Company, Close_Month, Product, loadDate
--order by Close_Month desc, Company

--select InsuranceCompany, Company, Close_Month, Product, loadDate,  count(*) as Rows
--from STG.IFM_ServiceFund_United_Elite where InsuranceCompany = 'united'  and Company = 'Elite'
--group by InsuranceCompany, Company, Close_Month, Product, loadDate
--order by Close_Month desc, Company


--Delete Previous  SF Data

delete from CDO_FINANCE.CDO.ServiceFund_IFM_All
where InsuranceCompany = 'united'  and Company = 'Elite'

--Transfer Current  FPG SF data

INSERT INTO CDO_FINANCE.CDO.ServiceFund_IFM_All
                         (InsuranceCompany, InsuranceCompanyID, OfficeName, SFPCPName, PCPLastName, PCPFirstName, PCPID, MemberID, MCARE_ID, Cov_Month, Close_Month, RiskScoreC, CMSFundingA, CMSFundingB, CMSFundingC, 
                         CMSFundingD, CMSTotalFunding, FPGFundingA, FPGFundingB, FPGFundingC, FPGFundingD, PartDReserve, FPGTotalFunding, SpecCap, PCPCap, ClaimsPartA, ClaimsPartA_IP, ClaimsPartA_OP, ClaimsPartA_Other, 
                         ClaimsPartB, ProfClaims, RX_B_Claims, RX_D_Claims, RX_Rebates, RX_Stoploss, RX_LICS, RX_Quality, RX_GDCA, RX_REP_GAP_DSCNT, RX_RISK_CORRIDOR, RX_D__EXP, TotalClaims, StopLossFee, ReinRecoveries, 
                         Adjustment, FactorMonth, IBNRPartA, IBNRPartB, IBNR, Tot_Exp, Net, MemberName, SFBirthDate, SFGender, Hospice, ESRD, Institutional, NursingHomeCertifiable, PreviouslyDisabled, CurrentMember, [Level], LOB, PlanCode, 
                         PlanName, IPAName, PBP, Age, ProductType, Product, Contract, Company, LoadDate, Market, Cohort, Region, Org, TotalExpenses)
SELECT        InsuranceCompany, InsuranceCompanyID, OfficeName, SFPCPName, PCPLastName, PCPFirstName, PCPID, MemberID, MCARE_ID, Cov_Month, Close_Month, RiskScoreC, CMSFundingA, CMSFundingB, CMSFundingC, 
                         CMSFundingD, CMSTotalFunding, ProviderFundingA, ProviderFundingB, ProviderFundingC, ProviderFundingD, PartDReserve, ProviderTotalFunding, SpecCap, PCPCap, ClaimsPartA, ClaimsPartA_IP, ClaimsPartA_OP, 
                         ClaimsPartA_Other, ClaimsPartB, ProfClaims, RX_B_Claims, RX_D_Claims, RX_Rebates, RX_Stoploss, RX_LICS, RX_Quality, RX_GDCA, RX_REP_GAP_DSCNT, RX_RISK_CORRIDOR, RX_D__EXP, TotalClaims, StopLossFee, 
                         ReinRecoveries, Adjustment, FactorMonth, IBNRPartA, IBNRPartB, IBNR, TotalExpenses AS Tot_Exp, Net, MemberName, SFBirthDate, SFGender, Hospice, ESRD, Institutional, NursingHomeCertifiable, PreviouslyDisabled, 
                         CurrentMember, [Level], LOB, PlanCode, PlanName, IPAName, PBP, Age, ProductType, Product, Contract, Company, GETDATE(), Market, Cohort, Region, Org, TotalExpenses
FROM            STG.IFM_ServiceFund_United_Elite
WHERE        (InsuranceCompany = 'united') AND (Company = 'Elite')

--Transfer Current PM data

-- Just to see what is there

--select Close_Month, Insurance_Company, Company, Product, LOADDATE, count(*) as Rows
--from CDO_FINANCE.CDO.Provider_Margin_IFM
--where 
--Insurance_Company = 'united' and Company  IN ('Elite')
--and Close_Month >= '2024-03-01'
--group by Close_Month, Insurance_Company, Company, Product , LOADDATE
--order by Company, Close_Month

--select Close_Month, Insurance_Company, Company, Product, LOADDATE, count(*) as Rows
--FROM            Provider_Margin_CCS_IFM
--where 
--Insurance_Company = 'united' and Company IN ('Elite')
--group by Close_Month, Insurance_Company, Company, Product , LOADDATE

--delete
--from CDO_FINANCE.CDO.Provider_Margin_IFM
--where 
--Insurance_Company = 'united' and Company  IN ('Elite')
--and Close_Month = '2024-03-01'

INSERT INTO CDO_FINANCE.CDO.Provider_Margin_IFM
                         (Close_Month, Coverage_Month, Insurance_Company, Facility_Name, SF_PCP_Nname, PCP_ID, Description, Amount, Company, Product, Grouper_ID, Upside, Downside, Risk, Risk_Type, Market, Taxonomy, LOADDATE)
SELECT        Close_Month, Coverage_Month, Insurance_Company, Facility_Name, SF_PCP_Nname, PCP_ID, Description, Amount, Company, Product, Grouper_ID, Upside, Downside, Risk, Risk_Type, Market, Taxonomy, GETDATE()
FROM            Provider_Margin_CCS_IFM
WHERE        (Insurance_Company = 'united') AND (Company IN ('Elite'))

-- Trianngle

-- Just to see what is there

--select Close_Month, PAYER, Company, Product, Update_Date, count(*) 
--from STG.CLM_TRIANGLE_CCS_POT
--where 
--PAYER = 'united' and Company = 'Elite'
--group by Close_Month, PAYER, Company, Product, Update_Date
--order by Company, Close_Month

--select Close_Month, PAYER, Company, Product, Update_Date, count(*) 
--from CDO_FINANCE.CDO.ccs_Claims_Triangle_POT
--where 
--PAYER = 'united' and Company = 'Elite'
--and CLOSE_MONTH >= '2024-03-01'
--group by Close_Month, PAYER, Company, Product, Update_Date
--order by Company, Close_Month

INSERT INTO CDO_FINANCE.CDO.CCS_Claims_Triangle_POT
                         (PAYER, COV_MONTH, PAID_MONTH, PAID_AMT, CLAIM_CLASS, CLOSE_MONTH, UPDATE_DATE, Company, PRODUCT, PCP_ID, Facility_Name, POT_CD, POT_CD_DESC, TAXONOMY)
SELECT        PAYER, COV_MONTH, PAID_MONTH, PAID_AMT, CLAIM_CLASS, CLOSE_MONTH, GETDATE(), Company, PRODUCT, PCP_ID, Facility_Name, POT_CD, POT_CD_DESC, TAXONOMY
FROM            STG.CLM_TRIANGLE_CCS_POT
WHERE        (PAYER = 'united') AND (Company IN ('Elite'))

-- Admit Triangle

-- Just to see what is there

--select Close_Month, PAYER, Company, Product, UpdateDate, count(*) 
--from dbo.STG_CLM_TRIANGLE_Test_POT_With_Count
--where 
--PAYER = 'united' and Company = 'Elite'
--group by Close_Month, PAYER, Company, Product, UpdateDate
--order by Company, Close_Month

--select Close_Month, PAYER, Company, Product, Update_Date, count(*) 
--from CDO_FINANCE.dbo.STG_CLM_TRIANGLE_Test_POT_With_Count
--where 
--PAYER = 'united' and Company = 'Elite'
--and CLOSE_MONTH >= '2024-03-01'
--group by Close_Month, PAYER, Company, Product, Update_Date
--order by Company, Close_Month

--delete
--from dbo.STG_CLM_TRIANGLE_Test_POT_With_Count
--where 
--PAYER = 'united' and Company = 'Elite' and cast(UpdateDate as date) < '2024-05-16'


INSERT INTO CDO_FINANCE.dbo.STG_CLM_TRIANGLE_Test_POT_With_Count
                         (PAYER, COV_MONTH, PAID_MONTH, PAID_AMT, CLAIM_CLASS, CLOSE_MONTH, UPDATE_DATE, Company, PRODUCT, PCP_ID, Facility_Name, POT_CD, POT_CD_DESC, TAXONOMY, ClaimCount)
SELECT        Payer, Cov_Month, Paid_Month, Paid_Amount, Claim_Class, Close_Month, GETDATE() AS Expr1, Company, Product, PCPID, OfficeName, POS, POSDescription, Taxonomy, Claim_Count
FROM            STG_CLM_TRIANGLE_Test_POT_With_Count AS STG_CLM_TRIANGLE_Test_POT_With_Count_1
WHERE        (Payer = 'united') AND (Company IN ('Elite'))

-- new finance tables

--select Close_Month, PAYER, Company, Product, Update_Date, count(*) 
--from STG.CLM_TRIANGLE_CCS_POT
--where 
--PAYER = 'united' 
--group by Close_Month, PAYER, Company, Product, Update_Date
--order by Company, Close_Month

--select Close_Month, PAYER, Company, Product, Update_Date, count(*) 
--from CDO_FINANCE.ifm.CCS_triangle
--where 
--PAYER = 'united' 
--and close_month >= '2024-01-01'
--group by Close_Month, PAYER, Company, Product, Update_Date
--order by Company, Close_Month

INSERT INTO CDO_FINANCE.ifm.CCS_triangle
                         (PAYER, COV_MONTH, PAID_MONTH, PAID_AMT, CLAIM_CLASS, CLOSE_MONTH, UPDATE_DATE, Company, PRODUCT, PCP_ID, Facility_Name, POT_CD, POT_CD_DESC, TAXONOMY)
SELECT        PAYER, COV_MONTH, PAID_MONTH, PAID_AMT, CLAIM_CLASS, CLOSE_MONTH, GETDATE(), Company, PRODUCT, PCP_ID, Facility_Name, POT_CD, POT_CD_DESC, TAXONOMY
FROM            STG.CLM_TRIANGLE_CCS_POT
WHERE        (PAYER = 'united')


--select Close_Month, PAYER, Company, Product, UpdateDate, count(*) 
--,Min(Cov_Month) as Min_Month, Max(Cov_Month) as Max_Month
----select *
--from dbo.STG_CLM_TRIANGLE_Test_POT_With_Count
--where 
--PAYER = 'united'
--group by Close_Month, PAYER, Company, Product, UpdateDate
--order by Company, Close_Month

--select Close_Month, PAYER, Company, Product, Update_Date, count(*) 
--,Min(Cov_Month) as Min_Month, Max(Cov_Month) as Max_Month
--from cdo_finance.ifm.CCS_triangle_utilization
--where 
--PAYER = 'united'
--and CLOSE_MONTH >= '2024-01-01'
--group by Close_Month, PAYER, Company, Product, Update_Date
--order by Company, Close_Month, product


INSERT INTO cdo_finance.ifm.CCS_triangle_utilization
            (PAYER, CLOSE_MONTH, COV_MONTH, PAID_MONTH, PAID_AMT, Company, PCP_ID, POT_CD, CLAIM_CLASS, UPDATE_DATE, PRODUCT, ClaimCount, TAXONOMY)
SELECT        Payer, Close_Month, Cov_Month, Paid_Month, SUM(CAST(Paid_Amount AS float)) AS Expr2, Company, PCPID, POS, Claim_Class, GETDATE(), Product, SUM(Claim_Count) AS Expr3, Taxonomy
FROM            STG_CLM_TRIANGLE_Test_POT_With_Count
WHERE        (Payer = 'united')
GROUP BY Payer, Close_Month, Cov_Month, Paid_Month, Company, PCPID, POS, Claim_Class, UpdateDate, Product, Taxonomy


-- // Begin Email Code. HTML code sends results in tabular format 


DECLARE @XML NVARCHAR(MAX)
DECLARE @BODY_Start NVARCHAR(MAX) 
DECLARE @Table_START NVARCHAR(MAX) 
DECLARE @Table_End NVARCHAR(MAX) 
DECLARE @BODY_End NVARCHAR(MAX) 
DECLARE @BODY NVARCHAR(MAX) 
DECLARE @NoNullFacilities NVARCHAR(MAX)


SET @XML = CAST(
			   (
					SELECT DISTINCT 
							PCP_ID AS 'td',''
						  ,COMPANY as 'td',''
						  ,case when FACILITY_NAME is null then 'NULL' end as 'td',''
						 
					FROM TRANSCENDANALYTICS.dbo.Provider_Margin_CCS_IFM
					WHERE FACILITY_NAME IS NULL AND INSURANCE_COMPANY = 'united'  and Company in ('Elite')

				FOR XML PATH('tr'), ELEMENTS 
				) AS NVARCHAR(MAX)) 

SET @BODY_Start = '<html><body><P>Hello, the united Elite SF, PM, and triangle data has been transferred to CDO_FINANCE. 
					If there are NULL facilities, they will be displayed below.
					<br/>
			 <br/>File location:
			 <br/>
			 <a href="\\rsc.humad.com\qdrive\D749\F11701\SECURED\PHI\CDO Data Solutions\DDS Data Source\ADMIN REPORTS\">\\rsc.humad.com\qdrive\D749\F11701\SECURED\PHI\CDO Data Solutions\DDS Data Source\ADMIN REPORTS\</a>
			 </P>
			 <P>
			 YYYY_MM > Elite> [united_Elite_Recon_YYYYMM.xlsx]
			 </P>
			  
			 '
--\\rsc.humad.com\qdrive\D749\F11701\SECURED\PHI\CDO Data Solutions\DDS Data Source\ADMIN REPORTS\2023_01\PIPC\Wellcare\TX\Settlement(Optimum)-Group TX 2023-01 Recon.xlsx
SET @Table_START = '<table border = 1> 
			 <tr>
			 <th> PCP_ID </th> <th> COMPANY </th> <th> FACILITY_NAME </th>'
SET @Table_End = '</TR> </TABLE>'
SET @BODY_End = '<P>
			 If you have any questions please let me know.
			 <br/>
			 <br/>
			 Jody Schrader</P> ' 

Set @NoNullFacilities = '<P>There are no facilities with null values.</P>'
		 
if not exists(SELECT DISTINCT PCP_ID, COMPANY, FACILITY_NAME FROM TRANSCENDANALYTICS.dbo.Provider_Margin_CCS_IFM WHERE FACILITY_NAME IS NULL AND INSURANCE_COMPANY = 'united' and Company in ('Elite'))
	SET @BODY = @BODY_Start + @NoNullFacilities + @BODY_End + '</body></html>' 
else 
	SET @BODY = @BODY_Start + @Table_START + @XML + @Table_End + @BODY_End + '</body></html>' 



--SET @BODY = @BODY_Start + @XML + @BODY_End + '</body></html>' 


EXEC msdb.dbo.sp_send_dbmail
--@profile_name = 'SQL ALERTING', -- replace with your SQL Database Mail Profile 
@body = @body,
@body_format ='HTML',
--@recipients = 'AVARGAS@HUMANA.COM; BPeterson6@humana.com; jdorris@humana.com; cherman1@humana.com',  -- replace with your email address
@recipients = 'vjurkiewicz@humana.com; DVAUGHAN3@humana.com; xbencomo2@humana.com; TLile@centerwell.com; lwahl1@Humana.com; JNolan8@centerwell.com; EDeCicco@humana.com; EClevenger@humana.com; BPeterson6@humana.com; jmorris61@humana.com; LHellmann649@humana.com; ',
@copy_recipients = 'AVARGAS@HUMANA.COM; gscheynost@centerwell.com; jschrader@caredeliveryorganization.com;',
--@recipients = 'jschrader@caredeliveryorganization.COM',
@subject = 'united Elite Current Close SF, PM, and Triangle Data' ;



END
GO
