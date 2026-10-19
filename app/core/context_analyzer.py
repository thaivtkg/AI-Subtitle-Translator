"""
ContextAnalyzer: 100% Offline Entity & Archetype Classifier.
Analyzes story summaries to extract glossary entities and determine character archetypes
with pronoun biasing using regex and keyword scoring without external dependencies.
"""

from __future__ import annotations

import re
from typing import Any

# --- Archetype Identifiers ---
ARCHETYPE_ANCIENT_FANTASY = "ancient_fantasy"
ARCHETYPE_ANIME_SCHOOL = "anime_school"
ARCHETYPE_MODERN_ACTION = "modern_action"
ARCHETYPE_ROMANCE_FAMILY = "romance_family"
ARCHETYPE_CUSTOM = "custom"

# --- Default Pronoun Pair Mappings ---
DEFAULT_PRONOUNS: dict[str, str] = {
    ARCHETYPE_ANCIENT_FANTASY: "Ta - Ngươi",
    ARCHETYPE_ANIME_SCHOOL: "Tớ - Cậu",
    ARCHETYPE_MODERN_ACTION: "Tôi - Bạn",
    ARCHETYPE_ROMANCE_FAMILY: "Anh - Em",
    ARCHETYPE_CUSTOM: "Tự do (Theo ngữ cảnh)",
}

# --- Archetype Metadata (Used by UI Header Capsule & Dropdowns) ---
ARCHETYPE_METADATA: dict[str, dict[str, Any]] = {
    ARCHETYPE_ANCIENT_FANTASY: {
        "id": ARCHETYPE_ANCIENT_FANTASY,
        "name": "Cổ Trang / Kiếm Hiệp",
        "pronouns": "Ta - Ngươi",
        "icon": "⚔️",
    },
    ARCHETYPE_ANIME_SCHOOL: {
        "id": ARCHETYPE_ANIME_SCHOOL,
        "name": "Anime / Học Đường",
        "pronouns": "Tớ - Cậu",
        "icon": "🌸",
    },
    ARCHETYPE_MODERN_ACTION: {
        "id": ARCHETYPE_MODERN_ACTION,
        "name": "Hiện Đại / Hành Động",
        "pronouns": "Tôi - Bạn",
        "icon": "🔫",
    },
    ARCHETYPE_ROMANCE_FAMILY: {
        "id": ARCHETYPE_ROMANCE_FAMILY,
        "name": "Tình Cảm / Gia Đình",
        "pronouns": "Anh - Em",
        "icon": "❤️",
    },
    ARCHETYPE_CUSTOM: {
        "id": ARCHETYPE_CUSTOM,
        "name": "Tự Do",
        "pronouns": "Theo ngữ cảnh",
        "icon": "🎭",
    },
}

ARCHETYPE_LIST: list[dict[str, Any]] = list(ARCHETYPE_METADATA.values())

# Stopwords to filter out metadata fields or generic noise in summary
STOPWORDS: set[str] = {
    "phim", "tập", "thể loại", "diễn viên", "đạo diễn", "nội dung", "tóm tắt",
    "phần", "tác giả", "nhân vật", "năm", "mùa", "season", "episode", "chapter",
}

# Pair definition pattern:
# Matches: "Source": Target, "Source" -> Target, Source => Target, Source là Target
PAIR_PATTERN = re.compile(
    r'(?:["“]([^"”\n]+)["”]|([\w\-\s\u3040-\u30ff\u4e00-\u9fff]{2,}))\s*(?::|->|=>|→|\blà\b)\s*(?:["“]([^"”\n]+)["”]|([^\n,;.]+))',
    re.IGNORECASE,
)

# Brackets & Quotes pattern:
# Western quotes "...", “...”, CJK brackets 「...」, 『...』, 【...】, 《...》
BRACKET_PATTERN = re.compile(
    r'["“]([^"”\n]{2,})["”]|[「『【《]([^」』】》\n]{2,})[」』】》]'
)

# Katakana pattern (Japanese names/terms, min 2 characters)
KATAKANA_PATTERN = re.compile(r'[\u30A0-\u30FF]{2,}')

# Keyword dictionaries for scoring
ARCHETYPE_KEYWORDS: dict[str, list[str]] = {
    ARCHETYPE_ANCIENT_FANTASY: [
        "tu tiên", "cổ trang", "kiếm hiệp", "võ lâm", "tông môn", "phi kiếm", "sư huynh",
        "sư muội", "sư phụ", "chưởng môn", "hoàng đế", "bệ hạ", "thần tiên", "tiên hiệp",
        "ma giáo", "đạo hữu", "yêu ma", "linh khí", "đan dược", "công pháp", "tiên môn",
    ],
    ARCHETYPE_ANIME_SCHOOL: [
        "học đường", "học sinh", "trường học", "nữ sinh", "nam sinh", "thanh xuân",
        "senpai", "kouhai", "anime", "clb", "manga", "ma pháp", "chuyển sinh", "isekai",
    ],
    ARCHETYPE_MODERN_ACTION: [
        "cảnh sát", "đặc nhiệm", "điệp viên", "bắn tỉa", "trực thăng", "tội phạm",
        "truy kích", "súng", "chiến tranh", "thám tử", "sát thủ", "đặc vụ", "quân đội",
    ],
    ARCHETYPE_ROMANCE_FAMILY: [
        "lãng mạn", "tổng tài", "ngôn tình", "kết hôn", "hôn nhân", "gia đình",
        "yêu đương", "tình cảm", "vợ chồng", "hẹn hò", "bạn gái", "bạn trai",
    ],
}

