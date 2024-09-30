
import re
import os

edited_excel_path = "./project/edited_excel_output.sql"
col_name_and_new_len_file_path = "./project/col_name_and_new_len.csv"
output_file_path = "./project/output.text"
source_file_encoding = "utf-8"
mention_autoincrement_col = "" #should either be value or empty string

def generate_auto_increment(content,sequence_col):
    if(mention_autoincrement_col != ""):
        pattern1 = r'create\s+or\s+replace\s+table\s+([\w\.]+)'
        match = re.search(pattern1,content,re.IGNORECASE)
        sch_tbl =  match.group(1) if match else None
        generate_sequence_line = f"CREATE OR REPLACE SEQUENCE {sch_tbl}_{sequence_col}_SEQ start with 1 increment by 1 order;\n\n"
        pattern2 = fr'{sequence_col}\s+#N/A'
        replacement = f"{sequence_col} NUMBER(38, 0) NOT NULL DEFAULT {sch_tbl}_{sequence_col}_SEQ.NEXTVAL,"
        updated_content = re.sub(pattern2,replacement,content,flags=re.IGNORECASE)
        output = generate_sequence_line+updated_content
        return output
    else: return content

def read_edited_excel_file(edited_excel_path):
    if not os.path.exists(edited_excel_path):
        print("edited_excel_path does not exist")
    else:
        if os.path.isfile(edited_excel_path):
            with open(edited_excel_path,'r',encoding=source_file_encoding) as file:
                content = file.read()
                return content

def read_col_name_and_new_len_file(col_name_and_new_len_file_path):
    if not os.path.exists(col_name_and_new_len_file_path):
        print("col_name_and_new_len_file_pathh does not exist")
    else:
        if os.path.isfile(col_name_and_new_len_file_path):
            with open(col_name_and_new_len_file_path,'r',encoding=source_file_encoding) as file:
                content = file.read().replace("varchar", "VARCHAR")
                return content


def get_mapping_dict(col_name_and_new_len_file_path):
    # Parse the file_mapping into a dictionary
    mapping_dict = {}
    col_name_and_new_length = read_col_name_and_new_len_file(col_name_and_new_len_file_path)
    for line in col_name_and_new_length.strip().split('\n')[1:]:
        column_name, length = line.split(',')
        mapping_dict[column_name] = length
    return mapping_dict 

def adjust_column_names(input):
    output1 = re.sub(r'\bloaddate\b','Load_ts',input,flags = re.IGNORECASE)
    output2 = re.sub(r'\bpaid_date\b','Paid_ts',output1,flags = re.IGNORECASE)
    output3 = re.sub(r'\bmodified_date\b','Modified_ts',output2,flags = re.IGNORECASE)
    output4 = re.sub(r'\bupdated_date\b','Updated_ts',output3,flags = re.IGNORECASE)
    output5 = re.sub(r'\bdds_(\w*)',r'ddsc_\1',output4,flags = re.IGNORECASE)
    return output5

def generate_output_file(output_file_path,content):
    with open(output_file_path,'w',encoding="utf-8") as new_file:
        new_file.write(content)

# Function to replace words in the file based on column info and print the result
def replace_words_in_file(edited_excel_path,col_name_and_new_len_file_path ):
    column_info = get_mapping_dict(col_name_and_new_len_file_path)
    content = read_edited_excel_file(edited_excel_path)
    content = generate_auto_increment(content,mention_autoincrement_col)

    
    for column_name, max_len in column_info.items():
        # Compile a regex pattern to match the column name followed by spaces/tabs and "VARCHAR"
        pattern = re.compile(r'\b' + re.escape(column_name) + r'\b\s*\t*\s*VARCHAR', re.IGNORECASE)
        replacement = f"{column_name} VARCHAR({max_len})"
        content = pattern.sub(replacement, content)
    
    print(f"check output at: {output_file_path}")
    return content


varchar_replaced = replace_words_in_file(edited_excel_path,col_name_and_new_len_file_path )
output = adjust_column_names(varchar_replaced)
generate_output_file(output_file_path,output)
print("""BELOW IS TAKEN INTO CONSIDERATION:
LoadDate      --> Load_Ts
Paid_Date     --> Paid_ts 
Modified_Date --> Modified_ts 
Updated_Date  --> Updated_Ts 
DDS_*         --> DDSC_* \n""")