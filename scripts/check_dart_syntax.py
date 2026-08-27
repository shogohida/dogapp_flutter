#!/usr/bin/env python3
"""check_dart_syntax.py

Dart SDKが利用できない環境(このサンドボックス)でも検出できる範囲の
構文チェックを行う。文字列リテラル・行コメント・ブロックコメントを
考慮しながら、丸括弧・波括弧・角括弧の対応が取れているかを検証する。

これは `dart analyze` の代替にはならない(型チェック・未使用import・
存在しないメンバー参照などは検出できない)。あくまで
「明らかな書き間違い(閉じ忘れ・余分な閉じ括弧)」を機械的に検出するための
簡易チェッカーであり、README にもその限界を明記している。
"""
import glob
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

PAIRS = {")": "(", "}": "{", "]": "["}
OPENERS = set(PAIRS.values())
CLOSERS = set(PAIRS.keys())


def check_file(path):
    with open(path, encoding="utf-8") as f:
        text = f.read()

    stack = []
    i = 0
    n = len(text)
    line = 1
    errors = []

    in_string = None  # None, "'", '"', "'''", '"""'
    in_line_comment = False
    in_block_comment = False
    is_raw_string = False

    while i < n:
        c = text[i]
        if c == "\n":
            line += 1
            in_line_comment = False
            i += 1
            continue

        if in_line_comment:
            i += 1
            continue

        if in_block_comment:
            if text[i:i+2] == "*/":
                in_block_comment = False
                i += 2
                continue
            i += 1
            continue

        if in_string:
            if not is_raw_string and c == "\\":
                i += 2
                continue
            if text[i:i+len(in_string)] == in_string:
                i += len(in_string)
                in_string = None
                is_raw_string = False
                continue
            i += 1
            continue

        # コメント開始
        if text[i:i+2] == "//":
            in_line_comment = True
            i += 2
            continue
        if text[i:i+2] == "/*":
            in_block_comment = True
            i += 2
            continue

        # raw文字列 (r'...' や r"...")
        if c == "r" and i + 1 < n and text[i+1] in ("'", '"'):
            quote = text[i+1]
            triple = text[i+1:i+4] == quote * 3
            in_string = quote * 3 if triple else quote
            is_raw_string = True
            i += 4 if triple else 2
            continue

        # 通常の文字列
        if c in ("'", '"'):
            triple = text[i:i+3] == c * 3
            in_string = c * 3 if triple else c
            is_raw_string = False
            i += 3 if triple else 1
            continue

        if c in OPENERS:
            stack.append((c, line))
        elif c in CLOSERS:
            expected_open = PAIRS[c]
            if not stack:
                errors.append(f"行{line}: 対応する開き括弧のない '{c}' があります")
            else:
                open_c, open_line = stack.pop()
                if open_c != expected_open:
                    errors.append(
                        f"行{line}: '{c}' が行{open_line}の '{open_c}' と対応していません"
                    )
        i += 1

    if stack:
        for open_c, open_line in stack:
            errors.append(f"行{open_line}: 閉じられていない '{open_c}' があります")

    return errors


def main():
    dart_files = sorted(glob.glob(os.path.join(ROOT, "lib", "**", "*.dart"), recursive=True))
    dart_files += sorted(glob.glob(os.path.join(ROOT, "test", "**", "*.dart"), recursive=True))

    total_errors = 0
    for path in dart_files:
        rel = os.path.relpath(path, ROOT)
        errors = check_file(path)
        if errors:
            print(f"FAIL {rel}")
            for e in errors:
                print(f"     {e}")
            total_errors += len(errors)
        else:
            print(f"OK   {rel}")

    print()
    print(f"チェック対象: {len(dart_files)}ファイル")
    if total_errors == 0:
        print("括弧・文字列リテラルの対応は全て正常です。")
        print("注: これは dart analyze の代替ではありません(型チェック等は行っていません)。")
    else:
        print(f"{total_errors} 件の問題が見つかりました。")
        sys.exit(1)


if __name__ == "__main__":
    main()
