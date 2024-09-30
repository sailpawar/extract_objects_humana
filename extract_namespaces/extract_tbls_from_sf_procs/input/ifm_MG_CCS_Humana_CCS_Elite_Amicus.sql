

CREATE OR REPLACE PROCEDURE PCO_CDM_PREPROD_1.IFM.ifm_MG_CCS_Humana_CCS_Elite_Amicus()
RETURNS VARCHAR(16777216)
LANGUAGE SQL
EXECUTE AS CALLER
AS '

BEGIN


    
	CREATE or replace temporary TABLE ifm.temp_Provider_Margin
	(	Close_Month date NOT NULL,
		Coverage_Month date NOT NULL,
		Insurance_Company varchar(50) NULL,
		Facility_Name varchar(100) NULL,
		SF_PCP_Nname varchar(102) NULL,
		PCP_ID varchar(25) NULL,
		Description varchar(50) NULL,
		Amount decimal(38, 4) NULL,
		Company varchar(50) NULL,
		Product varchar(50) NULL,
		Upside float NULL,
		Downside float NULL,
		Risk varchar(10) NULL,
		Risk_Type varchar(255) NULL,
		Market varchar(255) NULL,
		Taxonomy varchar(50) NULL,
		load_ts timestamp_ntz(9) NULL,
		Grouper_ID varchar(100) NULL
	);



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market
		)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'Provider_Funding_Part C',
		SUM(ifnull(ProviderTotalFunding,0)) - sum(ifnull(PCPCap,0)) AS FPGFundingC,
		IPAName,
		Product,
		Company,
		Market
	FROM ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product, Company,Market
	HAVING (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'Provider_Capitation_Revenue',
		SUM(PCPCap) ,
		IPAName,
		Product, 
		Company,
		Market
	FROM ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product, Company,Market
	HAVING (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'Medical_Part_A_Claims_Paid',
		-SUM(ifnull(ClaimsPartA_IP,0)+ifnull(ClaimsPartA_OP,0)+ifnull(ClaimsPartA_Other,0)) , 
		IPAName, 
		Product,
		Company,
		Market
	FROM ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product, Company,Market
	HAVING (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'Medical_Part_A_Claims_Paid_IP',
		-SUM(ifnull(ClaimsPartA_IP,0)) , 
		IPAName, 
		Product,
		Company,
		Market
	FROM ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product, Company,Market
	HAVING (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'Medical_Part_A_Claims_Paid_OP',
		-SUM(ifnull(ClaimsPartA_OP,0)) , 
		IPAName,
		 Product,
		Company,
		Market
	FROM ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product, Company,Market
	HAVING  (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'Medical_Part_A_Claims_Paid_Other',
		-SUM(ifnull(ClaimsPartA_Other,0)) , 
		IPAName, 
		Product,
		Company,
		Market
	FROM ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product, Company,Market
	HAVING (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'Medical_Part_B_Claims_Paid',
		-SUM(ifnull(ClaimsPartB,0)) ,
		IPAName,
		Product,
		Company,
		Market
	FROM ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product, Company,Market
	HAVING (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'RX_Part_A_Claims',
		-SUM(ifnull(RX_B_Claims,0)) ,
		IPAName,
		Product,
		Company,
		Market
	FROM ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product, Company,Market
	HAVING (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'RX_Part_D_Claims',
		-SUM(ifnull(RX_D_Claims,0)) ,
		IPAName,
		Product,
		Company,
		Market
	FROM ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product, Company,Market
	HAVING (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'RX_Rebates',
		SUM(ifnull(RX_Rebates,0)) ,
		IPAName,
		Product,
		Company,
		Market
	FROM ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product, Company,Market
	HAVING (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'RX_Stoploss',
		SUM(ifnull(RX_Stoploss,0)) ,
		IPAName,
		Product,
		Company,
		Market
	FROM ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product, Company,Market
	HAVING (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'RX_LICS',
		SUM(ifnull(RX_LICS,0)) ,
		IPAName,
		Product,
		Company,
		Market
	FROM ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product, Company,Market
	HAVING  (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'RX_Quality',
		SUM(ifnull(RX_Quality,0)) ,
		IPAName,
		Product,
		Company,
		Market
	FROM  ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product, Company,Market
	HAVING  (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'RX_GDCA',
		SUM(ifnull(RX_GDCA,0)) ,
		IPAName,
		Product,
		Company,
		Market
	FROM  ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product, Company,Market
	HAVING (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'RX_REP_GAP_DSCNT',
		SUM(ifnull(RX_REP_GAP_DSCNT,0)) ,
		IPAName,
		Product,
		Company,
		Market
	FROM ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product, Company,Market
	HAVING (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'RX_RISK_CORRIDOR',
		SUM(ifnull(RX_RISK_CORRIDOR,0)) ,
		IPAName,
		Product,
		Company,
		Market
	FROM ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product, Company,Market
	HAVING (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'Specialty_Capitation',
		-SUM(ifnull(SpecCap,0)) ,
		IPAName,
		Product,
		Company,
		Market
	FROM ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product, Company,Market
	HAVING (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'StopLossFee',
		-SUM(ifnull(StopLossFee,0)) ,
		IPAName,
		Product,
		Company,
		Market
	FROM ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product, Company,Market
	HAVING (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'Reinsurance_Recoveries',
		SUM(ifnull(ReinRecoveries,0)) ,
		IPAName,
		Product,
		Company,
		Market
	FROM ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product, Company,Market
	HAVING (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'Adjustment',
		-SUM(ifnull(Adjustment,0)) ,
		IPAName,
		Product,
		Company,
		Market
	FROM            ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product, Company,Market
	HAVING        (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00')) and (InsuranceCompany <> 'Freedom' and InsuranceCompany <> 'Optimum' ) and PCPID <> ''
	ORDER BY Cov_Month;



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'Total Expenses',
		-sum(ifnull(ClaimsPartA_IP,0) +
		ifnull(ClaimsPartA_OP,0) +
		ifnull(ClaimsPartA_Other,0) +
	ifnull(ClaimsPartB,0) +
	ifnull(RX_B_Claims,0) +
	ifnull(RX_D_Claims,0) -
	ifnull(RX_Rebates,0) -
	ifnull(RX_Stoploss,0) -
	ifnull(RX_LICS,0) -
	ifnull(RX_Quality,0) -
	ifnull(RX_GDCA,0) -
	ifnull(RX_REP_GAP_DSCNT,0) -
	ifnull(RX_RISK_CORRIDOR,0) +
	ifnull(SpecCap,0) +
	ifnull(StopLossFee,0) -
	ifnull(ReinRecoveries,0) +
	ifnull(Adjustment,0) ),
	IPAName,
	Product,
	Company,
	Market
	FROM            ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product, Company,Market
	HAVING        (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))  
	ORDER BY Cov_Month;




	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'Net Activity',
		(case when InsuranceCompany = 'WellCare' then SUM(ifnull(ProviderFundingC,0)) + sum(ifnull(ProviderFundingD,0)) 
		else SUM(ifnull(ProviderFundingA,0)) + SUM(ifnull(ProviderFundingB,0)) + sum(ifnull(ProviderFundingD,0)) end)
		- sum(ifnull(ClaimsPartA_IP,0) + ifnull(ClaimsPartA_OP,0) + ifnull(ClaimsPartA_Other,0) +
	ifnull(ClaimsPartB,0) +
	ifnull(RX_B_Claims,0) +
	ifnull(RX_D_Claims,0) -
	ifnull(RX_Rebates,0) -
	ifnull(RX_Stoploss,0) -
	ifnull(RX_LICS,0) -
	ifnull(RX_Quality,0) -
	ifnull(RX_GDCA,0) -
	ifnull(RX_REP_GAP_DSCNT,0) -
	ifnull(RX_RISK_CORRIDOR,0) +
	ifnull(SpecCap,0) +
	ifnull(StopLossFee,0) -
	ifnull(ReinRecoveries,0) +
	ifnull(Adjustment,0) ),
	IPAName,
	Product,
	Company,
		Market
	FROM            ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product,Company,Market
	HAVING        (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'MemberMonths',
		count(MemberID),
		IPAName,
		Product,
		Company,
		Market
	FROM            ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product,Company,Market
	HAVING        (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;




	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'Total_Medical_Expenses',
		-SUM(ifnull(ClaimsPartA_IP,0) + ifnull(ClaimsPartA_OP,0) + ifnull(ClaimsPartA_Other,0) + ifnull(ClaimsPartB,0) + ifnull(SpecCap,0) +ifnull(StopLossFee,0) - ifnull(ReinRecoveries,0) +ifnull(Adjustment,0) ),
		IPAName,
		Product,
		Company,
		Market
	FROM            ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product,Company,Market
	HAVING        (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'Total_Rx_Expenses',
		-SUM(ifnull(RX_B_Claims,0) +
	ifnull(RX_D_Claims,0) +
	ifnull(RX_Rebates,0) -
	ifnull(RX_Stoploss,0) -
	ifnull(RX_LICS,0) -
	ifnull(RX_Quality,0) -
	ifnull(RX_GDCA,0) -
	ifnull(RX_REP_GAP_DSCNT,0) -
	ifnull(RX_RISK_CORRIDOR,0) 
	),
	IPAName,
	Product,
	Company,
		Market
	FROM            ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product,Company,Market
	HAVING        (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'Total Other Expenses',
		0 ,
		IPAName,
		Product,
		Company,
		Market
	FROM            ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product,Company,Market
	HAVING        (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'CMSFundingA',
		sum(ifnull(CMSFundingA,0)) ,
		IPAName,
		Product,
		Company,
		Market
	FROM            ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product,Company,Market
	HAVING        (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'CMSFundingB',
		sum(ifnull(CMSFundingB,0)) ,
		IPAName,
		Product,
		Company,
		Market
	FROM            ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product,Company,Market
	HAVING        (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'CMSFundingC',
		sum(ifnull(CMSFundingC,0)) ,
		IPAName,
		Product,
		Company,
		Market
	FROM            ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product,Company,Market
	HAVING        (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'CMSFundingD',
		sum(ifnull(CMSFundingD,0)) ,
		IPAName,
		Product,
		Company,
		Market
	FROM            ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product,Company,Market
	HAVING        (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'CMSFundingTotal',
		sum(ifnull(CMSTotalFunding,0)) ,
		IPAName,
		Product,
		Company,
		Market
	FROM            ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product,Company,Market
	HAVING        (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'PCP_Capitation',
		-sum(ifnull(PCPCap,0)) ,
		IPAName,
		Product,
		Company,
		Market
	FROM            ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product,Company,Market
	HAVING        (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;




	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'Gross_Medical_Part_B_Claims_Paid',
		-sum(ifnull(ProfClaims,0)),
		IPAName,
		Product,
		Company,
		Market
	FROM            ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product,Company,Market
	HAVING        (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'Gross_RX_Part_A_and_D Claims',
		-sum(ifnull(RX_B_Claims,0) + ifnull(RX_D_Claims,0)) ,
		IPAName,
		Product,
		Company,
		Market
	FROM            ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product,Company,Market
	HAVING        (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;



	INSERT INTO ifm.temp_Provider_Margin
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Market)
	SELECT
		SFPCPName,
		PCPID,
		OfficeName,
		Cov_Month,
		Close_Month,
		InsuranceCompany,
		'Humana_EXCL_Claims',
		-sum(ifnull(Humana_EXCL_Claims,0)) ,
		IPAName,
		Product,
		Company,
		Market
	FROM            ifm.IFM_ServiceFund_Hum_CCS_Amicus_Elite
	GROUP BY SFPCPName, PCPID, Cov_Month, OfficeName, InsuranceCompany, Close_Month, IPAName,Product,Company,Market
	HAVING        (Cov_Month >= to_timestamp_ntz('2016-01-01 00:00:00'))
	ORDER BY Cov_Month;




	UPDATE ifm.temp_Provider_Margin
	SET Taxonomy = 
		CASE WHEN Description = 'Medical_Part_A_Claims_Paid_IP' THEN 'Hospital_Inpatient'
			WHEN Description = 'Medical_Part_A_Claims_Paid_OP' THEN 'Hospital_Outpatient' 
			WHEN Description = 'Medical_Part_A_Claims_Paid_Other'THEN 'Hospital_Other'
			when Description = 'Medical_Part_B_Claims_Paid' then 'Physician'
			WHEN Description = 'RX_Part_A_Claims' THEN 'RX_B' 
			WHEN Description = 'RX_Part_D_Claims' THEN 'RX_D' ELSE Description END
	WHERE (Taxonomy IS NULL);



	UPDATE ifm.temp_Provider_Margin
	SET  load_ts = current_timestamp();              



	delete from ifm.Provider_Margin_CCS_IFM where Insurance_Company  = 'Humana';



	INSERT INTO ifm.Provider_Margin_CCS_IFM
		(SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Taxonomy,
		Market,
		load_ts
	)
	SELECT      SF_PCP_Nname,
		PCP_ID,
		Facility_Name,
		Coverage_Month,
		Close_Month,
		Insurance_Company,
		Description,
		Amount,
		Grouper_ID,
		Product,
		Company,
		Taxonomy,
		Market,
		load_ts
	FROM  ifm.temp_Provider_Margin;



	drop table ifm.temp_Provider_Margin;
	


	update ifm.Provider_Margin_CCS_IFM
	set SF_PCP_Nname = NULL;




	UPDATE ifm.Provider_Margin_CCS_IFM pmci
	SET Upside = rsk.Upside, Downside = rsk.Downside, Risk = rsk.Risk, Risk_Type = rsk."Risk Type", Market = rsk."Market Rollup"
	FROM  finance_protected.Risk rsk where pmci.PCP_ID = rsk.PCP_ID
										and to_timestamp_ntz(pmci.Coverage_Month) between rsk.Start_Date and rsk.End_Date
										and pmci.Company <> 'CCS';



	UPDATE ifm.Provider_Margin_CCS_IFM
	SET Upside = 1, Downside = 1, Risk = 'Y', Risk_Type = 'Global', Market = 'Orlando'
	where ifm.Provider_Margin_CCS_IFM.Company = 'FPG';




	update ifm.Provider_Margin_CCS_IFM
	set Risk = 'N',
		Risk_Type = 'Upside Only',
		Upside = '0.5',
		Downside = '0'
	where grouper_ID in('32145054','32145052','32145055','32145051','32145050','32145053')
	and Coverage_Month between '2019-01-01' and '2021-12-31'
	and company <> 'CCS';

	


	UPDATE       ifm.Provider_Margin_CCS_IFM
	SET  taxonomy =              
	case when Description = 'Medical_Part_A_Claims_Paid_IP' then 'Hospital_Inpatient'
		when Description = 'Medical_Part_A_Claims_Paid_OP' then 'Hospital_Outpatient'
		when Description = 'Medical_Part_A_Claims_Paid_Other' then 'Hospital_Other'
		when Description = 'RX_Part_A_Claims' then 'RX_B'
		when Description = 'RX_Part_D_Claims' then 'RX_D'
		when Description = 'Medical_Part_B_Claims_Paid' then 'Physician'
		else Description end;




	Update ifm.Provider_Margin_CCS_IFM
	set Company = 'Unknown'
	where company = ''
	or company is null;




	let Current_Close date := (select max(close_month) from ifm.Provider_Margin_CCS_IFM)::date;

	INSERT INTO ifm.Provider_Margin_CCS_IFM
							(Close_Month, Coverage_Month, Insurance_Company, Facility_Name, SF_PCP_Nname, PCP_ID, Description,
							Amount, Company, Product, Upside, Downside, Risk, Risk_Type, Market, Taxonomy, load_ts, Grouper_ID)
	SELECT      :Current_Close,
	Coverage_Month, Insurance_Company, Facility_Name, SF_PCP_Nname, PCP_ID, Description,
	Amount, Company, Product, Upside, Downside, Risk, Risk_Type, Market, Taxonomy, current_date(), Grouper_ID
	FROM            FINANCE_PROTECTED.Provider_Margin_IFM
	WHERE        (Insurance_Company = 'Humana') AND (Company IN ('CCS', 'Amicus', 'Elite', 'Prime West')) AND (Close_Month = '2023-06-01') AND (Coverage_Month < '2022-01-01')
	AND (Coverage_Month > '2020-12-01');




	INSERT INTO ifm.Provider_Margin_CCS_IFM
							(Close_Month, Coverage_Month, Insurance_Company, Facility_Name, SF_PCP_Nname, PCP_ID, Description,
							Amount, Company, Product, Upside, Downside, Risk, Risk_Type, Market, Taxonomy, load_ts, Grouper_ID)
	SELECT        :Current_Close, Coverage_Month, Insurance_Company, Facility_Name, SF_PCP_Nname, PCP_ID, Description,
	Amount, Company, Product, Upside, Downside, Risk, Risk_Type, Market, Taxonomy, current_date(), Grouper_ID
	FROM            FINANCE_PROTECTED.Provider_Margin_IFM
	WHERE        (Insurance_Company = 'Humana') AND (Company IN ('CCS', 'Amicus', 'Elite', 'Prime West')) AND (Close_Month = '2022-08-01') AND (Coverage_Month < '2021-01-01');




	update ifm.Provider_Margin_CCS_IFM
	set load_ts = current_timestamp()
	where (Insurance_Company = 'Humana') AND (Company IN ('CCS', 'Amicus', 'Elite', 'Prime West'));



	let close_month_value date  := (SELECT MAX(CLOSE_MONTH) FROM ifm.Provider_Margin_CCS_IFM where Insurance_Company  = 'Humana');
	let Row_Cnt_value integer := (SELECT COUNT(*) from ifm.Provider_Margin_CCS_IFM where Insurance_Company  = 'Humana');



	if ((SELECT COUNT(*) from ifm.Provider_Margin_CCS_IFM where Insurance_Company  = 'Humana') > 0 ) then
			INSERT INTO ifm.ifm_StoredProcedure_Log
				(Payor_Provider, Close_Month,StoredProc, Last_Updt_ts, Row_Cnt) 
				VALUES 
				(
					'Humana_CCS_Elite_Amicus',to_varchar(:close_month_value,'YYYYMM'),
					'MG', current_timestamp(),:Row_Cnt_value
				
				);
	END if; 

end;

';