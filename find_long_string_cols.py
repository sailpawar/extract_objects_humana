
# describe table ifm.Provider_Margin_CCS_IFM;



list = [
        'Close_Month',
		'Company',
		'LastRebate',
		'Act_Beg_Date',
		'Insurance_Company'
        ]



for x in list:
    print(f"select {x} from ifm.Max_Rebate_Month  where {x} like 'HMO%';" + "\n")





