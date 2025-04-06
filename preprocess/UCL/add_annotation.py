import math
import json
import pandas as pd
from wordfreq import word_frequency
import spacy

nlp = spacy.load("en_core_web_sm")

df = pd.read_csv("data/UCL/all_measures.csv")
id2sent = {row[1][0]: row[1][1] for row in df[["sent_id", "sentence"]].iterrows()}
tokens = {str(id): [sent.split()]for id, sent in id2sent.items()}
json.dump(tokens, open("data/UCL/tokens.json", "w"))

df = df.drop(['is_multitoken_GPT2', 's_GPT2',
       'is_multitoken_GPT2_medium', 's_GPT2_medium',
       'is_multitoken_GPT2_large', 's_GPT2_large', 'is_multitoken_GPT2_xl',
       's_GPT2_xl', 'is_multitoken_GPTNeo_125M', 's_GPTNeo_125M',
       'is_multitoken_GPTNeo', 's_GPTNeo', 'is_multitoken_GPTNeo_2.7B',
       's_GPTNeo_2.7B', 'rnn', 'rnn_pos', 'psg', 'psg_pos', 'bigram',
       'trigram', 'tetragram', 'bigram_pos', 'trigram_pos', 'tetragram_pos','cloze_p_smoothed',
       'cloze_s', 'item_id', 'rating_sd', 'rating_mean', 'list', 'entropy', 'word2'], axis=1).rename({'sent_id':'article', 'sentence': 'FullSentence', 'word': 'TargetWords', 'context_length': 'tokenN_in_sent'}, axis=1)
df["sent_id"] = 0

df.to_csv("data/UCL/all.txt",  sep="\t", quoting=2, escapechar="\\")
df.groupby(["item", "article", "TargetWords", "FullSentence", "tokenN_in_sent", "competition", "is_start_end", "Subtlex_log10", "length", "sent_id"])[["ELAN", "LAN", "N400", "EPNP", "P600", "PNP", 'RTfirstfix', 'RTfirstpass', 'RTrightbound', 'RTgopast',
       'self_paced_reading_time']].mean().reset_index().to_csv("data/UCL/all.txt.averaged_rt",  sep="\t", quoting=2, escapechar="\\")

df["word"] = df["TargetWords"]
avg_len = df["length"].mean()
df["length_prev_1"] = df.apply(lambda x: len(x["FullSentence"].split()[x["tokenN_in_sent"]-1] if x["tokenN_in_sent"] > 0 else avg_len), axis=1)
df["length_prev_2"] = df.apply(lambda x: len(x["FullSentence"].split()[x["tokenN_in_sent"]-2] if x["tokenN_in_sent"] > 1 else avg_len), axis=1)

df["log_gmean_freq"] = df["TargetWords"].apply(lambda x: math.log(word_frequency(x, "en")+0.0000001))
avg_freq = df["log_gmean_freq"].mean()
df["log_gmean_freq_prev_1"] = df.apply(lambda x: math.log(word_frequency(x["FullSentence"].split()[x["tokenN_in_sent"]-1], "en")+0.0000001) if x["tokenN_in_sent"] > 0 else avg_freq, axis=1)
df["log_gmean_freq_prev_2"] = df.apply(lambda x: math.log(word_frequency(x["FullSentence"].split()[x["tokenN_in_sent"]-2], "en")+0.0000001) if x["tokenN_in_sent"] > 1 else avg_freq, axis=1)

df["is_first"] = df["tokenN_in_sent"] == 1
df["is_last"] = df.apply(lambda x: bool((x["is_start_end"]) & (not x["is_first"])), axis=1)
df["has_punct"] = df["TargetWords"].apply(lambda x: not all([c.isalpha() for c in x]))
df["has_num"] = df["TargetWords"].apply(lambda x: any([c.isdigit() for c in x]))
df["has_punct_prev_1"] = df.apply(lambda x: not all([c.isalpha() for c in x["FullSentence"].split()[x["tokenN_in_sent"]-1]]) if x["tokenN_in_sent"] > 0 else False, axis=1)
df["has_num_prev_1"] = df.apply(lambda x: any([c.isdigit() for c in x["FullSentence"].split()[x["tokenN_in_sent"]-1]]) if x["tokenN_in_sent"] > 0 else False, axis=1)
df["context_char_len"] = df["item"].apply(lambda x: len(str(x))+1)
df["pos"] = df.apply(lambda x: ([t.tag_ for t in nlp(x["FullSentence"]) if t.idx == x["context_char_len"]][0:1] or [None])[0], axis=1)
df["RTreread"] = df["RTgopast"] - df["RTfirstpass"]
df = df.drop(["FullSentence", "TargetWords", "item"], axis=1)

df.to_csv("data/UCL/all.txt.averaged_rt.annotation", quoting=2, escapechar="\\")