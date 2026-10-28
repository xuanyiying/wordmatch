#!/usr/bin/env python3
"""生成阅读标注用的「频序常用词表」common_words.json。

阅读页本地标注引擎凭此表过滤常用词：词频排名 ≤ 阈值（intermediate 档 2000）
的词视为学习者已掌握，即使出现在当前词书且无学习进度也不自动标注；
只有用户显式学习中/已收藏的词才例外。无此过滤时，高考/CET 词书里大量
about/accept/access 级别的基础词都会被标成「生词」。

数据源优先级：
  1. --csv 指定的本地 ECDICT ecdict.csv（frq = BNC/COCA 词频排名，质量最佳，
     文件约 66MB，国内可用 build_mini_ecdict.py 中的 gh-proxy 镜像下载）。
  2. Google Web Trillion Word Corpus 前 10000 高频词表（first20000hours/
     google-10000-english，真实频序，体积极小，直连失败时走 gh-proxy 镜像）。

注意：BaiitMobile 遗留的 word-frequency.json 虽被当作「频序词表」使用，
实际是两个按字母序拼接的分片（the 排到 5215 位），index 不是词频排名，
不可直接复用。

输出（dictionary_service 同族资产，由 WordFrequencyService 解析）：
  ["the", "of", "and", ...]   # 数组下标 + 1 即词频排名

用法：
  python3 scripts/build_common_words.py                 # Google 词表，取前 6000
  python3 scripts/build_common_words.py --top 8000
  python3 scripts/build_common_words.py --csv /path/to/ecdict.csv
"""

import argparse
import csv
import io
import json
import os
import re
import ssl
import sys
import urllib.request

_GOOGLE_URLS = [
    "https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english.txt",
    "https://gh-proxy.com/https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english.txt",
    "https://ghproxy.net/https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english.txt",
]

OUT_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "..", "assets", "dict",
    "common_words.json",
)

_WORD_RE = re.compile(r"^[a-z]+(?:['-][a-z]+)*$")


def _valid(word: str) -> bool:
    # 标注引擎只处理纯英文词；撇除数字、符号与单字符（a/i 由停用词表处理）
    return bool(_WORD_RE.match(word)) and len(word) >= 2


def from_ecdict_csv(path: str, top: int) -> list[str]:
    rows = []
    with open(path, encoding="utf-8", errors="ignore") as f:
        for row in csv.DictReader(f):
            w = (row.get("word") or "").strip().lower()
            if not _valid(w):
                continue
            try:
                frq = int(row.get("frq") or 0)
            except ValueError:
                frq = 0
            if frq <= 0:
                continue
            rows.append((frq, w))
    # frq 即词频排名（越小越常见）；同排名按字母序保证生成结果稳定
    rows.sort(key=lambda e: (e[0], e[1]))
    out, seen = [], set()
    for _, w in rows:
        if w in seen:
            continue
        seen.add(w)
        out.append(w)
        if len(out) >= top:
            break
    return out


def _http_get(url: str) -> str:
    for ctx in (ssl.create_default_context(), ssl._create_unverified_context()):  # noqa: SLF001
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=90, context=ctx) as resp:
            return resp.read().decode("utf-8", errors="ignore")


def from_google(top: int) -> list[str]:
    last_err = None
    for url in _GOOGLE_URLS:
        try:
            print(f"下载 {url} ...")
            raw = _http_get(url)
            break
        except Exception as e:  # noqa: BLE001
            print(f"  失败：{e}")
            last_err = e
    else:
        raise RuntimeError(f"所有词表下载源均失败：{last_err}")

    out, seen = [], set()
    for line in raw.splitlines():
        w = line.strip().lower()
        if not _valid(w) or w in seen:
            continue
        seen.add(w)
        out.append(w)
        if len(out) >= top:
            break
    return out


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--top", type=int, default=6000,
                        help="保留的高频词数量（默认 6000，为阈值调整留余量）")
    parser.add_argument("--csv", default=None,
                        help="本地 ECDICT ecdict.csv 路径（按 frq 排序，优先于在线词表）")
    parser.add_argument("--words-file", default=None,
                        help="已下载的频序词表纯文本（每行一个词，优先于在线下载；"
                             "系统 Python 缺 CA 证书时用 curl 先下载再传此参数）")
    args = parser.parse_args()

    if args.csv:
        words = from_ecdict_csv(args.csv, args.top)
    elif args.words_file:
        with open(args.words_file, encoding="utf-8") as f:
            raw = f.read()
        words = list(dict.fromkeys(
            w for w in (line.strip().lower() for line in raw.splitlines())
            if _valid(w)
        ))[:args.top]
    else:
        words = from_google(args.top)
    # 完整性校验：词频表损坏（如断点续传拼接错位）时常见词会整体缺失
    anchors = {"the", "be", "to", "of", "and"}
    head = set(words[:100])
    if len(words) < 1500 or not anchors.issubset(head):
        raise RuntimeError(
            f"词表完整性校验失败（{len(words)} 条，top100 缺 "
            f"{sorted(anchors - head)}），数据源可能已损坏")

    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    with open(OUT_PATH, "w", encoding="utf-8") as f:
        json.dump(words, f, ensure_ascii=False, separators=(",", ":"))
    print(f"已生成 {os.path.normpath(OUT_PATH)}：{len(words)} 条频序常用词")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:  # noqa: BLE001
        print(f"[错误] 常用词表生成失败：{e}", file=sys.stderr)
        sys.exit(1)
