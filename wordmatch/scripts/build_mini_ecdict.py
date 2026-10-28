#!/usr/bin/env python3
"""生成资讯频道离线查词词典 mini_ecdict.json。

数据源优先级：
  1. 本地词书（xiaoxiaole/dict/book/*.zip，JSONL 格式，含 usphone/ukphone/
     trans[tranCn,pos]），去重后全量收录（81 本词书约 2.2 万词）。
  2. ECDICT（skywind3000/ECDICT，MIT 协议）ecdict.csv，按词频（frq 升序）
     取前 N 条高频词——国内直连需镜像，仅在前两者不可用时使用。

输出结构（dictionary_service.dart 按此解析，改动需同步）：
  {"word": {"p": "音标", "pos": "词性", "d": "中文释义"}}

失败时打印告警并以非零码退出，不阻塞 App 构建
（App 运行时检测 assets 缺失会自动全走 AI 查词）。

用法：
  python3 scripts/build_mini_ecdict.py [--top 30000] [--csv /path/to/ecdict.csv]
  （--csv 指定本地已下载的 csv 时跳过词书与网络）
"""

import argparse
import csv
import glob
import io
import json
import os
import ssl
import sys
import urllib.request
import zipfile

# ECDICT 备用下载源（gh-proxy 类镜像；jsDelivr 对 >20MB 文件返回 403，勿加）
_SOURCES = [
    "https://gh-proxy.com/https://raw.githubusercontent.com/skywind3000/ECDICT/master/ecdict.csv",
    "https://ghproxy.net/https://raw.githubusercontent.com/skywind3000/ECDICT/master/ecdict.csv",
]

# 本地词书目录（wordmatch/scripts/../.. = xiaoxiaole 根目录）
LOCAL_BOOK_DIR = os.path.normpath(
    os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "dict", "book")
)

OUT_PATH = "assets/dict/mini_ecdict.json"


def fetch_ecdict_csv() -> str:
    last_err = None
    for url in _SOURCES:
        for ctx in (ssl.create_default_context(), ssl._create_unverified_context()):  # noqa: SLF001
            try:
                desc = "verified" if ctx is not ssl._create_unverified_context() else "unverified"
                print(f"下载 {url} (ssl={desc}) ...")
                req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
                with urllib.request.urlopen(req, timeout=120, context=ctx) as resp:
                    return resp.read().decode("utf-8", errors="ignore")
            except Exception as e:  # noqa: BLE001
                print(f"  失败：{e}")
                last_err = e
    raise RuntimeError(f"所有下载源均失败：{last_err}")


def _normalize_word(raw: str) -> str | None:
    w = (raw or "").strip().lower()
    if not w:
        return None
    if not all(c.isascii() and (c.isalpha() or c in "-'") for c in w):
        return None
    return w


