from transformer_lens import HookedTransformer

gpt2_model = HookedTransformer.from_pretrained(
    "gpt2", 
    device="cpu",            # or "cuda" if you actually have a GPU
    cache_dir="./_cache_tl_MVE",  # points to a stable download folder
    fold_ln=False,
    center_writing_weights=False,
    center_unembed=False,
)

gpt2_model.eval()

tokenizer = gpt2_model.tokenizer
tokenizer.pad_token = tokenizer.eos_token
