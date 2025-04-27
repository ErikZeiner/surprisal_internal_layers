import json
import os
import glob
import pandas as pd
import numpy as np
import statsmodels.api as sm
import statsmodels.formula.api as smf
import argparse

from statistics import mean
from patsy import dmatrices


data2targets = {
    "DC": ["time", "time_last_token"],
    "NS": ["time", "time_last_token"],
    "NS_MAZE": ["time", "time_last_token"],
    "UCL": ["ELAN","LAN","N400","EPNP","P600","PNP","RTfirstpass", "RTreread", "RTgopast", "self_paced_reading_time", "RTfirstpass_last_token", "RTreread_last_token", "RTgopast_last_token", "self_paced_reading_time_last_token", "N400_last_token", "P600_last_token", "EPNP_last_token", "PNP_last_token", "ELAN_last_token", "LAN_last_token"],
    "Fillers": ["SPR_RT", "MAZE_RT", "FPRT", "SPR_RT_last_token", "MAZE_RT_last_token", "FPRT_last_token"],
    "S_N400": ['Federmeier et al. (2007)', 'Hubbard et al. (2019)', 'Szewczyk & Federmeier (2022)', 'Szewczyk et al. (2022)', 'Wlotko & Federmeier (2012)'],
    "M_N400": ['C3', 'C4', 'CP3', 'CP4', 'CPz', 'Cz', 'P3', 'P4', 'Pz', 'all'],
    "MECO/du": ["time"],
    "MECO/ee": ["time"],
    "MECO/en": ["time"],
    "MECO/fi": ["time"],
    "MECO/ge": ["time"],
    "MECO/gr": ["time"],
    "MECO/he": ["time"],
    "MECO/it": ["time"],
    "MECO/ko": ["time"],
    "MECO/no": ["time"],
    "MECO/ru": ["time"],
    "MECO/sp": ["time"],
    "MECO/tr": ["time"],
    "ZuCO": ["time", "N400"]
}