def collect_from_local_books() -> dict[str, dict]:
    """遍历本地词书 zip（JSONL），聚合词条。

    同一词出现在多本书时：音标取首个非空，词性/释义取信息更全的一条。
    返回 {word: {"p","pos","d"}}。
    """
    result: dict[str, dict] = {}
    zips = sorted(glob.glob(os.path.join(LOCAL_BOOK_DIR, "*.zip")))
    if not zips:
        raise FileNotFoundError(f"本地词书目录无 zip：{LOCAL_BOOK_DIR}")
    for zp in zips:
        try:
            with zipfile.ZipFile(zp) as z:
                name = z.namelist()[0]
                with z.open(name) as f:
                    for line in io.TextIOWrapper(f, encoding="utf-8", errors="ignore"):
                        line = line.strip()
                        if not line:
                            continue
                        try:
                            obj = json.loads(line)
                            head = obj["content"]["word"]["wordHead"]
                            content = obj["content"]["word"]["content"]
                        except Exception:
                            continue
                        w = _normalize_word(head)
                        if w is None:
                            continue
                        phon = (content.get("usphone") or content.get("ukphone") or "").strip()
                        trans = content.get("trans") or []
                        pos_list = [t.get("pos", "").strip() for t in trans if t.get("pos")]
                        defs = [t.get("tranCn", "").strip() for t in trans if t.get("tranCn")]
                        if not defs and not phon:
                            continue
                        pos = ",".join(dict.fromkeys(p for p in pos_list if p))
                        d = "；".join(x for x in defs if x)
                        cur = result.get(w)
                        if cur is None:
                            result[w] = {"p": phon, "pos": pos, "d": d[:80]}
                        else:
                            if not cur["p"] and phon:
                                cur["p"] = phon
                            if len(d) > len(cur["d"]):
                                cur["d"] = d[:80]
                            if not cur["pos"] and pos:
                                cur["pos"] = pos
        except Exception as e:  # noqa: BLE001
            print(f"  跳过损坏词书 {os.path.basename(zp)}：{e}")
    if not result:
        raise RuntimeError("本地词书解析结果为空")

    # 并入 IT 技术词表（dict/data/it_expansion_merged.json，249 词）：
    # 词书对技术词覆盖不足（如 algorithm），仅补充词书缺失的词
    it_path = os.path.join(os.path.dirname(LOCAL_BOOK_DIR), "data", "it_expansion_merged.json")
    if os.path.isfile(it_path):
        try:
            with open(it_path, encoding="utf-8") as f:
                it_words = json.load(f).get("words") or []
            added = 0
            for item in it_words:
                w = _normalize_word(item.get("word"))
                if w is None or w in result:
                    continue
                defs = [x.strip() for x in (item.get("definition") or []) if x.strip()]
                if not defs:
                    continue
                result[w] = {
                    "p": (item.get("phonetic_us") or "").strip().strip("/"),
                    "pos": "",
                    "d": "；".join(defs)[:80],
                }
                added += 1
            print(f"并入 IT 技术词表：+{added} 词")
        except Exception as e:  # noqa: BLE001
            print(f"  IT 词表并入失败（忽略）：{e}")
    return result


def collect_from_ecdict_csv(raw: str, top: int) -> dict[str, dict]:
    reader = csv.DictReader(io.StringIO(raw))
    entries = []
    for row in reader:
        w = _normalize_word(row.get("word"))
        if w is None:
            continue
        frq = row.get("frq") or "0"
        try:
            frq_val = int(frq)
        except ValueError:
            frq_val = 0
        if frq_val <= 0:
            continue
        translation = (row.get("translation") or "").strip().replace("\n", "；")
        if not translation:
            continue
        entries.append((w, (row.get("phonetic") or "").strip(),
                        (row.get("pos") or "").strip(), translation, frq_val))
    # frq 越小越高频（BNC/COCA 词频排名）
    entries.sort(key=lambda e: e[4])
    entries = entries[:top]
    return {w: {"p": p, "pos": pos, "d": d[:80]} for w, p, pos, d, _ in entries}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--top", type=int, default=30000, help="ECDICT 模式保留最高频词数")
    parser.add_argument("--csv", default=None, help="本地已下载的 ecdict.csv 路径（跳过词书与下载）")
    args = parser.parse_args()

    if args.csv:
        print(f"使用本地 ECDICT 文件 {args.csv}")
        with open(args.csv, encoding="utf-8", errors="ignore") as f:
            raw = f.read()
        result = collect_from_ecdict_csv(raw, args.top)
    elif os.path.isdir(LOCAL_BOOK_DIR):
        print(f"使用本地词书 {LOCAL_BOOK_DIR}")
        result = collect_from_local_books()
    else:
        print("本地词书目录不存在，回退 ECDICT 下载")
        result = collect_from_ecdict_csv(fetch_ecdict_csv(), args.top)

    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    with open(OUT_PATH, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, separators=(",", ":"))

    print(f"已生成 {OUT_PATH}：{len(result)} 词条")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:  # noqa: BLE001
        print(f"[警告] 词典生成失败（App 将降级为 AI 查词）：{e}")
        sys.exit(1)
