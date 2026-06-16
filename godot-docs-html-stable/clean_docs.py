#!/usr/bin/env uv run
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "beautifulsoup4",
# ]
# ///
"""
清理 Godot HTML 文档，移除所有冗余，只保留 AI 查询需要的核心内容。

使用方法:
    uv run clean_docs.py                           # 清理所有 HTML
    uv run clean_docs.py --dry-run                 # 预览模式
    uv run clean_docs.py --target tutorials        # 只清理指定目录
    uv run clean_docs.py --workers 8               # 指定线程数（默认 CPU 核心数）

清理内容:
  [结构层] 侧边栏导航、RTD 版本浮层、面包屑、页脚、CSS/JS 引用
  [属性层] class / data-* / aria-* / style 等 AI 不需要的 HTML 属性
  [Meta层] 保留 title/description/doc_version，移除渲染/社交类 meta
  [空白层] 压缩多余空白行

执行效果（实测 1566 文件）:
  第 1 步: 原始 1945.9 MB → ~50 MB  (去除导航树, -97%)
  第 2 步: ~50 MB  → ~32 MB  (剥离 class 等属性, -36%)
  合计:    1945.9 MB → ~32 MB  (总量缩减 ~98.4%)
"""

import argparse
import concurrent.futures
import os
import re
import sys
import time
from pathlib import Path

HERE = Path(__file__).parent.resolve()

DOC_DIRS = [
    "about",
    "classes",
    "community",
    "engine_details",
    "getting_started",
    "tutorials",
]

# ── 需要保留的 meta name / property ──
KEEP_META = {
    "description",           # 页面描述
    "og:title",              # 页面标题
    "og:description",        # 页面描述（OG）
    "doc_version",           # Godot 版本号
    "doc_pagename",          # 页面路径标识
}

# ── 需要保留的 link ──
KEEP_LINK_RELS = {"index", "search", "next", "prev"}


# ============================================================
#  HTML 正则清理（快速，不经过 BS4）
# ============================================================

def _strip_attribute(html: str, attr_pattern: str) -> str:
    """移除匹配指定模式的 HTML 属性。"""
    return re.sub(
        rf'\s+{re.escape(attr_pattern)}"[^"]*"',
        "",
        html,
    )


def _strip_attributes_fast(html: str) -> str:
    """通过正则快速剥离冗余 HTML 属性。"""
    # 1. class 属性（最大头，占 ~32%）
    html = _strip_attribute(html, 'class="')
    # 2. data-* 属性
    html = re.sub(r'\s+data-[^=]*="[^"]*"', "", html)
    # 3. aria-* 属性
    html = re.sub(r'\s+aria-[^=]*="[^"]*"', "", html)
    # 4. style 属性
    html = re.sub(r'\s+style="[^"]*"', "", html)
    # 5. 空的属性（如 class="" 等）
    html = re.sub(r'\s+\w+=""', "", html)
    # 6. 压缩多余空白行
    html = re.sub(r'\n\s*\n', '\n', html)
    html = re.sub(r'^\s*\n', '', html, flags=re.MULTILINE)
    return html


def _filter_meta_fast(html: str) -> str:
    """筛选 meta 标签，只保留 AI 有用的。"""
    def _keep_meta(m: re.Match) -> str:
        tag = m.group(0)
        # 检查是否包含需要保留的属性
        for attr_name in KEEP_META:
            if f'="{attr_name}"' in tag or f"='{attr_name}'" in tag:
                return tag
        # charset 和 viewport 也保留（基本结构）
        if 'charset=' in tag or "name=\"viewport\"" in tag:
            return tag
        return ""  # 移除
    return re.sub(r'<meta[^>]*>', _keep_meta, html)


def _filter_links_fast(html: str) -> str:
    """筛选 link 标签，只保留 prev/next/index/search。"""
    def _keep_link(m: re.Match) -> str:
        tag = m.group(0)
        for rel in KEEP_LINK_RELS:
            if f'rel="{rel}"' in tag:
                return tag
        return ""
    return re.sub(r'<link[^>]*>', _keep_link, html)


# ============================================================
#  BS4 结构清理
# ============================================================

