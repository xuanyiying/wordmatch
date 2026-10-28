import json
import sys

MF = "/Users/yiying/dev-app/xiaoxiaole/wordmatch/assets/data/mnemonics_gaokao.json"
WF = "/Users/yiying/dev-app/xiaoxiaole/wordmatch/assets/data/words_gaokao_200.json"

with open(MF, "r", encoding="utf-8") as f:
    md = json.load(f)
with open(WF, "r", encoding="utf-8") as f:
    wd = json.load(f)

exist = {m["wordId"] for m in md["mnemonics"]}
all_ids = {w["id"] for w in wd["words"]}
missing = sorted(all_ids - exist)

def C(*cps):
    return "".join(chr(c) for c in cps)

DASH = C(8212, 8212)
