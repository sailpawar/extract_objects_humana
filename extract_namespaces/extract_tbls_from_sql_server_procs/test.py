# sail_pawar@24thJune2024
# re-running this script will create fresh output file by overwriting existing output if already present as a result of last run.
# nothing from commented out code in stored procs will be considered

import re
import os


# ============================================================================================================================
# 5 NECESSARY INPUTS
# ============================================================================================================================
# Note
# 1) source_folder_path = folder path where proc files from sql server are stored
# 2) junk_folder_path = create a junk folder manually somewhere and point its path
# 3) output_location_with_file_name = folder path where you want your output to be saved with file name
# 4) find what is the encoding format if files in source_folder_path, all files in source_folder_path must have same encoding
# 5) if you want temporary tables included in output list or not (tables that start with # while creation)

source_folder_path = 'input_folder'
junk_folder_path = 'junk'
output_location_with_file_name = 'output/output_file.txt'
source_files_encoding = 'utf-16' # utf-8, utf-16, etc
exclude_temporary_tables = 0  #  1 = yes, 0 = no

# ============================================================================================================================



def read_and_save_as_txt(folder_path):
    if not os.path.exists(folder_path):
        pass
    else:
        for file_name in os.listdir(folder_path):
            file_path =  os.path.join(folder_path,file_name)
            if os.path.isfile(file_path):
                with open(file_path,'r',encoding=source_files_encoding) as file:
                    content = file.read()
            base_name = os.path.splitext(file_name)[0]
            new_file_path = os.path.join(junk_folder_path, base_name + '.txt')
            with open(new_file_path,'w',encoding="utf-8") as new_file:
                new_file.write(content)


def empty_junk_before_next_run(junk_folder_path):
    if not os.path.exists(junk_folder_path):
        pass
    else:
        for file_name in os.listdir(junk_folder_path):
            file_path =  os.path.join(junk_folder_path,file_name)
            if os.path.isfile(file_path):
                os.remove(file_path)


def remove_comments_1(file_path):
    with open(file_path,'r',encoding="utf-8") as file:
        content = file.read()
    # below line removes all square brackets in file
        content = content.replace('[','').replace(']','')
    # regex pattern to match anything between /* and */ inclusive
    comment_pattern_1 = re.compile(r'/\*.*?\*/',re.DOTALL)
    # replace matched pattern with an empty string
    cleaned_content_1 = re.sub(comment_pattern_1,'',content)
    with open(file_path,'w',encoding='utf_8') as file:
        file.write(cleaned_content_1)

def remove_comments_2(file_path):
    with open(file_path,'r',encoding="utf-8") as file:
        lines = file.readlines()
    # pattern to match anything from -- to end of the line
    comment_pattern_2 = re.compile(r'--.*$')
    cleaned_lines_list = []
    for line in lines:
            cleaned_line = re.sub(comment_pattern_2,'',line)
            cleaned_lines_list.append(cleaned_line.rstrip()+'\n')
    with open(file_path,'w',encoding="utf-8") as file:
         file.writelines(cleaned_lines_list)
    
def remove_from_set_xml(file_path):
    with open(file_path,'r',encoding="utf-8") as file:
        file_content = file.read()
    position_xml = file_content.lower().find("set @xml")
    if position_xml != -1:
        file_content = file_content[:position_xml]
    with open(file_path,'w',encoding="utf-8") as file:
        file.write(file_content)

def remove_from_body_start(file_path):
    with open(file_path,'r',encoding="utf-8") as file:
        file_content = file.read()
    position_body_start = file_content.lower().find("set @body_start")
    if position_body_start != -1:
        file_content = file_content[:position_body_start]
    with open(file_path,'w',encoding="utf-8") as file:
        file.write(file_content)


