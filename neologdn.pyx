# cython: language_level=3
# -*- coding: utf-8 -*-
from __future__ import unicode_literals

import itertools
from sys import version_info

# Import modern Unicode creation helpers
from cpython.unicode cimport PyUnicode_FromKindAndData, PyUnicode_4BYTE_KIND
from libc.stdlib cimport malloc, free

VERSION = (0, 5, 1)
__version__ = '0.5.1'

##################################################
# Define all your character conversion data
##################################################

ASCII = (
    ('ａ', 'a'), ('ｂ', 'b'), ('ｃ', 'c'), ('ｄ', 'd'), ('ｅ', 'e'),
    ('ｆ', 'f'), ('ｇ', 'g'), ('ｈ', 'h'), ('ｉ', 'i'), ('ｊ', 'j'),
    ('ｋ', 'k'), ('ｌ', 'l'), ('ｍ', 'm'), ('ｎ', 'n'), ('ｏ', 'o'),
    ('ｐ', 'p'), ('ｑ', 'q'), ('ｒ', 'r'), ('ｓ', 's'), ('ｔ', 't'),
    ('ｕ', 'u'), ('ｖ', 'v'), ('ｗ', 'w'), ('ｘ', 'x'), ('ｙ', 'y'),
    ('ｚ', 'z'),
    ('Ａ', 'A'), ('Ｂ', 'B'), ('Ｃ', 'C'), ('Ｄ', 'D'), ('Ｅ', 'E'),
    ('Ｆ', 'F'), ('Ｇ', 'G'), ('Ｈ', 'H'), ('Ｉ', 'I'), ('Ｊ', 'J'),
    ('Ｋ', 'K'), ('Ｌ', 'L'), ('Ｍ', 'M'), ('Ｎ', 'N'), ('Ｏ', 'O'),
    ('Ｐ', 'P'), ('Ｑ', 'Q'), ('Ｒ', 'R'), ('Ｓ', 'S'), ('Ｔ', 'T'),
    ('Ｕ', 'U'), ('Ｖ', 'V'), ('Ｗ', 'W'), ('Ｘ', 'X'), ('Ｙ', 'Y'),
    ('Ｚ', 'Z'),
    ('！', '!'), ('”', '"'), ('＃', '#'), ('＄', '$'), ('％', '%'),
    ('＆', '&'), ('’', '\''), ('（', '('), ('）', ')'), ('＊', '*'),
    ('＋', '+'), ('，', ','), ('−', '-'), ('．', '.'), ('／', '/'),
    ('：', ':'), ('；', ';'), ('＜', '<'), ('＝', '='), ('＞', '>'),
    ('？', '?'), ('＠', '@'), ('［', '['), ('¥', '\\'), ('］', ']'),
    ('＾', '^'), ('＿', '_'), ('‘', '`'), ('｛', '{'), ('｜', '|'),
    ('｝', '}')
)
KANA = (
    ('ｱ', 'ア'), ('ｲ', 'イ'), ('ｳ', 'ウ'), ('ｴ', 'エ'), ('ｵ', 'オ'),
    ('ｶ', 'カ'), ('ｷ', 'キ'), ('ｸ', 'ク'), ('ｹ', 'ケ'), ('ｺ', 'コ'),
    ('ｻ', 'サ'), ('ｼ', 'シ'), ('ｽ', 'ス'), ('ｾ', 'セ'), ('ｿ', 'ソ'),
    ('ﾀ', 'タ'), ('ﾁ', 'チ'), ('ﾂ', 'ツ'), ('ﾃ', 'テ'), ('ﾄ', 'ト'),
    ('ﾅ', 'ナ'), ('ﾆ', 'ニ'), ('ﾇ', 'ヌ'), ('ﾈ', 'ネ'), ('ﾉ', 'ノ'),
    ('ﾊ', 'ハ'), ('ﾋ', 'ヒ'), ('ﾌ', 'フ'), ('ﾍ', 'ヘ'), ('ﾎ', 'ホ'),
    ('ﾏ', 'マ'), ('ﾐ', 'ミ'), ('ﾑ', 'ム'), ('ﾒ', 'メ'), ('ﾓ', 'モ'),
    ('ﾔ', 'ヤ'), ('ﾕ', 'ユ'), ('ﾖ', 'ヨ'),
    ('ﾗ', 'ラ'), ('ﾘ', 'リ'), ('ﾙ', 'ル'), ('ﾚ', 'レ'), ('ﾛ', 'ロ'),
    ('ﾜ', 'ワ'), ('ｦ', 'ヲ'), ('ﾝ', 'ン'),
    ('ｧ', 'ァ'), ('ｨ', 'ィ'), ('ｩ', 'ゥ'), ('ｪ', 'ェ'), ('ｫ', 'ォ'),
    ('ｯ', 'ッ'), ('ｬ', 'ャ'), ('ｭ', 'ュ'), ('ｮ', 'ョ'),
    ('｡', '。'), ('､', '、'), ('･', '・'), ('゛', 'ﾞ'), ('゜', 'ﾟ'),
    ('｢', '「'), ('｣', '」'), ('ｰ', 'ー')
)
DIGIT = (
    ('０', '0'), ('１', '1'), ('２', '2'), ('３', '3'), ('４', '4'),
    ('５', '5'), ('６', '6'), ('７', '7'), ('８', '8'), ('９', '9')
)
KANA_TEN = (
    ('カ', 'ガ'), ('キ', 'ギ'), ('ク', 'グ'), ('ケ', 'ゲ'), ('コ', 'ゴ'),
    ('サ', 'ザ'), ('シ', 'ジ'), ('ス', 'ズ'), ('セ', 'ゼ'), ('ソ', 'ゾ'),
    ('タ', 'ダ'), ('チ', 'ヂ'), ('ツ', 'ヅ'), ('テ', 'デ'), ('ト', 'ド'),
    ('ハ', 'バ'), ('ヒ', 'ビ'), ('フ', 'ブ'), ('ヘ', 'ベ'), ('ホ', 'ボ'),
    ('ウ', 'ヴ'), ('う', 'ゔ')
)
KANA_MARU = (
    ('ハ', 'パ'), ('ヒ', 'ピ'), ('フ', 'プ'), ('ヘ', 'ぺ'), ('ホ', 'ポ'),
    ('は', 'ぱ'), ('ひ', 'ぴ'), ('ふ', 'ぷ'), ('へ', 'ぺ'), ('ほ', 'ぽ')
)

