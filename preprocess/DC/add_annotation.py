import glob
import json
import math
import os
import re
import logging
import sentencepiece as spm

import pandas as pd

from logging import getLogger
from collections import defaultdict
from dataclasses import asdict
from itertools import groupby
from statistics import mean
from typing import List
from pydantic.dataclasses import dataclass
from pydantic import Field

from wordfreq import word_frequency

logging.basicConfig(level=logging.DEBUG)
logger = getLogger(__name__)

column2key = {
    0: "surface",
    1: "article",
    2: "screenN",
    3: "lineN",
    4: "segmentN",
    5: "tokenN_in_screen",
    6: "characterN_in_line",
    7: "length",
    8: "length_wo_punct",
    9: "punct_code",
    10: "open_punct_code",
    11: "close_punct_code",
    12: "tokenN",
    13: "freq_local",
}


@dataclass
class Token:
    surface: str = ""
    article: int = 0
    screenN: int = 0
    lineN: int = 0
    segmentN: int = 0
    tokenN_in_screen: int = 0
    # characterN_in_line: int = 0
    length: int = 0
    has_num: bool = False
    has_punct: bool = False
    log_gmean_freq: float = 0
    tokenN_in_sent: int = 0
    punct_code: int = 0
    is_first: bool = False
    is_last: bool = False
    # is_second_last: bool = False
    has_num_prev_1: bool = False
    has_punct_prev_1: bool = False


content_pos = [
    "NN",
    "NNP",
    "NNPS",
    "NNS",
]


dep_rel = [
    "nmod",
    "case",
    "det",
    "nsubj",
    "amod",
    "mark",
    "advmod",
    "dobj",
    "conj",
    "aux",
    "cc",
    "compound",
    "acl",
    "cop",
    "advcl",
    "ccomp",
    "xcomp",
    "name",
    "neg",
    "auxpass",
    "parataxis",
    "nummod",
    "nsubjpass",
    "appos",
    "expl",
    "mwe",
    "discourse",
    "csubj",
]


@dataclass
class Leaf:
    wnum: int = 0
    id_in_sent: int = 0
    sent_id: int = 0
    pos: str = ""
    head: int = 0
    dep_rel: str = ""

    def calc_anti_locality(self):
        self.anti_locality = len(self.preceding_syn_dists)

    def calc_locality(self):
        if len(self.preceding_syn_dists) > 0:
            self.avg_locality = mean(self.preceding_syn_dists)
            self.min_locality = min(self.preceding_syn_dists)
            self.max_locality = max(self.preceding_syn_dists)
            self.avg_locality_disc = mean(self.preceding_syn_dists_disc)
            self.min_locality_disc = min(self.preceding_syn_dists_disc)
            self.max_locality_disc = max(self.preceding_syn_dists_disc)


@dataclass
class DataPoint(Token, Leaf):
    subj_id: str = ""
    time: int = 0
    logtime: float = 0


def calc_freq(word: str):
    return math.log(word_frequency(word, "en")+0.0000001)


def load_tokens(files):
    article2tokens = defaultdict(list)
    for file in files:
        with open(file) as f:
            text_id = int(os.path.basename(file)[2:4])
            lines = f.readlines()
            tokenN = 1
            for i, line in enumerate(lines):
                line = line.strip()
                line = re.sub("\s+", "\t", line)
                info_from_line_dict = {
                    item[1]: col
                    for col, item in zip(
                        line.split("\t"), sorted(column2key.items(), key=lambda x: x[0])
                    )
                }
                info_from_line_dict = {k: v for k, v in info_from_line_dict.items() if k not in ["characterN_in_line", "is_second_last", "length_wo_punct", "open_punct_code", "close_punct_code", "tokenN", "freq_local"]}
                token = Token(
                    **info_from_line_dict,
                    has_num=bool(re.findall(r"[0-9]", info_from_line_dict["surface"])),
                    has_punct=int(info_from_line_dict["punct_code"]) > 0,
                    is_first=info_from_line_dict["tokenN_in_screen"] == "1",
                    log_gmean_freq=calc_freq(info_from_line_dict["surface"]),
                    tokenN_in_sent=tokenN,
                )

                article2tokens[text_id].append(token)
                if (
                    token.surface.endswith(".")
                    or token.surface.endswith("!")
                    or token.surface.endswith("?")
                ):
                    tokenN = 1
                else:
                    tokenN += 1

        tokens = article2tokens[text_id]
        for i, token in reversed(list(enumerate(tokens))):
            if i == len(article2tokens[text_id]) - 1:
                article2tokens[text_id][i].is_last = True
                continue
            elif int(tokens[i + 1].tokenN_in_screen) < token.tokenN_in_screen:
                article2tokens[text_id][i].is_last = True
            elif tokens[i + 1].is_last:
                article2tokens[text_id][i].is_second_last = True
            if i > 0:
                if tokens[i - 1].has_num:
                    article2tokens[text_id][i].has_num_prev_1 = True
                if tokens[i - 1].has_punct:
                    article2tokens[text_id][i].has_punct_prev_1 = True

    return article2tokens