def _clean_structure(html: str) -> str:
    """通过 BeautifulSoup 移除大型结构性冗余元素。"""
    from bs4 import BeautifulSoup

    soup = BeautifulSoup(html, "html.parser")

    # ── 侧边栏 ──
    for nav in soup.select("nav.wy-nav-side"):
        nav.decompose()

    # ── RTD 版本/语言浮层 ──
    for div in soup.select("div.rst-versions"):
        div.decompose()

    # ── 移动端顶部导航 ──
    for nav in soup.select("nav.wy-nav-top"):
        nav.decompose()

    # ── 面包屑 ──
    for ul in soup.select("ul.wy-breadcrumbs"):
        ul.decompose()

    # ── 上一页/下一页 ──
    for div in soup.select("div.rst-footer-buttons"):
        div.decompose()

    # ── 版权页脚 ──
    for div in soup.select("div[role='contentinfo']"):
        div.decompose()

    # ── "Built with Sphinx" footer ──
    for footer in soup.select("footer"):
        footer.decompose()

    # ── 分隔线 ──
    for hr in soup.select("div.wy-nav-content hr"):
        hr.decompose()

    # ── CSS ──
    for link in soup.select('link[rel="stylesheet"]'):
        link.decompose()

    # ── JS ──
    for script in soup.select("script"):
        src = script.get("src", "")
        if src and (src.endswith(".js") or "_static" in src or "plausible" in src):
            script.decompose()
        elif not src:
            text = script.get_text(strip=True)
            if "SphinxRtdTheme" in text or "jQuery" in text:
                script.decompose()

    # ── 搜索表单 ──
    for form in soup.select("div.wy-side-nav-search"):
        form.decompose()

    # ── 导航残留空壳 ──
    for li in soup.select("li.toctree-l1, li.toctree-l2, li.toctree-l3"):
        li.decompose()

    # ── 空 ul/p ──
    for tag in soup.select("ul, p.caption"):
        if not tag.get_text(strip=True):
            tag.decompose()

    # ── theme-color meta ──
    for meta in soup.select('meta[name="theme-color"]'):
        meta.decompose()

    return str(soup)


# ============================================================
#  主清理函数
# ============================================================

def clean_html(html: str) -> str:
    """完整的 HTML 清理管线。"""
    # Step 1: BS4 结构清理
    html = _clean_structure(html)
    # Step 2: 正则快速剥离 class/data/aria/style 属性
    html = _strip_attributes_fast(html)
    # Step 3: 筛选 meta
    html = _filter_meta_fast(html)
    # Step 4: 筛选 link
    html = _filter_links_fast(html)
    return html


def clean_one(filepath: Path, dry_run: bool = False) -> dict:
    """清理单个文件。"""
    original_size = filepath.stat().st_size
    html = filepath.read_text(encoding="utf-8")
    cleaned = clean_html(html)
    cleaned_size = len(cleaned.encode("utf-8"))

    if not dry_run:
        filepath.write_text(cleaned, encoding="utf-8")

    return {
        "path": filepath,
        "original": original_size,
        "cleaned": cleaned_size,
        "saved": original_size - cleaned_size,
    }


def scan_html_files(root_dir: Path, target_subdir: str | None = None):
    """扫描所有待处理 HTML 文件。"""
    dirs = [target_subdir] if target_subdir else DOC_DIRS
    files = []
    for d in dirs:
        search_dir = root_dir / d
        if not search_dir.is_dir():
            print(f"  ⚠ 跳过不存在目录: {search_dir}")
            continue
        for fpath in sorted(search_dir.rglob("*.html")):
            files.append(fpath)
    return files


# ============================================================
#  CLI
# ============================================================

def main():
    parser = argparse.ArgumentParser(
        description="清理 Godot HTML 文档中的冗余元素"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="预览模式，不写文件",
    )
    parser.add_argument(
        "--target",
        type=str,
        default=None,
        help="只清理指定子目录（如 tutorials）",
    )
    parser.add_argument(
        "--workers",
        type=int,
        default=os.cpu_count() or 4,
        help=f"并行线程数（默认 CPU 核心数: {os.cpu_count() or 4}）",
    )
    args = parser.parse_args()

    files = scan_html_files(HERE, args.target)
    if not files:
        print("未找到需要处理的 HTML 文件。")
        sys.exit(0)

    print(f"发现 {len(files)} 个文件，使用 {args.workers} 个线程并行处理...\n")

    total_original = 0
    total_cleaned = 0
    start_time = time.time()

    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as executor:
        futures = {
            executor.submit(clean_one, fpath, dry_run=args.dry_run): fpath
            for fpath in files
        }
        done = 0
        for future in concurrent.futures.as_completed(futures):
            done += 1
            result = future.result()
            total_original += result["original"]
            total_cleaned += result["cleaned"]

            rel = result["path"].relative_to(HERE)
            ratio = result["saved"] / result["original"] * 100 if result["original"] > 0 else 0
            action = "DRY-RUN" if args.dry_run else "OK"
            print(
                f"  [{action}] ({done:4d}/{len(files)}) "
                f"{rel}  "
                f"{result['original']/1024:.0f} KB → {result['cleaned']/1024:.0f} KB  "
                f"(-{ratio:.0f}%)"
            )

    elapsed = time.time() - start_time
    saved = total_original - total_cleaned
    print()
    print(f"{'='*60}")
    print(f"  文件数:      {len(files)}")
    print(f"  原始大小:    {total_original/1024/1024:.1f} MB")
    print(f"  清理后大小:  {total_cleaned/1024/1024:.1f} MB")
    print(f"  节省空间:    {saved/1024/1024:.1f} MB ({saved*100/total_original:.0f}%)")
    print(f"  耗时:        {elapsed:.1f} 秒")
    if args.dry_run:
        print(f"  [DRY-RUN 模式] 未实际写入任何文件。")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