HIPHENS = ('˗', '֊', '‐', '‑', '‒', '–', '⁃', '⁻', '₋', '−')
CHOONPUS = ('﹣', '－', 'ｰ', '—', '―', '─', '━', 'ー')
TILDES = ('~', '∼', '∾', '〜', '〰', '～')
SPACE = (' ', '　')

##################################################
# Build Python-level dicts/sets for mapping and membership
##################################################

conversion_map = {}
for (before, after) in (ASCII + DIGIT + KANA):
    conversion_map[before] = after

kana_ten_map = {}
for (before, after) in KANA_TEN:
    kana_ten_map[before] = after

kana_maru_map = {}
for (before, after) in KANA_MARU:
    kana_maru_map[before] = after

blocks = set()
basic_latin = set()

for codepoint in itertools.chain(
    range(19968, 40960),  # CJK UNIFIED IDEOGRAPHS
    range(12352, 12448),  # HIRAGANA
    range(12448, 12544),  # KATAKANA
    range(12289, 12352),  # CJK SYMBOLS AND PUNCTUATION
    range(65280, 65520)   # HALFWIDTH AND FULLWIDTH FORMS
):
    blocks.add(chr(codepoint))

for codepoint in range(128):
    basic_latin.add(chr(codepoint))

##################################################
# Helper function: shorten repeated substrings
##################################################

cpdef unicode shorten_repeat(unicode text, int repeat_threshould,
                             int max_repeat_substr_length=8):
    cdef int text_length, i, repeat_length, right_start, right_end
    cdef int num_repeat_substrs, upper_repeat_substr_length
    cdef unicode substr, right_substr

    i = 0
    while i < len(text):
        text_length = len(text)
        upper_repeat_substr_length = (text_length - i) // 2
        if max_repeat_substr_length and max_repeat_substr_length < upper_repeat_substr_length:
            upper_repeat_substr_length = max_repeat_substr_length + 1

        for repeat_length in range(1, upper_repeat_substr_length):
            substr = text[i : i + repeat_length]
            right_start = i + repeat_length
            right_end = right_start + repeat_length
            right_substr = text[right_start:right_end]
            num_repeat_substrs = 1
            while substr == right_substr and right_end <= text_length:
                num_repeat_substrs += 1
                right_start += repeat_length
                right_end += repeat_length
                right_substr = text[right_start:right_end]
            if num_repeat_substrs > repeat_threshould:
                text = (text[: i + repeat_length * repeat_threshould] +
                        text[i + repeat_length * num_repeat_substrs :])
        i += 1
    return text


