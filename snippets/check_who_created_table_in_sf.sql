SELECT * FROM INFORMATION_SCHEMA.TABLES              
               WHERE 
               TABLE_TYPE = 'BASE TABLE'
               AND TABLE_CATALOG='PCO_CDM_PREPROD_1'
               AND TABLE_SCHEMA = 'FINANCE_PROTECTED'
               AND TABLE_NAME='STG_CLM_TRIANGLE_FPG_POT';


               ------------------------------------------------------


SELECT * FROM INFORMATION_SCHEMA.views              
               WHERE 
                TABLE_CATALOG='PCO_CDM_PREPROD_1'
               AND TABLE_SCHEMA = 'FINANCE_PROTECTED'
               AND TABLE_NAME='V_PROVIDERMARGIN_BUSINESSMAPPING';