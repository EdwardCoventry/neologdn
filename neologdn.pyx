# distutils: language=c++
# cython: language_level=3
# -*- coding: utf-8 -*-

from __future__ import unicode_literals

### Cython / C++ imports
from libc.stdlib cimport malloc, free
from libcpp.unordered_map cimport unordered_map
from libcpp.unordered_set cimport unordered_set

### Python imports
import itertools
from sys import version_info

# Import the 4-byte builder for Python unicode
from cpython.unicode cimport (
    PyUnicode_FromKindAndData,  # to build Unicode directly from a codepoint array
    PyUnicode_4BYTE_KIND
)

VERSION = (0, 5, 1)
__version__ = '0.5.1'

##################################################
# Define character conversion data (Python level)
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
    ('ハ', 'パ'), ('ヒ', 'ピ'), ('フ', 'プ'), ('ヘ', 'ペ'), ('ホ', 'ポ'),
    ('は', 'ぱ'), ('ひ', 'ぴ'), ('ふ', 'ぷ'), ('へ', 'ぺ'), ('ほ', 'ぽ')
)

HIPHENS = ('˗', '֊', '‐', '‑', '‒', '–', '⁃', '⁻', '₋', '−')
CHOONPUS = ('﹣', '－', 'ｰ', '—', '―', '─', '━', 'ー')
TILDES = ('~', '∼', '∾', '〜', '〰', '～')
SPACE = (' ', '　')

##################################################
# We will store code points in the C++ containers
##################################################

cdef unordered_map[Py_UCS4, Py_UCS4] conversion_map
cdef unordered_map[Py_UCS4, Py_UCS4] kana_ten_map
cdef unordered_map[Py_UCS4, Py_UCS4] kana_maru_map

cdef unordered_set[Py_UCS4] blocks
cdef unordered_set[Py_UCS4] basic_latin

# Fill conversion_map with code points (ord)
for (before, after) in (ASCII + DIGIT + KANA):
    conversion_map[ord(before[0])] = <Py_UCS4>ord(after[0])

# Fill kana_ten_map
for (before, after) in KANA_TEN:
    kana_ten_map[ord(before[0])] = <Py_UCS4>ord(after[0])

# Fill kana_maru_map
for (before, after) in KANA_MARU:
    kana_maru_map[ord(before[0])] = <Py_UCS4>ord(after[0])

# Insert code points for the main CJK/Hiragana/Katakana blocks, etc.
for codepoint in itertools.chain(
    range(19968, 40960),  # CJK UNIFIED IDEOGRAPHS
    range(12352, 12448),  # HIRAGANA
    range(12448, 12544),  # KATAKANA
    range(12289, 12352),  # CJK SYMBOLS AND PUNCTUATION
    range(65280, 65520)   # HALFWIDTH AND FULLWIDTH FORMS
):
    blocks.insert(<Py_UCS4>codepoint)

# Insert code points for basic ASCII (0..127)
for codepoint in range(128):
    basic_latin.insert(<Py_UCS4>codepoint)

