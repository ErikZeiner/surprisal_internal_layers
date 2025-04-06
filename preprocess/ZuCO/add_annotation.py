import math
import json
import glob

import spacy
import pandas as pd
from wordfreq import word_frequency
from collections import defaultdict

nlp = spacy.load("en_core_web_sm")

dfs = []
for file in glob.glob("data/ZuCO/task2 - NR/*.csv"):
    subject = file.split("/")[-1].split(".")[0]
    df = pd.read_csv(file)
    df["subject"] = subject
    dfs.append(df)

df_all = pd.concat(dfs)
df_all.rename(columns={"word_id": "tokenN_in_sent", "GD": "time"}, inplace=True)
df_all[df_all["time"].isna()]["time"] = 0
df[df["word"]=="\u2013"]["word"] = "-"
df_all[["article_N", "sent_id", "tokenN_in_sent", "word", "time", "N400", "N400_baseline", "P600", "P600_baseline", "ANT", "ANT_baseline", "length"]].groupby(["article_N", "sent_id", "tokenN_in_sent", "word"]).mean().reset_index().to_csv("data/ZuCO/all.txt.averaged_rt")

df = pd.read_csv("data/ZuCO/all.txt.averaged_rt")
avg_len = df["length"].mean()
df["length_prev_1"] = df.apply(lambda x: df[(df["article_N"]==x["article_N"]) & (df["sent_id"]==x["sent_id"]) & (df["tokenN_in_sent"]==x["tokenN_in_sent"])]["length"].to_list()[0] if x["tokenN_in_sent"] > 0 else avg_len, axis=1)
df["length_prev_2"] = df.apply(lambda x: df[(df["article_N"]==x["article_N"]) & (df["sent_id"]==x["sent_id"]) & (df["tokenN_in_sent"]==x["tokenN_in_sent"])]["length"].to_list()[0] if x["tokenN_in_sent"] > 1 else avg_len, axis=1)

df["log_gmean_freq"] = df["word"].apply(lambda x: math.log(word_frequency(x, "en")+0.0000001))
avg_freq = df["log_gmean_freq"].mean()
df["log_gmean_freq_prev_1"] = df.apply(lambda x: df[(df["article_N"]==x["article_N"]) & (df["sent_id"]==x["sent_id"]) & (df["tokenN_in_sent"]==x["tokenN_in_sent"])]["log_gmean_freq"].to_list()[0] if x["tokenN_in_sent"] > 0 else avg_freq, axis=1)
df["log_gmean_freq_prev_2"] = df.apply(lambda x: df[(df["article_N"]==x["article_N"]) & (df["sent_id"]==x["sent_id"]) & (df["tokenN_in_sent"]==x["tokenN_in_sent"])]["log_gmean_freq"].to_list()[0] if x["tokenN_in_sent"] > 1 else avg_freq, axis=1)

df["is_first"] = df["tokenN_in_sent"] == 0
df["has_punct"] = df["word"].apply(lambda x: not all([c.isalpha() for c in x]))
df["has_num"] = df["word"].apply(lambda x: any([c.isdigit() for c in x]))
df = df.rename(columns={"article_N": "article"})

df.to_csv("data/ZuCO/all.txt.averaged_rt.annotation", quoting=2, escapechar="\\")

article2sents = defaultdict(list)
for article_id, article_grouped in df.groupby("article_N"):
    for sent_id, sent_grouped in article_grouped.groupby("sent_id"):
        sent = list(sent_grouped["word"])
        article2sents[article_id].append(sent)
json.dump(article2sents, open("data/ZuCO/tokens.json", "w"), ensure_ascii=False)