def load_treebank(treebank_files):
    article2leaves = defaultdict(dict)
    for treebank in treebank_files:
        article_id = int(os.path.basename(treebank)[2:4])
        with open(treebank) as f:
            for sent_id, sent_lines in groupby(f, lambda x: x.split("\t")[2]):
                sent_leaves = {}
                sent_lines = list(sent_lines)
                for line in sent_lines:
                    info = line.strip().split("\t")
                    if info[-1] == "punct":
                        continue
                    leaf = Leaf(
                        wnum=info[1],
                        id_in_sent=info[3],
                        sent_id=info[2],
                        pos=info[4],
                        head=info[5],
                        dep_rel=info[6],
                    )
                    sent_leaves[int(info[3])] = leaf
                article2leaves[article_id].update(
                    {leaf.wnum: leaf for leaf in sent_leaves.values()}
                )
    return article2leaves


def load_durations(files, article2tokens):
    subj2first_duration = defaultdict(lambda: defaultdict(dict))
    for file in files:
        with open(file) as f:
            subj_id = os.path.basename(file)[0:2]
            text_id = int(os.path.basename(file)[2:4])
            prev_wnum = None
            for line in f:
                line = line.strip()
                line = re.sub("\s+", "\t", line)
                if line.split()[0] == "WORD":
                    continue
                if line.split()[6] == "-99":
                    continue
                if line.split()[6] == "0":
                    continue
                info = line.split("\t")
                wnum = int(info[6])
                duration = int(info[7])
                if wnum == prev_wnum:
                    subj2first_duration[subj_id][text_id][wnum] += duration
                elif subj2first_duration[subj_id][text_id].get(wnum):
                    continue
                else:
                    subj2first_duration[subj_id][text_id][wnum] = duration
                prev_wnum = wnum
    return subj2first_duration


def merge_token_duration(article2tokens, subj2first_duration, article2leaves):
    data_points = []
    for subj_id, article2duration in subj2first_duration.items():
        for text_id, wnum2duration in sorted(
            article2duration.items(), key=lambda x: x[0]
        ):
            tokens = article2tokens[text_id]
            tree_info = article2leaves[text_id]

            for i, token in enumerate(tokens):
                duration = wnum2duration.get(i + 1)
                leaf = tree_info.get(i + 1)
                if duration:
                    data_point = DataPoint(
                        **asdict(token),
                        **asdict(leaf) if leaf else {},
                        subj_id=subj_id,
                        time=duration,
                        logtime=math.log10(duration)
                    )
                else:
                    data_point = DataPoint(
                        **asdict(token),
                        **asdict(leaf) if leaf else {},
                        subj_id=subj_id,
                        time=0,
                        logtime="-Infinity"
                    )
                data_points.append(asdict(data_point))
    return data_points