##################################################
# shorten_repeat (identical to old logic)
##################################################
cpdef unicode shorten_repeat(unicode text, int repeat_threshould, int max_repeat_substr_length=8):
    """
    Identical logic from old code, line-by-line.
    """
    cdef int text_length, i, repeat_length, right_start, right_end
    cdef int num_repeat_substrs, upper_repeat_substr_length
    cdef unicode substr, right_substr

    i = 0
    while i < len(text):
        text_length = len(text)
        # The maximum repeated substring length to check
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
# normalize with identical line-by-line logic
# but store the final text in a Py_UCS4* buffer
# and use the C++ sets for membership checks.
##################################################
cpdef unicode normalize(
    unicode text,
    int repeat = 0,
    bint remove_space = True,
    int max_repeat_substr_length = 8,
    unicode tilde = u'remove'
):
    """
    Replicate the old logic line by line, but:
    - Use an allocated Py_UCS4* buffer.
    - Use blocks.count(...) etc. instead of (chr(...) in blocks).
    """
    cdef Py_ssize_t length = len(text)
    # Allocate a Py_UCS4 buffer with length+1 for trailing null
    cdef Py_UCS4* buf = <Py_UCS4*> malloc(sizeof(Py_UCS4) * (length + 1))
    if not buf:
        raise MemoryError("Failed to allocate memory for 'normalize' buffer.")

    cdef int pos = 0
    cdef bint lattin_space = False
    cdef Py_UCS4 c
    # c_prev is an int to match "old" code's usage (for membership checks).
    cdef int c_prev = 0

    for ch in text:
        c = <Py_UCS4> ord(ch)

        #################################
        # (1) If the character is a space
        #################################
        if ch in SPACE:
            c = <Py_UCS4> ord(' ')

            # -- FIX: skip leading spaces if remove_space is True and we've stored nothing yet
            if remove_space and pos == 0:
                continue

            # if pos>0 and last stored was space, skip repeated space if remove_space or
            # previous was in blocks
            if pos > 0 and <int> buf[pos - 1] == ord(' '):
                if remove_space or (blocks.count(<Py_UCS4> c_prev) != 0):
                    continue

            elif c_prev != ord('*') and pos > 0 and basic_latin.count(<Py_UCS4> c_prev) != 0:
                lattin_space = True
                buf[pos] = c

            elif remove_space and pos > 0:
                pos -= 1
            else:
                buf[pos] = c

        ########################
        # (2) Hyphens => '-'
        ########################
        elif ch in HIPHENS:
            if c_prev == ord('-'):
                continue
            else:
                c = <Py_UCS4>ord('-')
                buf[pos] = c

        ########################
        # (3) Choonpus => 'ー'
        ########################
        elif ch in CHOONPUS:
            if c_prev == ord('ー'):
                continue
            else:
                c = <Py_UCS4>ord('ー')
                buf[pos] = c

        ########################
        # (4) Tildes
        ########################
        elif ch in TILDES:
            if tilde == u'ignore':
                buf[pos] = c
            elif tilde == u'normalize':
                c = <Py_UCS4>ord('~')
                buf[pos] = c
            elif tilde == u'normalize_zenkaku':
                c = <Py_UCS4>ord('〜')
                buf[pos] = c
            else:
                # "remove" => skip
                continue

        ########################
        # (5) Otherwise: conversions
        ########################
        else:
            if conversion_map.count(c) != 0:
                c = conversion_map[c]

            if c == ord('ﾞ') and pos > 0 and kana_ten_map.count(<Py_UCS4>c_prev) != 0:
                pos -= 1
                c = kana_ten_map[<Py_UCS4>c_prev]
                buf[pos] = c

            elif c == ord('ﾟ') and pos > 0 and kana_maru_map.count(<Py_UCS4>c_prev) != 0:
                pos -= 1
                c = kana_maru_map[<Py_UCS4>c_prev]
                buf[pos] = c

            else:
                if lattin_space and blocks.count(c) != 0 and remove_space and pos > 0:
                    pos -= 1

                lattin_space = False
                buf[pos] = c

        # Update c_prev from the newly stored character
        c_prev = <int> buf[pos]
        pos += 1

    #################################
    # If final character is ' ', remove it
    #################################
    if pos > 0 and <int>buf[pos - 1] == ord(' '):
        pos -= 1

    # Put a null terminator
    buf[pos] = 0

    # Build the final Python Unicode object from the 4-byte buffer
    cdef object py_obj = PyUnicode_FromKindAndData(
        PyUnicode_4BYTE_KIND,
        <const void*> buf,
        pos
    )
    cdef unicode out = <unicode>py_obj

    free(buf)

    # Apply repeat-shortening if needed
    if repeat > 0:
        return shorten_repeat(out, repeat, max_repeat_substr_length)
    return out
