"""
Real-world Verification on E:\\ghpm98ja.srt and E:\\ghpm98.srt (First 30 Subtitles).
Compares Baseline vs Enriched Prompts to guarantee that Japanese origin biasing
correctly transforms anime address terms into 'tiền bối'.
"""
import os
import re
import pytest
from app.core.context_analyzer import ContextAnalyzer, detect_ja_translated_en
from app.core.prompt_builder import PromptBuilder


def parse_srt_first_30(file_path: str):
    if not os.path.exists(file_path):
        pytest.skip(f"Test file not found: {file_path}")
    with open(file_path, "r", encoding="utf-8", errors="replace") as f:
        content = f.read()
    blocks = re.split(r"\n\s*\n", content.strip())
    results = []
    for b in blocks[:30]:
        lines = b.strip().split("\n")
        if len(lines) >= 3:
            idx = lines[0].strip()
            time = lines[1].strip()
            text = " ".join(lines[2:]).strip()
            results.append((int(idx), time, text))
    return results


def test_real_srt_detection_ghpm98():
    ja_path = r"E:\ghpm98ja.srt"
    en_path = r"E:\ghpm98.srt"
    
    en_subs = parse_srt_first_30(en_path)
    assert len(en_subs) == 30
    combined_en_text = " ".join([s[2] for s in en_subs])
    
    # 1. Khẳng định hệ thống nhận diện ra đây là phụ đề tiếng Anh dịch từ Nhật
    detection = detect_ja_translated_en(combined_en_text)
    assert detection["is_ja_origin"] is True, "Phải nhận diện được ghpm98.srt là phụ đề dịch từ JA!"
    assert "anime_senior_address" in detection["matched_clues"]
    assert any("senpai" in c for c in detection["matched_clues"])


def test_real_srt_30_lines_comparative_prompt():
    en_path = r"E:\ghpm98.srt"
    en_subs = parse_srt_first_30(en_path)
    # Các câu trọng yếu chứa danh xưng tiếng Nhật
    target_indices = [2, 4, 16, 18, 25, 26, 29]
    target_subs = {idx: text for idx, time, text in en_subs if idx in target_indices}
    for idx, sub_text in target_subs.items():
        # --- BASELINE PROMPT: Không có cờ JA, không có đại từ định hướng ---
        baseline_prompt = PromptBuilder.build(
            story_summary="",
            source_lang="English",
            target_lang="Vietnamese",
            current_sub=sub_text,
            active_pronoun_pair="",
            is_ja_origin=False,
        )
        # --- ENRICHED PROMPT: Có cờ JA origin, kích hoạt đại từ Em - Tiền bối ---
        enriched_prompt = PromptBuilder.build(
            story_summary="Anime viễn tưởng phép thuật học đường",
            source_lang="English",
            target_lang="Vietnamese",
            current_sub=sub_text,
            active_pronoun_pair="Em - Tiền bối",
            is_ja_origin=True,
        )
        # 1. Bắt buộc có sự khác biệt rõ rệt giữa 2 prompt
        assert enriched_prompt != baseline_prompt, f"Dòng #{idx} prompt không thay đổi!"
        # 2. Enriched prompt bắt buộc phải chứa chỉ thị cấm dịch 'người lớn tuổi', ép dịch 'tiền bối'
        assert "JAPANESE TRANSLATION ARTIFACTS" in enriched_prompt
        assert "tiền bối" in enriched_prompt
        assert "NEVER translate as 'người lớn tuổi'" in enriched_prompt
