import json
import math

import pandas as pd
import sentencepiece as spm
from wordfreq import word_frequency

from statistics import mean
from itertools import groupby
from collections import defaultdict

df = pd.read_csv("data/NS/naturalstories/naturalstories_RTS/processed_RTs.tsv", delimiter="\t")
df = df.rename(columns={'meanItemRT': 'time', 'item': 'article'})
unique_df = df[["article", "zone", "word", "time"]].drop_duplicates()
unique_df["length"] = unique_df["word"].apply(lambda x: len(x))
unique_df["log_gmean_freq"] = unique_df["word"].apply(lambda x: math.log(word_frequency(x, "en")+0.0000001))

article2zone2is_first = defaultdict(dict)
article2zone2is_last = defaultdict(dict)
article2zone2has_punct = defaultdict(dict)
article2zone2has_num = defaultdict(dict)
article2zone2has_punct_prev_1 = defaultdict(dict)
article2zone2has_num_prev_1 = defaultdict(dict)

article2zone2sent_id = defaultdict(dict)
article2zone2tokenN_in_sent = defaultdict(dict)
article2zone2pos = defaultdict(dict)

article2sent_id = defaultdict(int)
with open("data/NS/naturalstories/parses/ud/stories-aligned.conllx") as f:
    for is_not_blank, lines in groupby(f, key=lambda x: bool(x.strip())):
        if is_not_blank:
            lines = list(lines)
            item_id = int(lines[0].strip().split("=")[-1].split(".")[0])
            zone_ids = [int(line.strip().split("=")[-1].split(".")[1]) for line in lines]
    
            tokenN_in_sent = 0
            for line, zone_id in zip(lines, zone_ids):
                dep = line.split("\t")[-3]
                if dep == "punct":
                    article2zone2has_punct[item_id][zone_id] = True
                    article2zone2has_punct_prev_1[item_id][zone_id+1] = True  
                if dep == "nummod":
                    article2zone2has_num[item_id][zone_id] = True 
                    article2zone2has_num_prev_1[item_id][zone_id+1] = True 
                pos = line.split("\t")[-6]
                if zone_id in article2zone2pos[item_id]:
                    continue
                article2zone2pos[item_id][zone_id] = pos
                article2zone2sent_id[item_id][zone_id] = article2sent_id[item_id]
                article2zone2tokenN_in_sent[item_id][zone_id] = tokenN_in_sent
                tokenN_in_sent += 1
            article2sent_id[item_id] += 1

            is_first_id = min(zone_ids)
            is_last_id = max(zone_ids)
            article2zone2is_first[item_id][is_first_id] = True
            article2zone2is_last[item_id][is_last_id] = True

unique_df["is_first"] = unique_df.apply(lambda x: article2zone2is_first[x["article"]].get(x["zone"], False), axis=1)
unique_df["is_last"] = unique_df.apply(lambda x: article2zone2is_last[x["article"]].get(x["zone"], False), axis=1)
unique_df["has_punct"] = unique_df.apply(lambda x: article2zone2has_punct[x["article"]].get(x["zone"], False), axis=1)
unique_df["has_num"] = unique_df.apply(lambda x: article2zone2has_num[x["article"]].get(x["zone"], False), axis=1)
unique_df["has_punct_prev_1"] = unique_df.apply(lambda x: article2zone2has_punct_prev_1[x["article"]].get(x["zone"], False), axis=1)
unique_df["has_num_prev_1"] = unique_df.apply(lambda x: article2zone2has_num_prev_1[x["article"]].get(x["zone"], False), axis=1)
unique_df["sent_id"] = unique_df.apply(lambda x: article2zone2sent_id[x["article"]].get(x["zone"]), axis=1)
unique_df["tokenN_in_sent"] = unique_df.apply(lambda x: article2zone2tokenN_in_sent[x["article"]].get(x["zone"]), axis=1)
unique_df["pos"] = unique_df.apply(lambda x: article2zone2pos[x["article"]].get(x["zone"]), axis=1)

mean_length = mean(unique_df["length"])
unique_df["length_prev_1"] = [mean_length] + list(unique_df["length"])[:-1]
unique_df["length_prev_1"] = unique_df.apply(lambda x: x["length_prev_1"] if x["tokenN_in_sent"] > 0 else mean_length, axis=1)
unique_df["length_prev_2"] = [mean_length, mean_length] + list(unique_df["length"])[:-2]
unique_df["length_prev_2"] = unique_df.apply(lambda x: x["length_prev_2"] if x["tokenN_in_sent"] > 1 else mean_length, axis=1)

mean_freq = mean(unique_df["log_gmean_freq"])
unique_df["log_gmean_freq_prev_1"] = [mean_freq] + list(unique_df["log_gmean_freq"])[:-1]
unique_df["log_gmean_freq_prev_1"] = unique_df.apply(lambda x: x["log_gmean_freq_prev_1"] if x["tokenN_in_sent"] > 0 else mean_freq, axis=1)
unique_df["log_gmean_freq_prev_2"] = [mean_freq, mean_freq] + list(unique_df["log_gmean_freq"])[:-2]
unique_df["log_gmean_freq_prev_2"] = unique_df.apply(lambda x: x["log_gmean_freq_prev_2"] if x["tokenN_in_sent"] > 1 else mean_freq, axis=1)

unique_df.to_csv("data/NS/all.txt.averaged_rt.annotation", quoting=2, escapechar="\\")

# generate tokens.json
df = pd.read_csv("data/NS/all.txt.averaged_rt.annotation")
article2sents = defaultdict(list)
for article_id, article_grouped in df.groupby("article"):
    for sent_id, sent_grouped in article_grouped.groupby("sent_id"):
        sent = list(sent_grouped["word"])
        article2sents[article_id].append([word if word !="peaked" else "peeked" for word in sent]) # fix to be aligned with NS_MAZE
json.dump(article2sents, open("data/NS/tokens.json", "w"))