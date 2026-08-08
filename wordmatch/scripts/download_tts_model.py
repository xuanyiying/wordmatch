#!/usr/bin/env python3
"""Download sherpa-onnx Piper TTS model files into Flutter assets.

Fetches the file tree from HuggingFace mirror and downloads every needed
file (onnx / tokens / espeak-ng-data/**) into
assets/tts/vits-piper-en_US-lessac-medium/, then writes a _manifest.txt
listing every relative path (one per line) for runtime asset extraction.
"""

import json
import os
import sys
import urllib.request
import urllib.parse
from concurrent.futures import ThreadPoolExecutor, as_completed

REPO = "csukuangfj/vits-piper-en_US-lessac-medium"
MIRROR = "https://hf-mirror.com"
DEST = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "assets", "tts", "vits-piper-en_US-lessac-medium",
)
SKIP_SUFFIXES = (".py", ".sh")
SKIP_NAMES = {".gitattributes", "MODEL_CARD", "README.md"}
# 仅保留英文字典；其他语言字典（ru_dict 8.5MB / cmn_dict 1.5MB / ar_dict 等）
# 在英文 TTS 下永不会被 espeak-ng 加载，跳过以节省 ~15MB APK 体积。
KEEP_DICTS = {"en_dict"}
CONCURRENCY = 8


def fetch_tree():
    url = f"{MIRROR}/api/models/{REPO}/tree/main?recursive=1"
    print(f"[tree] {url}")
    req = urllib.request.Request(url, headers={"User-Agent": "curl/8"})
    with urllib.request.urlopen(req, timeout=30) as r:
        data = json.loads(r.read())
    files = []
    for item in data:
        if item.get("type") != "file":
            continue
        path = item["path"]
        if os.path.basename(path) in SKIP_NAMES:
            continue
        if path.endswith(SKIP_SUFFIXES):
            continue
        # 跳过非英文语言字典（espeak-ng 英文 TTS 永不加载它们）
        if path.startswith("espeak-ng-data/") and path.endswith("_dict"):
            dict_name = os.path.basename(path)
            if dict_name not in KEEP_DICTS:
                continue
        files.append((path, item.get("size", 0)))
    return files


def download_one(path, size):
    dest = os.path.join(DEST, path)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    # Skip if already downloaded with correct size
    if os.path.exists(dest) and size and os.path.getsize(dest) == size:
        print(f"[skip] {path} ({size} bytes)")
        return path
    encoded = "/".join(urllib.parse.quote(p) for p in path.split("/"))
    url = f"{MIRROR}/{REPO}/resolve/main/{encoded}"
    print(f"[get ] {path} ({size} bytes)")
    req = urllib.request.Request(url, headers={"User-Agent": "curl/8"})
    resp = urllib.request.urlopen(req, timeout=120)
    with open(dest, "wb") as f:
        while True:
            chunk = resp.read(1024 * 256)
            if not chunk:
                break
            f.write(chunk)
    resp.close()
    return path


def main():
    os.makedirs(DEST, exist_ok=True)
    files = fetch_tree()
    total = sum(s for _, s in files)
    print(f"[info] {len(files)} files, {total / 1024 / 1024:.1f} MB total")

    done = []
    with ThreadPoolExecutor(max_workers=CONCURRENCY) as pool:
        futures = {pool.submit(download_one, p, s): p for p, s in files}
        for fut in as_completed(futures):
            try:
                done.append(fut.result())
            except Exception as e:
                print(f"[ERR] {futures[fut]}: {e}", file=sys.stderr)
                sys.exit(1)

    # Write manifest (relative paths, one per line, sorted for determinism)
    manifest = os.path.join(DEST, "_manifest.txt")
    with open(manifest, "w") as f:
        for p in sorted(done):
            f.write(p + "\n")
    print(f"[done] {len(done)}/{len(files)} files -> {DEST}")
    print(f"[manifest] {manifest}")


if __name__ == "__main__":
    main()