def modeling(data, layer_id, target_file, df_original, is_clause_finals):
    all_interests = [sup for _, sents_sups in sorted(data.items(), key=lambda x: int(x[0])) for sent_sups in sents_sups for sup in sent_sups]
    mean_surprisal = mean(all_interests)
    df = df_original.copy()

    df["interest"] = df_original.apply(lambda x: data[str(x["article"])][x["sent_id"]][x["tokenN_in_sent"]], axis=1)
    df["interest_prev_1"] = [mean_surprisal] + list(df["interest"])[:-1]
    df["interest_prev_1"] = df.apply(lambda x: x["interest_prev_1"] if x["tokenN_in_sent"] > 0 else mean_surprisal, axis=1)
    df["interest_prev_2"] = [mean_surprisal, mean_surprisal] + list(df["interest"])[:-2]
    df["interest_prev_2"] = df.apply(lambda x: x["interest_prev_2"] if x["tokenN_in_sent"] > 1 else mean_surprisal, axis=1)
    if args.data in ["DC", "NS", "NS_MAZE", "UCL", "Fillers"]:
        df["is_clause_final"] = df_original.apply(lambda x: is_clause_finals[str(x["article"])][x["sent_id"]][x["tokenN_in_sent"]], axis=1)
    

    for target_name in data2targets[args.data]:
        if args.data == "NS_MAZE":
             output_path = target_file + f".result.layer{layer_id}.MAZE_{target_name}"
        else:
            output_path = target_file + f".result.layer{layer_id}.{target_name.replace(' ', '_')}"
        if os.path.exists(output_path) and not args.overwrite:
            print("skip!")
            continue

        if "last_token" in target_name:
            target_df = df[df["is_clause_final"]]
            print(len(target_df))
            target = target_name.replace("_last_token", "")
        else:
            target_df = df.copy()
            target = target_name
        if target not in ["RTreread", "RTreread_last_token", "RRT", "RRT_last_token", 
                          "ELAN","LAN","N400","EPNP","P600","PNP", "N400_last_token",
                            "P600_last_token", "PNP_last_token", "ELAN_last_token", "LAN_last_token", 
                            'Federmeier et al. (2007)', 'Hubbard et al. (2019)', 'Szewczyk & Federmeier (2022)', 'Szewczyk et al. (2022)', 'Wlotko & Federmeier (2012)',
                            'C3', 'C4', 'CP3', 'CP4', 'CPz', 'Cz', 'P3', 'P4', 'Pz', 'all']:
            target_df = target_df[target_df[target] > 0]
        
        
        if args.data == "S_N400":
            target_df = target_df[target_df["dataset"] == target]
            target = "time"
        if args.data == "M_N400":
            if target != "all":
                target_df = target_df[target_df["Electrode"] == target]
            target = "time"

        if args.data == "ZuCO" and target_name == "N400":
            formula = f'{target} ~ interest + interest_prev_1 + interest_prev_2 + length + log_gmean_freq +  length_prev_1 + log_gmean_freq_prev_1 + length_prev_2 + log_gmean_freq_prev_2 + N400_baseline'
            baseline_formula = f'{target} ~ interest_prev_1 + interest_prev_2 + length + log_gmean_freq  + length_prev_1 + log_gmean_freq_prev_1 + length_prev_2 + log_gmean_freq_prev_2 + N400_baseline'
        elif args.data == "S_N400":
            formula = f'{target} ~ interest + interest_prev_1 + interest_prev_2 + length + log_gmean_freq +  length_prev_1 + log_gmean_freq_prev_1 + length_prev_2 + log_gmean_freq_prev_2 + bline'
            baseline_formula = f'{target} ~ interest_prev_1 + interest_prev_2 + length + log_gmean_freq  + length_prev_1 + log_gmean_freq_prev_1 + length_prev_2 + log_gmean_freq_prev_2 + bline'
        else:
            formula = f'{target} ~ interest + interest_prev_1 + interest_prev_2 + length + log_gmean_freq +  length_prev_1 + log_gmean_freq_prev_1 + length_prev_2 + log_gmean_freq_prev_2'
            baseline_formula = f'{target} ~ interest_prev_1 + interest_prev_2 + length + log_gmean_freq  + length_prev_1 + log_gmean_freq_prev_1 + length_prev_2 + log_gmean_freq_prev_2'

        target_df = target_df[target_df["tokenN_in_sent"] > 0] # TODO: apply or not
        target_df = target_df[target_df["is_first"] == False]

        if args.data == "M_N400" and target == "all":
            mod = smf.mixedlm(formula, target_df, groups=target_df["electrode"])
            res = mod.fit()
            mod_baseline = smf.mixedlm(baseline_formula, target_df, groups=target_df["electrode"])
            res_baseline = mod_baseline.fit()
        else:
            y, X = dmatrices(formula, data=target_df, return_type='dataframe')
            mod = sm.OLS(y, X)
            res = mod.fit() 

            y_baseline, X_baseline = dmatrices(baseline_formula, data=target_df, return_type='dataframe')
            mod_baseline = sm.OLS(y_baseline, X_baseline)
            res_baseline = mod_baseline.fit() 

        with open(output_path, "w") as f:
            f.write(f"delta loglik: {res.llf - res_baseline.llf}\n")
            f.write(f"delta loglik per tokens: {(res.llf - res_baseline.llf)/len(df)}\n")
            f.write(f"average surprisal: {df['interest'].mean()/np.log(2)}\n")
            f.write(f"perplexity: {np.exp(df['interest'].mean())}\n")
            f.write(str(res.summary()))

def main(args):
    df_original = pd.read_csv(f"data/{args.data}/all.txt.averaged_rt.annotation")
    df_original = df_original.sort_values(["article", "sent_id", "tokenN_in_sent"])
    if args.data in ["DC", "NS", "NS_MAZE", "UCL", "Fillers", "ZuCO"]:
        is_clause_finals = json.load(open(f"data/{args.data}/clause_finals.json"))

    target_files = glob.glob(f"{args.input_dir}/**/surprisal.json", recursive=True)
    if not target_files:
        return
    for target_file in target_files:
        if args.data == "NS_MAZE":
            assert "NS" in target_file
        else:
            assert args.data in target_file
        print(target_file)
        article2interest = json.load(open(target_file))
        for layer_id, data in article2interest.items():
            modeling(data, str(layer_id), target_file, df_original, is_clause_finals=None)
    return

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--input-dir", required=True)
    parser.add_argument("-d", "--data", default="DC")
    parser.add_argument("-o", "--overwrite", action="store_true")
    args = parser.parse_args()
    main(args)