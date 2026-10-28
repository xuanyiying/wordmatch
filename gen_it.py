#!/usr/bin/env python3
import json
DATA_FILE = "wordmatch/assets/data/words_it.json"
def w(word, pu, pk, defs, ex, freq):
    return {"id":f"{word}_it","word":word,"phonetic_us":pu,"phonetic_uk":pk,"definition":defs,"example":ex,"frequency":freq,"book_id":"it"}
WORDS = []
