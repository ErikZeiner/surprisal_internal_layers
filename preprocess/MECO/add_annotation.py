import math
import pandas as pd

for lang in ['du', 'ee', 'en', 'fi', 'ge', 'gr', 'he', 'it', 'ko', 'no', 'ru', 'sp', 'tr']:
    file_name = f"data/MECO/{lang}/all.txt.averaged_rt"
    print(file_name)
    df = pd.read_table(file_name)
    df["word"] = df["TargetWords"]
    df["length"] = df["TargetWords"].apply(len)
    mean_length = df["length"].mean()
    df["length_prev_1"] = [mean_length] + list(df["length"])[:-1]
    df["length_prev_1"] = df.apply(lambda x: x["length_prev_1"] if x["tokenN_in_sent"] > 0 else mean_length, axis=1)
    df["length_prev_2"] = [mean_length, mean_length] + list(df["length"])[:-2]
    df["length_prev_2"] = df.apply(lambda x: x["length_prev_2"] if x["tokenN_in_sent"] > 1 else mean_length, axis=1)

    df["log_gmean_freq"] = df["freq"].apply(lambda x: math.log(x))
    mean_freq = df["log_gmean_freq"].mean()
    df["log_gmean_freq_prev_1"] = [mean_freq] + list(df["log_gmean_freq"])[:-1]
    df["log_gmean_freq_prev_1"] = df.apply(lambda x: x["log_gmean_freq_prev_1"] if x["tokenN_in_sent"] > 0 else mean_freq, axis=1)
    df["log_gmean_freq_prev_2"] = [mean_freq, mean_freq] + list(df["log_gmean_freq"])[:-2]
    df["log_gmean_freq_prev_2"] = df.apply(lambda x: x["log_gmean_freq_prev_2"] if x["tokenN_in_sent"] > 1 else mean_freq, axis=1)

    df["is_first"] = df["tokenN_in_sent"] == 0
    df["is_last"] = df.apply(lambda x: x["tokenN_in_sent"] == df[df["FullSentence"] == x["FullSentence"]]["tokenN_in_sent"].max(), axis=1)
    df["has_punct"] = df["TargetWords"].apply(lambda x: not all([c.isalpha() for c in x]))
    df["has_punct_prev_1"] = [False] + list(df["has_punct"])[:-1]
    df["has_num"] = df["TargetWords"].apply(lambda x: any([c.isdigit() for c in x]))
    df["has_num_prev_1"] = [False] + list(df["has_num"])[:-1]
    df = df.drop(["FullSentence", "TargetWords"], axis=1)

    df.to_csv(file_name + ".annotation", quoting=2, escapechar="\\")