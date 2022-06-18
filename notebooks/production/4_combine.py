import pandas as pd
import numpy as np
import glob


MASKING_DATA_PATH = "../../data/3_masking/maskedfiles" # 入力データセット
STYLES = ["training","validation","test"] 
C2S_DIR_PATH = "../../data/2_convert_c2s"
C2S_PATHS = [C2S_DIR_PATH+"/java-small_raw.train.c2s",C2S_DIR_PATH+"/java-small_raw.val.c2s",C2S_DIR_PATH+"/java-small_raw.test.c2s"]


# c2s取り出し処理を先にやってidxを記録しておく
idxs= []
masked_methods = []
for c2s_path in C2S_PATHS:
    df = pd.read_table(c2s_path,header=None,names=["c2s_method"],skip_blank_lines=False)
df = df.dropna(how='all')
df = df[df["c2s_method"].str.contains('[a-z]+')]# 空行列の削除


OUTPUT_PATH = "../../data/4_combine/"
TRUE_STYLES = ["train","val","test"]

# masked?df = 
for style, c2s_path, true_style in zip(STYLES,C2S_PATHS,TRUE_STYLES):
    # masked_methods
    idxs= []
    masked_methods = []
    filepaths = sorted(glob.glob(f"{MASKING_DATA_PATH}/{style}/*.java"))
    for path in filepaths:
        idx = int(path.split("/")[-1].replace(".java","") )# 数字のindex
        idxs.append(idx)
        with open(path) as f:
            masked_methods.append(f.read())
    masked_df = pd.DataFrame(index = idxs, data={"masked_method": masked_methods})         

    # c2s_methods
    c2s_df = pd.read_table(c2s_path,header=None,names=["c2s_method"],skip_blank_lines=False)
    c2s_df = c2s_df[c2s_df["c2s_method"].str.contains('[a-z]+')]# 空行列の削除
    result_df = c2s_df.join(masked_df, how='inner')
    result_df["train_str"] = result_df["masked_method"] + " $$$ " + result_df["c2s_method"]

    result_df.to_csv(f"{OUTPUT_PATH}dataframe/{style}.csv")
    with open(OUTPUT_PATH+"input_c2s/"+true_style+".c2s", "w") as f:
        li = result_df["train_str"].values.tolist()
        li = map(lambda x: x + "\n", li)
        f.writelines(li)