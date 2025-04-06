
import math
import json
import pandas as pd
import spacy
import pandas as pd
from collections import defaultdict
from wordfreq import word_frequency

nlp = spacy.load("en_core_web_sm")

df = pd.read_csv("data/Fillers/processed_maze_data.csv")
df_maze_average = df.drop(["distractor", "subject", "noun", "Continuation", "trial", "distractor_condition", "item", "Region", "RegionFine"], axis=1).groupby(["id", "wordInItem", "sentence", "word"]).mean("rt").reset_index()
print(len(df_maze_average))

df = pd.read_csv("data/Fillers/processed_spr_data.csv")
df = df[df["wordInItem"]!="?"].astype({"wordInItem": int})
df_spr_average = df.drop([ "subject",  "item"], axis=1).groupby(["id", "wordInItem", "sentence"], as_index=False).mean("rt").reset_index()
print(len(df_spr_average))

df = pd.read_csv("data/Fillers/processed_et_data.csv")
df = df[(df["RBRT"]>0)]
df["wordInItem"] = df["roi"] - 1
df_et_average = df.drop(["subject", "trial", "experiment", "item", "condition", "accuracy", "roi"], axis=1).groupby(["id", "wordInItem", "sentence"]).mean().reset_index()
print(len(df_et_average))

df = pd.read_csv("data/Fillers/processed_maze_data.csv")
df = df.rename({"rt": "MAZE_RT"}, axis=1)
df_maze_average = df.drop(["Region", "RegionFine", "noun", "Continuation", "trial", "distractor_condition", "distractor", "subject"], axis=1).groupby(["id", "wordInItem", "sentence", "word"]).mean("MAZE_RT").reset_index()

df_all = pd.merge(pd.merge(df_maze_average, df_spr_average, on=["id", "wordInItem", "sentence"]).drop("index", axis=1), df_et_average, on=["id", "wordInItem", "sentence"])
df_all = df_all.rename({"sentence": "FullSentence", "word": "TargetWords", "wordInItem": "tokenN_in_sent"}, axis=1)

id2sentindex = defaultdict(lambda: len(id2sentindex))
for id in df_all["id"].to_list():
    id2sentindex[id]

df_all["article"] = df_all["id"].apply(lambda x: id2sentindex[x])
df_all = df_all.drop("id", axis=1)

df = df_all
df["length"] = df["TargetWords"].apply(len)
avg_len = df["length"].mean()
df["length_prev_1"] = df.apply(lambda x: len(x["FullSentence"].split()[x["tokenN_in_sent"]-1] if x["tokenN_in_sent"] > 0 else avg_len), axis=1)
df["length_prev_2"] = df.apply(lambda x: len(x["FullSentence"].split()[x["tokenN_in_sent"]-2] if x["tokenN_in_sent"] > 1 else avg_len), axis=1)

df["log_gmean_freq"] = df["TargetWords"].apply(lambda x: math.log(word_frequency(x, "en")+0.0000001))
avg_freq = df["log_gmean_freq"].mean()
df["log_gmean_freq_prev_1"] = df.apply(lambda x: math.log(word_frequency(x["FullSentence"].split()[x["tokenN_in_sent"]-1], "en")+0.0000001) if x["tokenN_in_sent"] > 0 else avg_freq, axis=1)
df["log_gmean_freq_prev_2"] = df.apply(lambda x: math.log(word_frequency(x["FullSentence"].split()[x["tokenN_in_sent"]-2], "en")+0.0000001) if x["tokenN_in_sent"] > 1 else avg_freq, axis=1)

df["is_first"] = df["tokenN_in_sent"] == 0
df["is_last"] = df.apply(lambda x: x["tokenN_in_sent"] == len(x["FullSentence"].split())-1, axis=1)
df["has_punct"] = df["TargetWords"].apply(lambda x: not all([c.isalpha() for c in x]))
df["has_num"] = df["TargetWords"].apply(lambda x: any([c.isdigit() for c in x]))
df["has_punct_prev_1"] = df.apply(lambda x: not all([c.isalpha() for c in x["FullSentence"].split()[x["tokenN_in_sent"]-1]]) if x["tokenN_in_sent"] > 0 else False, axis=1)
df["has_num_prev_1"] = df.apply(lambda x: any([c.isdigit() for c in x["FullSentence"].split()[x["tokenN_in_sent"]-1]]) if x["tokenN_in_sent"] > 0 else False, axis=1)
df["context_char_len"] = df.apply(lambda x: len(" ".join(x["FullSentence"].split()[:x["tokenN_in_sent"]]))+1 if x["tokenN_in_sent"]>0 else 0, axis=1)
df["pos"] = df.apply(lambda x: ([t.tag_ for t in nlp(x["FullSentence"]) if t.idx == x["context_char_len"]][0:1] or [None])[0], axis=1)
df = df.drop(["FullSentence", "TargetWords"], axis=1)
df["sent_id"] = 0
df.to_csv("data/Fillers/all.txt.averaged_rt.annotation", quoting=2, escapechar="\\")

sents = {row[1][0]: [row[1][1].split()] for row in df_all[["article", "FullSentence"]].drop_duplicates().iterrows()}
json.dump(sents, open("data/Fillers/tokens.json", "w"))