import math
import pandas as pd
from wordfreq import word_frequency
import spacy

nlp = spacy.load("en_core_web_sm")
df = pd.read_table("data/NS_MAZE/all.txt.averaged_rt", sep="\t")
df["word"] = df["TargetWords"]
df["time"] = df["rt"]
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
df = df.drop(["FullSentence", "rt", "TargetWords"], axis=1)

df.to_csv("data/NS_MAZE/all.txt.averaged_rt.annotation", quoting=2, escapechar="\\")