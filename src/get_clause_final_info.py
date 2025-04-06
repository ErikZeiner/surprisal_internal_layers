import os
import json
import argparse
import benepar, spacy

from collections import defaultdict

parser = argparse.ArgumentParser()
parser.add_argument("-i", "--input", required=True)
args = parser.parse_args()

data = json.load(open(args.input))
nlp = spacy.load('en_core_web_md')
nlp.add_pipe('benepar', config={'model': 'benepar_en3'})

def get_clause_final_idx(sent: str):
    sent = list(nlp(sent).sents)[0]
    clause_final_indices = []
    for c in sent._.constituents:
        if "S" in c._.labels:
            cc = [cc for cc in c if cc.pos_ != "PUNCT"]
            clause_final = cc[-1]
            clause_final_indices.append(clause_final.idx)
    clause_final_indices = list(set(clause_final_indices))
    return clause_final_indices

article2is_clause_final = defaultdict(list)
for article_i, article in data.items():
    for tokens in article:
        token2position = []
        idx = 0
        for t in tokens:
            token2position.append(idx)
            idx += len(t) + 1
        assert len(token2position) == len(tokens)

        # by parse
        sent = " ".join(tokens)
        clause_final_idices = get_clause_final_idx(sent)

        # by punctuation
        clause_final_idices2 = [t for t in tokens if t[-1] in [",", "."]]
        
        all_clause_final_idices = set(clause_final_idices + clause_final_idices2)
        is_clause_final = [p in all_clause_final_idices for p in token2position]

        assert len(tokens) == len(is_clause_final)
        article2is_clause_final[article_i].append(is_clause_final)

json.dump(article2is_clause_final, open(os.path.join(os.path.dirname(args.input), "clause_finals.json"), "w"))