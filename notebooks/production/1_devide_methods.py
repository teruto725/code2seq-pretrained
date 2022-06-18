import pandas as pd
import numpy as np
import lizard
import glob
from pprint import pprint
from typing import List

JAVA_SMALL_RAW_DATA = "../../data/java-small_raw" # 入力データセット
STYLES = ["training","validation","test"] 
SAVE_DF_PATH = "../../data/1_devided_methods/df" # DATAFRAMEの出力ディレクトリ


def get_methods_files(filepath :str) -> List[str]:
    liz = lizard.analyze_file(filepath,)
    source_code = []
    with open(filepath,encoding="utf8", errors='ignore') as f:
        source_code = f.readlines()
    methods = []
    methods.extend( ["".join(source_code[liz_func.start_line-1: liz_func.end_line]) for liz_func in liz.function_list])
    return methods

print("create df and sav pkl")
df_methods = None
for style in STYLES:
    filepaths = glob.glob(f"{JAVA_SMALL_RAW_DATA}/{style}/**/*")
    print(style)
    for i,filepath in enumerate(filepaths):
        if i%1000 == 0:print(i) 
        methods = get_methods_files(filepath)
        temp_df = pd.DataFrame({"style": [style]*len(methods),"method_code":methods})
        if df_methods is None:
            df_methods = temp_df
        else:
            df_methods = pd.concat([df_methods, temp_df])
df_methods=df_methods.reset_index(drop=True)
df_methods.to_pickle(f"{SAVE_DF_PATH}/1_devided_methods.pkl")


print("save methods")
SAVE_METHODS_PATH = "../../data/1_devided_methods_mini/methods" # DATAFRAMEの出力ディレクトリ
# 1_devided_methodsをファイル出力する
df = pd.read_pickle(SAVE_DF_PATH+"/1_devided_methods.pkl")
for style in STYLES:
    for i,method_code in enumerate(df[df["style"]==style]["method_code"]):
        with open(SAVE_METHODS_PATH+"/"+style+"/"+str(i)+".java", mode="w") as f:
            f.write(method_code)