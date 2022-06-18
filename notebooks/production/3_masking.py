import pandas as pd
import subprocess
import os
import shutil
import pandas as pd
import numpy as np
import glob
from pprint import pprint
from typing import List


JAVA_SMALL_RAW_DATA = "../../data/java-small_raw_mini" # Data path of java-small_raw
STYLES = ["training","validation","test"] 
SAVE_DATA_PATH = "../../data/1_devided_methods_mini"

IDIOMS_PATH = "../../externallibs/code_review/idioms.csv"
SRC2ABS_PATH = "../../externallibs/src2abs/target/src2abs-0.1-jar-with-dependencies.jar"
METHODS_DIR_PATH = "../../data/3_masking_mini/methods"

# 1_devided_methodsをファイル出力する
df = pd.read_pickle(SAVE_DATA_PATH+"/1_devided_methods.pkl")
for style in STYLES:
    for i,method_code in enumerate(df[df["style"]==style]["method_code"]):
        with open(METHODS_DIR_PATH+"/"+style+"/"+str(i)+".java", mode="w") as f:
            f.write(method_code)

# マスキング
def masking(filepath: str, output_path:str, idioms_path:str = IDIOMS_PATH, jar_path:str = SRC2ABS_PATH):
    cp = subprocess.run(["java", "-jar",jar_path, "single","method",filepath,output_path, idioms_path])

# マスキングする
df_methods = None
for style in STYLES:
    filepaths = glob.glob(f"{METHODS_DIR_PATH}/{style}/*")
    for i,filepath in enumerate(filepaths):
        if i%1000 == 0:print(i) 
        filename = str(filepath).split("/")[-1]
        masking(filepath, f"../../data/3_masking_mini/maskedfiles/{style}/{filename}")
