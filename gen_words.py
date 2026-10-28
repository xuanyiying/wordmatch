#!/usr/bin/env python3
"""生成IT补充词汇 - 目标从227扩展到约1500"""
import json, sys

DATA_FILE = "wordmatch/assets/data/words_it.json"

EXISTING = {
    "acid","agile","algorithm","annotation","ansible","api","architecture",
    "array","artifact","assertion","async","authentication","authorization",
    "autoscaling","await","b-tree","backbone","backend","bandwidth","batch",
    "binary","boolean","breach","browser","bucket","buffer","bug","bundle",
    "cache","callback","cd","cdn","certificate","ci","cipher","class",
    "closure","cloud","cluster","collection","compile","compiler","component",
    "concurrency","config","constant","constructor","container","containerization",
    "csrf","css","cursor","database","dataset","ddos","debug","decorator",
    "dependency","deploy","deprecated","devops","dns","document","dom","domain",
    "download","elastic","embedding","encrypt","endpoint","enum","exception",
    "failover","feature","firewall","float","framework","frontend","function",
    "gateway","generics","git","gradient","handshake","hardware","hash","heap",
    "helm","hmac","host","http","hydration","icmp","index","infrastructure",
    "inheritance","instance","integer","interface","ip","iteration","jenkins",
    "join","kernel","kubectl","kubernetes","label","lambda","latency","lazy",
    "library","load","loadbalancer","log","logistic","loop","malware",
    "microservice","middleware","migration","module","monitor","multi-tenant",
    "multicast","namespace","nat","network","neural","nginx","node","nosql",
    "null","oauth","object","orchestration","overfitting","overflow","override",
    "packet","parameter","parse","partition","patch","payload","penetration",
    "phishing","ping","pipeline","platform","plugin","pointer","polymorphism",
    "prediction","prefetch","protocol","proxy","query","queue","ransomware",
    "recursive","refactor","reference","region","registry","regression",
    "reinforcement","render","replica","replica-set","repository","request",
    "response","responsive","rollback","router","runtime","s3","salt","sass",
    "scalability","schema","script","serialize","server","serverless","shard",
    "sharding","singleton","snapshot","snippet","socket","software","ssl",
    "stack","state","stateless","stream","string","struct","subnet","syntax",
    "tcp","template","tensor","terraform","thread","timeout","tls","token",
    "training","transaction","transformer","tuple","type","udp","upload",
    "upsert","variable","vault","vector","virtual","void","volatile","webpack",
    "websocket","widget","xss"
}

def w(word, pu, pk, defs, ex, freq):
    return {"id":f"{word}_it","word":word,"phonetic_us":pu,"phonetic_uk":pk,
            "definition":defs,"example":ex,"frequency":freq,"book_id":"it"}

WORDS = []