##################################################
# Main normalize function using Py_UCS4 and PyUnicode_FromKindAndData
##################################################

cpdef unicode normalize(unicode text,
                        int repeat = 0,
                        bint remove_space = True,
                        int max_repeat_substr_length = 8,
                        unicode tilde = u'remove'):
    """
    Normalize text with membership checks at the Python level,
    but store the final results in a Py_UCS4* buffer.
    Then build the final string with PyUnicode_FromKindAndData.
    """
    cdef:
        Py_UCS4* buf = <Py_UCS4*>malloc(sizeof(Py_UCS4) * (len(text) + 1))
        Py_UCS4 c_prev = 0
        Py_UCS4 c
        int pos = 0
        bint lattin_space = False

    if not buf:
        raise MemoryError("Failed to allocate memory for 'normalize' buffer.")

    for ch in text:
        # Get the code point for ch
        c = <Py_UCS4> ord(ch)

        # 1) If the character is a space
        if ch in SPACE:
            c = <Py_UCS4> ord(' ')
            # Use an explicit cast (<int>) for the left-hand side to avoid the warning.
            if pos > 0 and (<int> buf[pos - 1]) == ord(' ') or (chr(c_prev) in blocks and remove_space):
                continue
            elif c_prev != <Py_UCS4> ord('*') and pos > 0 and (chr(c_prev) in basic_latin):
                lattin_space = True
                buf[pos] = c
            elif remove_space and pos > 0:
                pos -= 1
            else:
                buf[pos] = c

        # 2) Hyphens: unify to '-'
        elif ch in HIPHENS:
            if c_prev == <Py_UCS4> ord('-'):
                continue
            else:
                c = <Py_UCS4> ord('-')
                buf[pos] = c

        # 3) Choonpus: unify to 'ー'
        elif ch in CHOONPUS:
            if c_prev == <Py_UCS4> ord('ー'):
                continue
            else:
                c = <Py_UCS4> ord('ー')
                buf[pos] = c

        # 4) Tildes: based on the tilde argument
        elif ch in TILDES:
            if tilde == u'ignore':
                buf[pos] = c
            elif tilde == u'normalize':
                c = <Py_UCS4> ord('~')
                buf[pos] = c
            elif tilde == u'normalize_zenkaku':
                c = <Py_UCS4> ord('〜')
                buf[pos] = c
            else:
                continue

        # 5) Otherwise: perform conversion
        else:
            if ch in conversion_map:
                c = <Py_UCS4> ord(conversion_map[ch])
            if c == <Py_UCS4> ord('ﾞ') and pos > 0 and (chr(c_prev) in kana_ten_map):
                pos -= 1
                combined = kana_ten_map[chr(c_prev)]
                c = <Py_UCS4> ord(combined[0])
                buf[pos] = c
            elif c == <Py_UCS4> ord('ﾟ') and pos > 0 and (chr(c_prev) in kana_maru_map):
                pos -= 1
                combined = kana_maru_map[chr(c_prev)]
                c = <Py_UCS4> ord(combined[0])
                buf[pos] = c
            else:
                if lattin_space and (chr(c) in blocks) and remove_space and pos > 0:
                    pos -= 1
                lattin_space = False
                buf[pos] = c

        c_prev = buf[pos]
        pos += 1

    # If final character is space, remove it (use explicit cast to int)
    if pos > 0 and (<int> buf[pos - 1]) == ord(' '):
        pos -= 1

    # Build the final Python Unicode object from the 4-byte UCS4 code units.
    # Store the result in a Python object (which safely holds a reference).
    cdef object py_obj = PyUnicode_FromKindAndData(
        PyUnicode_4BYTE_KIND,
        <const void*> buf,
        pos
    )

    free(buf)

    if py_obj is None:
        raise MemoryError("Failed to create Python string from UCS4 data.")

    # Optionally apply the repeat logic.
    if repeat > 0:
        return shorten_repeat(py_obj, repeat, max_repeat_substr_length)
    return py_obj
