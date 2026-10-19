import pytest
from app.core.context_analyzer import (
    ARCHETYPE_ANCIENT_FANTASY,
    ARCHETYPE_ANIME_SCHOOL,
    ARCHETYPE_MODERN_ACTION,
    ARCHETYPE_ROMANCE_FAMILY,
    ARCHETYPE_CUSTOM,
    DEFAULT_PRONOUNS,
    ARCHETYPE_METADATA,
    extract_entities,
    classify_archetype,
    analyze_context,
)


def test_archetype_constants_and_metadata():
    assert len(ARCHETYPE_METADATA) == 5
    assert DEFAULT_PRONOUNS[ARCHETYPE_ANCIENT_FANTASY] == "Ta - Ngươi"
    assert DEFAULT_PRONOUNS[ARCHETYPE_ANIME_SCHOOL] == "Em - Tiền bối"
    assert DEFAULT_PRONOUNS[ARCHETYPE_MODERN_ACTION] == "Tôi - Bạn"
    assert DEFAULT_PRONOUNS[ARCHETYPE_ROMANCE_FAMILY] == "Anh - Em"
    assert DEFAULT_PRONOUNS[ARCHETYPE_CUSTOM] == "Tự do (Theo ngữ cảnh)"


def test_extract_pair_definitions():
    text = """
    "Xiao Yan": Tiêu Viêm
    "Master Yao" -> Dược Lão
    Naruto => Uzumaki Naruto
    Aizen là Lam Nhiễm
    """
    entities = extract_entities(text)
    lookup = {e["source_term"]: e["preferred_translation"] for e in entities}
    assert lookup.get("Xiao Yan") == "Tiêu Viêm"
    assert lookup.get("Master Yao") == "Dược Lão"
    assert lookup.get("Naruto") == "Uzumaki Naruto"
    assert lookup.get("Aizen") == "Lam Nhiễm"
    for e in entities:
        assert e["is_auto"] is True


def test_extract_quotes_and_cjk_brackets():
    text = """
    Nhân vật chính "Soul Society" cùng “Kurotsuchi” nghiên cứu 「Bankai」.
    Bảo vật 『Shinigami』 và ấn ký 【Zanpakuto】 được ghi chép trong 《Hokage》.
    """
    entities = extract_entities(text)
    terms = [e["source_term"] for e in entities]
    assert "Soul Society" in terms
    assert "Kurotsuchi" in terms
    assert "Bankai" in terms
    assert "Shinigami" in terms
    assert "Zanpakuto" in terms
    assert "Hokage" in terms
    for e in entities:
        assert e["preferred_translation"] == e["source_term"]


def test_extract_katakana_terms():
    text = "Cuộc phiêu lưu của ナルト trong thế giới サイバーパンク đầy cạm bẫy."
    entities = extract_entities(text)
    terms = [e["source_term"] for e in entities]
    assert "ナルト" in terms
    assert "サイバーパンク" in terms


def test_sanitize_and_stopwords_filtering():
    text = """
    Phim: 123
    Tập: a
    Thể loại: Kiếm hiệp
    "Xiao Yan": Tiêu Viêm
    xiao yan: Tiêu Viêm Nhỏ
    """
    entities = extract_entities(text)
    terms_lower = [e["source_term"].lower() for e in entities]
    # Khử trùng lặp
    assert terms_lower.count("xiao yan") == 1
    # Bỏ qua từ < 2 ký tự hoặc stopwords
    assert "phim" not in terms_lower
    assert "tập" not in terms_lower
    assert "thể loại" not in terms_lower
    assert "a" not in terms_lower


def test_classify_ancient_fantasy():
    text = "Hành trình tu tiên của đệ tử tông môn, luyện phi kiếm cùng sư huynh sư muội trừ yêu ma."
    archetype, pronouns = classify_archetype(text)
    assert archetype == ARCHETYPE_ANCIENT_FANTASY
    assert pronouns == "Ta - Ngươi"


def test_classify_anime_school():
    text = "Câu chuyện học đường thanh xuân về nữ sinh tham gia clb anime cùng senpai."
    archetype, pronouns = classify_archetype(text)
    assert archetype == ARCHETYPE_ANIME_SCHOOL
    assert pronouns == "Em - Tiền bối"


def test_classify_modern_action():
    text = "Đội đặc nhiệm cảnh sát và điệp viên truy kích tội phạm bắn tỉa trên trực thăng."
    archetype, pronouns = classify_archetype(text)
    assert archetype == ARCHETYPE_MODERN_ACTION
    assert pronouns == "Tôi - Bạn"


def test_classify_romance_family():
    text = "Chuyện tình lãng mạn giữa tổng tài và cô nhân viên, vượt qua mâu thuẫn gia đình để kết hôn."
    archetype, pronouns = classify_archetype(text)
    assert archetype == ARCHETYPE_ROMANCE_FAMILY
    assert pronouns == "Anh - Em"


def test_anti_collision_tech_words():
    # Câu có từ kiếm hiệp nhưng bối cảnh công nghệ / lập trình / bug
    text = "Phim về lập trình viên chiến đấu với bug và hệ thống máy tính server như kiếm hiệp."
    archetype, pronouns = classify_archetype(text)
    assert archetype == ARCHETYPE_MODERN_ACTION
    assert pronouns == "Tôi - Bạn"


def test_empty_and_whitespace_summary():
    assert classify_archetype("") == (ARCHETYPE_CUSTOM, "Tự do (Theo ngữ cảnh)")
    assert classify_archetype("   \n\t  ") == (ARCHETYPE_CUSTOM, "Tự do (Theo ngữ cảnh)")
    assert extract_entities("") == []
    assert extract_entities("   ") == []


def test_analyze_context_wrapper():
    text = 'Tu tiên tông môn, nhân vật "Xiao Yan": Tiêu Viêm sử dụng phi kiếm.'
    result = analyze_context(text)
    assert result["archetype"] == ARCHETYPE_ANCIENT_FANTASY
    assert result["pronouns"] == "Ta - Ngươi"
    assert any(e["source_term"] == "Xiao Yan" for e in result["entities"])