# Tech keywords for anti-collision (suppresses ancient fantasy false positives)
TECH_KEYWORDS: list[str] = [
    "lập trình", "lập trình viên", "bug", "code", "máy tính", "server", "hệ thống máy tính",
    "tin học", "phần mềm", "source code", "developer", "cntt", "it",
]


def extract_entities(text: str, source_lang: str = "") -> list[dict[str, Any]]:
    """
    Extracts terms and definitions from story summary offline.
    Returns list of dicts with keys: source_term, preferred_translation, is_auto.
    """
    if not text or not text.strip():
        return []

    results: list[dict[str, Any]] = []
    seen_terms_lower: set[str] = set()

    def _is_valid_term(term: str) -> bool:
        t = term.strip()
        if len(t) < 2:
            return False
        if t.isdigit():
            return False
        if t.lower() in STOPWORDS:
            return False
        return True

    def _add_entity(src: str, target: str):
        cleaned_src = src.strip().strip('"“\'')
        cleaned_target = target.strip().strip('"“\'')
        if not _is_valid_term(cleaned_src):
            return
        if not cleaned_target:
            cleaned_target = cleaned_src

        src_key = cleaned_src.lower()
        if src_key not in seen_terms_lower:
            seen_terms_lower.add(src_key)
            results.append({
                "source_term": cleaned_src,
                "preferred_translation": cleaned_target,
                "is_auto": True,
            })

    # 1. Extract Explicit Pair Definitions (Line by Line for accuracy)
    for line in text.splitlines():
        line_clean = line.strip()
        if not line_clean:
            continue
        for match in PAIR_PATTERN.finditer(line_clean):
            src = match.group(1) or match.group(2)
            target = match.group(3) or match.group(4)
            if src and target:
                _add_entity(src, target)

    # 2. Extract Quoted or CJK Bracketed Single Entities
    for match in BRACKET_PATTERN.finditer(text):
        term = match.group(1) or match.group(2)
        if term:
            _add_entity(term, term)

    # 3. Extract Katakana Entities
    for match in KATAKANA_PATTERN.finditer(text):
        term = match.group(0)
        if term:
            _add_entity(term, term)

    return results


def classify_archetype(text: str) -> tuple[str, str]:
    """
    Classifies summary text into a character archetype and default pronoun pair.
    Returns: (archetype_id, pronoun_pair)
    """
    if not text or not text.strip():
        return ARCHETYPE_CUSTOM, DEFAULT_PRONOUNS[ARCHETYPE_CUSTOM]

    lower_text = text.lower()
    has_tech = any(kw in lower_text for kw in TECH_KEYWORDS)

    scores: dict[str, int] = {archetype: 0 for archetype in ARCHETYPE_KEYWORDS}

    for archetype, keywords in ARCHETYPE_KEYWORDS.items():
        for kw in keywords:
            if kw in lower_text:
                scores[archetype] += 1

    # Anti-collision filter: tech words suppress ancient fantasy and boost modern action
    if has_tech:
        scores[ARCHETYPE_ANCIENT_FANTASY] = 0
        scores[ARCHETYPE_MODERN_ACTION] += 5

    best_archetype, best_score = max(scores.items(), key=lambda item: item[1])

    if best_score == 0:
        return ARCHETYPE_CUSTOM, DEFAULT_PRONOUNS[ARCHETYPE_CUSTOM]

    return best_archetype, DEFAULT_PRONOUNS.get(best_archetype, DEFAULT_PRONOUNS[ARCHETYPE_CUSTOM])


def analyze_context(text: str, source_lang: str = "") -> dict[str, Any]:
    """
    Convenience wrapper returning archetype, pronouns, and extracted entities.
    """
    archetype, pronouns = classify_archetype(text)
    entities = extract_entities(text, source_lang)
    return {
        "archetype": archetype,
        "pronouns": pronouns,
        "entities": entities,
    }


class ContextAnalyzer:
    """Class wrapper providing static access to analysis methods."""
    ARCHETYPE_ANCIENT_FANTASY = ARCHETYPE_ANCIENT_FANTASY
    ARCHETYPE_ANIME_SCHOOL = ARCHETYPE_ANIME_SCHOOL
    ARCHETYPE_MODERN_ACTION = ARCHETYPE_MODERN_ACTION
    ARCHETYPE_ROMANCE_FAMILY = ARCHETYPE_ROMANCE_FAMILY
    ARCHETYPE_CUSTOM = ARCHETYPE_CUSTOM

    DEFAULT_PRONOUNS = DEFAULT_PRONOUNS
    ARCHETYPE_METADATA = ARCHETYPE_METADATA
    ARCHETYPE_LIST = ARCHETYPE_LIST

    @staticmethod
    def extract_entities(text: str, source_lang: str = "") -> list[dict[str, Any]]:
        return extract_entities(text, source_lang)

    @staticmethod
    def classify_archetype(text: str) -> tuple[str, str]:
        return classify_archetype(text)

    @staticmethod
    def analyze_context(text: str, source_lang: str = "") -> dict[str, Any]:
        return analyze_context(text, source_lang)
