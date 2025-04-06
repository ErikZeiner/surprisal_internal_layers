import json

for line in open("openwebtext-10k.jsonl"):
    data = json.loads(line)
    text = data["text"]
    print(text)