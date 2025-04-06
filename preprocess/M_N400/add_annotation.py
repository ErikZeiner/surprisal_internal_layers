import math
import json
import pandas as pd
from wordfreq import word_frequency
import spacy

nlp = spacy.load("en_core_web_sm")

with open("data/M_N400/michaelov_2023.stims") as f:
    sent2id = {line.strip().replace("*", "") :i for i, line in enumerate(f, 1)}

with open("data/M_N400/michaelov_2023.stims") as f:
    sents = {str(i): [line.strip().replace("*", "").split()] for i, line in enumerate(f, 1)}
json.dump(sents, open("data/M_N400/tokens.json", "w"))

df = pd.read_table("data/M_N400/michaelov_2024.tsv")

df["article"] = df["FullSentence"].apply(lambda x: sent2id[x])
df["zone"] = df["FullSentence"].apply(lambda x: len(x.split())-1)
df["word"] = df["TargetWords"]
df["time"] = df["N400"]
df["length"] = df["TargetWords"].apply(len)
df["length_prev_1"] = df["FullSentence"].apply(lambda x: len(x.split()[-2])) # only last word is targeted, thus index should be -2
df["length_prev_2"] = df["FullSentence"].apply(lambda x: len(x.split()[-3]))
df["log_gmean_freq"] = df["TargetWords"].apply(lambda x: math.log(word_frequency(x, "en")))
df["log_gmean_freq_prev_1"] = df["FullSentence"].apply(lambda x: math.log(word_frequency(x.split()[-2], "en")))
df["log_gmean_freq_prev_2"] = df["FullSentence"].apply(lambda x: math.log(word_frequency(x.split()[-3], "en")))
df["is_first"] = False
df["is_last"] = True
df["has_punct"] = df["TargetWords"].apply(lambda x: all([c.isalpha() for c in x]))
df["has_num"] = df["TargetWords"].apply(lambda x: any([c.isdigit() for c in x]))
df["has_punct_prev_1"] = df["FullSentence"].apply(lambda x: all([c.isalpha() for c in x.split()[-2]]))
df["has_num_prev_1"] = df["FullSentence"].apply(lambda x: any([c.isdigit() for c in x.split()[-2]]))
df["sent_id"] = int(0)
df["pos"] = df["FullSentence"].apply(lambda x: nlp(x)[-1].tag_)
df = df.drop(["FullSentence", "N400", "TargetWords", "ContextCode", "zone"], axis=1)
df.to_csv("data/M_N400/all.txt.annotation", quoting=2, escapechar="\\")

avg_df = df.groupby(['Condition', 'PlausibilityJudgement','Electrode', 'Cloze', 'ON', 'ZipfFrequency','article','word','length','log_gmean_freq','is_first','is_last', 'has_punct', 'sent_id', 'tokenN_in_sent']).mean("time").reset_index()
avg_df.to_csv("data/M_N400/all.txt.averaged_rt.annotation", quoting=2, escapechar="\\")