empty_junk_before_next_run(junk_folder_path)
read_and_save_as_txt(source_folder_path)
tbl_to_view_known_list= {'IFM_SF_DLY_CTRCT_DETAILS_CW': 'IFM.VW_IFM_SF_DLY_CTRCT_DETAILS_CW',
'IFM_SF_DLY_MEMBER_PCP_ELIG_HIST':  'IFM.VW_IFM_SF_DLY_MEMBER_PCP_ELIG_HIST ',
'IFM_SF_DLY_MEMBER_PCP_ELIG_HIST_CW':  'IFM.VW_IFM_SF_DLY_MEMBER_PCP_ELIG_HIST_CW  ',
'IFM_SF_DLY_MEMBER_PCP_ELIG_HIST_CW_HEAL':  'iFM.VW_IFM_SF_DLY_MEMBER_PCP_ELIG_HIST_CW_HEAL ',
'IFM_SF_HUMANA_DLY_CTRCT_DETAILS':  'IFM.VW_IFM_SF_HUMANA_DLY_CTRCT_DETAILS ',
'IFM_SF_MANUAL_ADJUSTMENTS_OPEN_FUNDING':  'IFM.VW_IFM_SF_MANUAL_ADJUSTMENTS_OPEN_FUNDING ',
'IFM_SF_MANUAL_ADJUSTMENTS_OPEN_FUNDING_CW':  'IFM.VW_IFM_SF_MANUAL_ADJUSTMENTS_OPEN_FUNDING_CW ',
'IFM_SF_MANUAL_ADJUSTMENTS_OPEN_FUNDING_CW_HEAL':  'IFM.VW_IFM_SF_MANUAL_ADJUSTMENTS_OPEN_FUNDING_CW_HEAL ',
'IFM_SF_MTH_BALANCE':  'IFM.VW_IFM_SF_MTH_BALANCE ',
'IFM_SF_MTH_BALANCE_CW':  'IFM.VW_IFM_SF_MTH_BALANCE_CW ',
'IFM_SF_MTH_BALANCE_CW_HEAL':  'IFM.VW_IFM_SF_MTH_BALANCE_CW_HEAL ',
'IFM_SF_MTH_CAP_FUNDING':  'IFM.VW_IFM_SF_MTH_CAP_FUNDING ',
'IFM_SF_MTH_CAP_FUNDING_CW':  'IFM.VW_IFM_SF_MTH_CAP_FUNDING_CW ',
'IFM_SF_MTH_CAP_FUNDING_CW_HEAL': 'IFM.VW_IFM_SF_MTH_CAP_FUNDING_CW_HEAL ' ,
'IFM_SF_MTH_CLAIMS_LINES':  'IFM.VW_IFM_SF_MTH_CLAIMS_LINES ',
'IFM_SF_MTH_CLAIMS_LINES_CW':  'IFM.VW_IFM_SF_MTH_CLAIMS_LINES_CW ',
'IFM_SF_MTH_CLAIMS_LINES_CW_HEAL':  'IFM.VW_IFM_SF_MTH_CLAIMS_LINES_CW_HEAL ',
'IFM_SF_MTH_PREM_CMS_MATCHED':  'IFM.VW_IFM_SF_MTH_PREM_CMS_MATCHED  ',
'IFM_SF_MTH_PREM_CMS_MATCHED_CW':  'IFM.VW_IFM_SF_MTH_PREM_CMS_MATCHED_CW ',
'IFM_SF_MTH_PREM_CMS_MATCHED_CW_HEAL':  'IFM.VW_IFM_SF_MTH_PREM_CMS_MATCHED_CW_HEAL ',
'IFM_SF_SPEC_CAP_EXP_OPEN_FUNDING':  'iFM.VW_IFM_SF_SPEC_CAP_EXP_OPEN_FUNDING ',
'IFM_SF_SPEC_CAP_EXP_OPEN_FUNDING_CW' : 'iFM.VW_IFM_SF_SPEC_CAP_EXP_OPEN_FUNDING_CW '}

output_file = open(output_location_with_file_name, "w")
# Iterate over all files in the folder
for filename in os.listdir(junk_folder_path):
    output_list = []
    list_of_cte = set()
    list_of_cte.add("pmpms,")
    list_of_cte.add("select")
    index_word_dict = {}
    word_index = 1
    tbl_to_view = []
    final_tbl_list = []

    file_path = os.path.join(junk_folder_path, filename)
    remove_comments_1(file_path)
    remove_comments_2(file_path)
    remove_from_set_xml(file_path)
    remove_from_body_start(file_path)
    if os.path.isfile(file_path):
        with open(file_path, 'r',encoding="utf-8") as file:
            file_content = file.read()
            list_all_words = file_content.split()
            # createing a dictionary with index as key and every word extracted from file as value
            for word in list_all_words:
                index_word_dict[word_index] = word.lower().rstrip(';()').split(";")[0].split("(")[0].split(")")[0]
                word_index+=1
            # find cte
            for key, value in index_word_dict.items():
                if(index_word_dict.get(key-1) == "with"
                   and index_word_dict.get(key-3) != "apply"):
                    list_of_cte.add(value)

            # find all schema.table words , cte will be ignored
            for key, value in index_word_dict.items():
                if(index_word_dict.get(key-1) == 'into' or \
                index_word_dict.get(key-1) == 'from' or \
                index_word_dict.get(key-1) == 'table' or \
                index_word_dict.get(key-1) == 'update' or \
                index_word_dict.get(key-1) == 'join' or \
                (index_word_dict.get(key-2) == 'if' and index_word_dict.get(key-1) == 'exists') 
                )  and value not in list_of_cte:
                    if value not in output_list:
                        output_list.append(value.strip("'")) #rstrip is for specefic usecase
  
    if(exclude_temporary_tables == 1):
        tmp_tbl_excluded_list = [item for item in output_list if not item.lstrip().startswith('#')] 
        filtered_list = [item for item in tmp_tbl_excluded_list if len(item) > 2]
    else:
        filtered_list = [item for item in output_list if len(item) > 2]

    
    for item in filtered_list:
        if len(item.split('.')) == 3 and item not in final_tbl_list:
            final_tbl_list.append(item)
        elif len(item.split('.')) == 2 and "transcendanalytics."+item not in final_tbl_list:
            final_tbl_list.append("transcendanalytics."+item)
        elif len(item.split('.')) == 1 and "transcendanalytics.dbo."+item not in final_tbl_list:
            final_tbl_list.append("transcendanalytics.dbo."+item)


    
    # writing output into file
    output_file.write("=====================================================================================================================" + "\n")
    output_file.write("\n" + file_path + "\n\n")
    for item in final_tbl_list:
        output_file.write(item + "\n")
        only_tbl_name = item.split('.')[2]
        
        for key, value in tbl_to_view_known_list.items():
            if key.lower() == only_tbl_name:
                tbl_to_view.append(item + " --> " + "transcendanalytics."+value.lower())

if tbl_to_view:
    output_file.write("\n\n\n"+"Below is list of tables which are to be replaced with views:" + "\n\n")
    for item in tbl_to_view:
        output_file.write(item+"\n")

output_file.write("=====================================================================================================================" + "\n")
output_file.close()
print("output file saved at: " + output_location_with_file_name)