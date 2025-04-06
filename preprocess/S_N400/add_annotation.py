import math
import json

import spacy
import pandas as pd
from wordfreq import word_frequency

nlp = spacy.load("en_core_web_sm")

with open("data/S_N400/szewczyk_2022.stims") as f:
    sent2id = {line.strip().replace("*", "") :i for i, line in enumerate(f, 1)}

df = pd.read_table("data/S_N400/szewczyk_2022.tsv")
df["article"] = df["FullSentence"].apply(lambda x: sent2id[x])
df["zone"] = df["FullSentence"].apply(lambda x: len(x.split())-1)
df["word"] = df["TargetWords"]
df["time"] = df["n400"]
df["length"] = df["TargetWords"].apply(len)
df["length_prev_1"] = df["FullSentence"].apply(lambda x: len(x.split()[-2]))
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
df["tokenN_in_sent"] = df["pos_start"]
df["pos"] = df["FullSentence"].apply(lambda x: nlp(x)[-1].tag_)
df = df.drop(["FullSentence", "n400", "TargetWords", "pos_start"], axis=1)
df.to_csv("data/S_N400/all.txt.annotation", quoting=2, escapechar="\\")

avg_df = df.groupby(["Item","logfreq","concr","old20","dataset","cloze_p","article","zone","word","length","length_prev_1","length_prev_2","log_gmean_freq","log_gmean_freq_prev_1","log_gmean_freq_prev_2","is_first","is_last","has_punct","has_num","has_punct_prev_1","has_num_prev_1","sent_id","tokenN_in_sent","pos"]).mean("time").reset_index()
avg_df.to_csv("data/S_N400/all.txt.averaged_rt.annotation", quoting=2, escapechar="\\")

with open("data/S_N400/szewczyk_2022.stims") as f:
    sents = {str(i): [line.strip().replace("*", "").split()] for i, line in enumerate(f, 1)}
json.dump(sents, open("data/S_N400/tokens.json", "w"))