def main():
    files = glob.glob("data/DC/dundee_corpus_utf8/tx*")
    article2tokens = load_tokens(files)
    logger.info("loaded texts")

    duration_files = glob.glob("data/DC/dundee_corpus_utf8/*ma1p.dat")
    subj2durations = load_durations(duration_files, article2tokens)
    logger.info("loaded gaze durations")

    treebanks = glob.glob("data/DC/treebank/*.modified")
    article2leaves = load_treebank(treebanks)
    logger.info("loaded treebanks")

    data_points = merge_token_duration(article2tokens, subj2durations, article2leaves)
    logger.info("merged annotations")
    logger.info(data_points[:10])
    json.dump(data_points, open("data/DC/all.txt.annotation", "w"), ensure_ascii=False)

    # average reading time
    df = pd.read_json("data/DC/all.txt.annotation")

    print(len(df))
    assert len(df) == 515010
    article2sents = defaultdict(list)
    for article_id, article_grouped in df.groupby("article"):
        c = 0
        for subj_id, subj_grouped in article_grouped.groupby("subj_id"):
            if c > 0:
                continue
            for sent_id, sent_grouped in subj_grouped.groupby("sent_id"):
                sent = []
                for tok_id, tok_grouped in sent_grouped.groupby("tokenN_in_sent"):
                    tok = "".join(["".join(tok.replace("▁", " ").split()) for tok in tok_grouped["surface"]])
                    sent.append(tok)
                article2sents[article_id].append(sent)
            c += 1
    json.dump(article2sents, open("data/DC/tokens.json", "w"))

    def aggregate(x):
        ts = [t for t in x if t > 0]
        if ts:
            return mean(ts)
        else:
            return 0
        
    avg_rt = pd.DataFrame(df.groupby(["article", "sent_id", "tokenN_in_sent"])["time"].apply(lambda x: aggregate(x)))
    assert len(avg_rt) == len([tok for article, sents in article2sents.items() for sent in sents for tok in sent])
    
    df_wo_rt = df.drop(["subj_id", "time", "logtime", "id_in_sent"], axis=1).drop_duplicates()
    df_wo_rt = df_wo_rt.iloc[df_wo_rt[["article", "sent_id", "tokenN_in_sent"]].drop_duplicates().index]
    new_df = pd.merge(avg_rt, df_wo_rt, on=["article", "sent_id", "tokenN_in_sent"], how="left")

    article2sent2tokens = defaultdict(lambda: defaultdict(list))
    for row in new_df[["article", "sent_id", "tokenN_in_sent"]].iterrows():
        article, sent_id, tokenN_in_sent = row[1]
        article2sent2tokens[article][sent_id].append(tokenN_in_sent)

    article2sent2tokens_corrected = defaultdict(lambda: defaultdict(dict))
    for article, sents in article2sent2tokens.items():
        for sent_id, sent in sents.items():
            for i, token_i in enumerate(sent):
                article2sent2tokens_corrected[article][sent_id][token_i] = i

    new_df["tokenN_in_sent"] = new_df.apply(lambda x: article2sent2tokens_corrected[x["article"]][x["sent_id"]][x["tokenN_in_sent"]], axis=1)

    mean_length = mean(new_df["length"])
    new_df["length_prev_1"] = [mean_length] + list(new_df["length"])[:-1]
    new_df["length_prev_1"] = new_df.apply(lambda x: x["length_prev_1"] if x["tokenN_in_sent"] > 0 else mean_length, axis=1)
    new_df["length_prev_2"] = [mean_length, mean_length] + list(new_df["length"])[:-2]
    new_df["length_prev_2"] = new_df.apply(lambda x: x["length_prev_2"] if x["tokenN_in_sent"] > 1 else mean_length, axis=1)

    mean_freq = mean(new_df["log_gmean_freq"])
    new_df["log_gmean_freq_prev_1"] = [mean_freq] + list(new_df["log_gmean_freq"])[:-1]
    new_df["log_gmean_freq_prev_1"] = new_df.apply(lambda x: x["log_gmean_freq_prev_1"] if x["tokenN_in_sent"] > 0 else mean_freq, axis=1)
    new_df["log_gmean_freq_prev_2"] = [mean_freq, mean_freq] + list(new_df["log_gmean_freq"])[:-2]
    new_df["log_gmean_freq_prev_2"] = new_df.apply(lambda x: x["log_gmean_freq_prev_2"] if x["tokenN_in_sent"] > 1 else mean_freq, axis=1)

    new_df.to_csv("data/DC/all.txt.averaged_rt.annotation", quoting=2, escapechar="\\")


# post correction
df = pd.read_csv("data/DC/all.txt.averaged_rt.annotation")
article2sent2tokens = defaultdict(lambda: defaultdict(list))
for row in df[["article", "sent_id", "tokenN_in_sent"]].iterrows():
    article, sent_id, tokenN_in_sent = row[1]
    article2sent2tokens[article][sent_id].append(tokenN_in_sent)

article2sent2tokeNs_corrected = defaultdict(lambda: defaultdict(dict))
for article, sents in article2sent2tokens.items():
    for sent_id, sent in sents.items():
       for i, token_i in enumerate(sent):
           article2sent2tokeNs_corrected[article][sent_id][token_i] = i

df["tokenN_in_sent"] = df.apply(lambda x: article2sent2tokeNs_corrected[x["article"]][x["sent_id"]][x["tokenN_in_sent"]], axis=1)
df.to_csv("data/DC/all.txt.averaged_rt.annotation", quoting=2, escapechar="\\")


if __name__ == "__main__":
    main()
