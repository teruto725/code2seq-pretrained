#!/usr/bin/env bash
###########################################################
#!/usr/bin/env bash

# 新しいデータセットの前処理を行うために以下の値を変更する。
# TRAIN_DIR、VAL_DIR、TEST_DIRは以下のパスでなければならない。     
# .javaファイルのあるサブディレクトリを含むディレクトリ
# DATASET_NAME は、現在抽出されているデータの名前に過ぎません。
# データセット                                              
# MAX_DATA_CONTEXTS は各データセットに残すべきコンテキストの数です。
# メソッド(デフォルトは1000)。学習時，これらのコンテキスト
# MAX_CONTEXTSまで動的にダウンサンプリングされます.
# MAX_CONTEXTS - 実際のコンテキストの数（デフォルトは200）．
# MAX_DATA_CONTEXTSのうち）考慮されるのは
# すべてのトレーニングイテレーションで テスト時のランダム性を回避するため．
# テストセットと検証セットでは、MAX_CONTEXTSのコンテキストのみが保持される。
# 学習用には、MAX_DATA_CONTEXTSを保持し、MAX_CONTEXTSを使用します。
# 学習中に動的に選択される)。
# subtoken_vocab_size、target_vocab_size - -。  
# - サブトークンとターゲットワードの保持数 
# 語彙に含まれる（上位に出現する単語とパスが保持される）。
# NUM_THREADS - 使用する並列スレッドの数．これは 
# 前処理にマルチコアマシンを使用することを推奨します。
# ステップで、この値をコアの数に設定します。
# PYTHON - Python3インタプリタの別名．
TRAIN_DIR=../../data/1_devided_methods_mini/methods/training
VAL_DIR=../../data/1_devided_methods_mini/methods/validation
TEST_DIR=../../data/1_devided_methods_mini/methods/test
DATASET_NAME=java-small_raw
MAX_DATA_CONTEXTS=1000
MAX_CONTEXTS=200
SUBTOKEN_VOCAB_SIZE=186277
TARGET_VOCAB_SIZE=26347
NUM_THREADS=1
PYTHON=python3
###########################################################

TRAIN_DATA_FILE=${DATASET_NAME}.train.raw.txt
VAL_DATA_FILE=${DATASET_NAME}.val.raw.txt
TEST_DATA_FILE=${DATASET_NAME}.test.raw.txt
EXTRACTOR_JAR=../../externallibs/code2seq-original/JavaExtractor/JPredict/target/JavaExtractor-0.0.1-SNAPSHOT.jar

mkdir -p data
mkdir -p data/${DATASET_NAME}

echo "Extracting paths from validation set..."
${PYTHON} ../../externallibs/code2seq-original/JavaExtractor/extract.py --dir ${VAL_DIR} --max_path_length 8 --max_path_width 2 --num_threads ${NUM_THREADS} --jar ${EXTRACTOR_JAR} > ${VAL_DATA_FILE} 2>> error_log.txt
echo "Finished extracting paths from validation set"
echo "Extracting paths from test set..."
${PYTHON} ../../externallibs/code2seq-original/JavaExtractor/extract.py --dir ${TEST_DIR} --max_path_length 8 --max_path_width 2 --num_threads ${NUM_THREADS} --jar ${EXTRACTOR_JAR} > ${TEST_DATA_FILE} 2>> error_log.txt
echo "Finished extracting paths from test set"
echo "Extracting paths from training set..."
${PYTHON} ../../externallibs/code2seq-original/JavaExtractor/extract.py --dir ${TRAIN_DIR} --max_path_length 8 --max_path_width 2 --num_threads ${NUM_THREADS} --jar ${EXTRACTOR_JAR}  > ${TRAIN_DATA_FILE} 2>> error_log.txt
echo "Finished extracting paths from training set"

TARGET_HISTOGRAM_FILE=data/${DATASET_NAME}/${DATASET_NAME}.histo.tgt.c2s
SOURCE_SUBTOKEN_HISTOGRAM=data/${DATASET_NAME}/${DATASET_NAME}.histo.ori.c2s
NODE_HISTOGRAM_FILE=data/${DATASET_NAME}/${DATASET_NAME}.histo.node.c2s

echo "Creating histograms from the training data"
cat ${TRAIN_DATA_FILE} | cut -d' ' -f1 | tr '|' '\n' | awk '{n[$0]++} END {for (i in n) print i,n[i]}' > ${TARGET_HISTOGRAM_FILE}
cat ${TRAIN_DATA_FILE} | cut -d' ' -f2- | tr ' ' '\n' | cut -d',' -f1,3 | tr ',|' '\n' | awk '{n[$0]++} END {for (i in n) print i,n[i]}' > ${SOURCE_SUBTOKEN_HISTOGRAM}
cat ${TRAIN_DATA_FILE} | cut -d' ' -f2- | tr ' ' '\n' | cut -d',' -f2 | tr '|' '\n' | awk '{n[$0]++} END {for (i in n) print i,n[i]}' > ${NODE_HISTOGRAM_FILE}


${PYTHON} ../../externallibs/code2seq-original/preprocess.py --train_data ${TRAIN_DATA_FILE} --test_data ${TEST_DATA_FILE} --val_data ${VAL_DATA_FILE} \
  --max_contexts ${MAX_CONTEXTS} --max_data_contexts ${MAX_DATA_CONTEXTS} --subtoken_vocab_size ${SUBTOKEN_VOCAB_SIZE} \
  --target_vocab_size ${TARGET_VOCAB_SIZE} --subtoken_histogram ${SOURCE_SUBTOKEN_HISTOGRAM} \
  --node_histogram ${NODE_HISTOGRAM_FILE} --target_histogram ${TARGET_HISTOGRAM_FILE} --output_name data/${DATASET_NAME}/${DATASET_NAME}
    
# If all went well, the raw data files can be deleted, because preprocess.py creates new files 
# with truncated and padded number of paths for each example.
# rm ${TRAIN_DATA_FILE} ${VAL_DATA_FILE} ${TEST_DATA_FILE} ${TARGET_HISTOGRAM_FILE} ${SOURCE_SUBTOKEN_HISTOGRAM} \
#  ${NODE_HISTOGRAM_FILE}

