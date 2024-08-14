# Sail_Pawar@23may2024


# Note:
#1 this script creates .txt file with list of unique schema.table (ignores temp tables) from all the files present in input folder
#2 re-running this script will create fresh output file by overwriting existing output if already present as a result of last run.
#3 if schema.table is used in commented lines, it will be considered as well
#4 table names from dynamic sql will not be considered by this py script, if your script has hard coded table names then note them down manually 
#5 input files must have schema.tbl and not db.schema.tbl

import re
import os


# ============================================================================================================================
# 2 NECESSARY INPUTS
# ============================================================================================================================
# Note
# 1) give folder level path in variable folder_path.
# 2) dont use forword slash at the end of folder_path string.
# 3) give output location and file name as desired.
folder_path = 'snowflake/input'
output_location_with_file_name = 'snowflake/output/output.txt'
# ============================================================================================================================


output_file = open(output_location_with_file_name, "w")
# Iterate over all files in the folder
for filename in os.listdir(folder_path):
    output_list = []
    set_of_temp_tables = set()
    index_word_dict = {}
    word_index = 1

    file_path = os.path.join(folder_path, filename)
    if os.path.isfile(file_path):
        with open(file_path, 'r') as file:
            file_content = file.read()
            list_all_words = file_content.split()
            # createing a dictionary with index as key and every word extracted from file as value
            for word in list_all_words:
                index_word_dict[word_index] = word.lower().rstrip(';()').split(";")[0].split("(")[0].split(")")[0]
                word_index+=1
            # find all temporary tables eg: schema.table
            for key, value in index_word_dict.items():
                if index_word_dict.get(key-2) == 'temporary' or index_word_dict.get(key-2) == 'temp':
                    set_of_temp_tables.add(value.rstrip(';)')) 
            # find all schema.table words (temporary tables and something.something will be ignored unless its an actual table)
            for key, value in index_word_dict.items():
                if (value not in set_of_temp_tables) and \
                (index_word_dict.get(key-1) == 'into' or \
                index_word_dict.get(key-1) == 'from' or \
                index_word_dict.get(key-1) == 'table' or \
                index_word_dict.get(key-1) == 'update' or \
                index_word_dict.get(key-1) == 'join'):
                    if value not in output_list:
                        output_list.append(value.split('--')[0].split("/*")[0]) #removing comments if attached with schema.table
  
    # removing all elements that does not follow schema.table pattern and still have ended up in this output_list. eg cte 
    pattern = r'\b\w+\.\w+\b'
    filtered_output_list = [item for item in output_list if re.match(pattern,item)]
    # writing output into file
    output_file.write("=====================================================================================================================" + "\n")
    output_file.write("\n" + file_path + "\n\n")
    for item in filtered_output_list:
        output_file.write(item + "\n")


output_file.write("=====================================================================================================================" + "\n")
output_file.close()
print("output file saved at: " + output_location_with_file_name)

