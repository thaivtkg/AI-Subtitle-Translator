"""
Mandatory A/B Comparative Test & Dialogue Continuity Verification.
Ensures that adding Story Summary, Archetype Pronoun Biasing, and Translated Previous Subtitles
strictly modifies the prompt compared to baseline, failing if no difference is detected.
"""

import pytest
from app.core.prompt_builder import PromptBuilder
from app.core.context_engine import ContextEngine
from app.core.context_analyzer import (
    ContextAnalyzer,
    ARCHETYPE_ANCIENT_FANTASY,
    classify_archetype,
)


def test_mandatory_ab_comparative_prompt_difference():
    """
    MANDATORY A/B TEST:
    Compare translation prompt BEFORE vs AFTER adding Summary & Pronoun Biasing.
    MUST fail if enriched prompt does not enforce target pronouns or differs from baseline.
    """
    current_sub = "What do you want from me?"

    # --- 1. BASELINE: No summary, no active pronoun pair, raw previous context ---
    baseline_prev = ["Hello there."]
    baseline_prompt = PromptBuilder.build(
        story_summary="",
        source_lang="English",
        target_lang="Vietnamese",
        prev_context=baseline_prev,
        current_sub=current_sub,
        next_context=[],
        active_pronoun_pair="",
    )

    # --- 2. ENRICHED: Ancient Fantasy summary, Ta - Ngươi detected, translated dialogue ---
    summary = "Phim cổ trang tu tiên kiếm hiệp, hai cao thủ đối đầu sinh tử"
    archetype, pronoun_pair = classify_archetype(summary)
    assert archetype == ARCHETYPE_ANCIENT_FANTASY
    assert pronoun_pair == "Ta - Ngươi"

    # Context continuity: Preceding translated line using Ta - Ngươi
    enriched_prev = ["Ngươi muốn gì ở ta?"]
    enriched_prompt = PromptBuilder.build(
        story_summary=summary,
        source_lang="English",
        target_lang="Vietnamese",
        prev_context=enriched_prev,
        current_sub=current_sub,
        next_context=[],
        active_pronoun_pair=pronoun_pair,
        canonical_names=("Tiêu Viêm",),
    )

    # --- 3. MANDATORY COMPARATIVE ASSERTIONS ---
    # Enriched prompt MUST strictly differ from baseline
    assert enriched_prompt != baseline_prompt, (
        "CRITICAL FAILURE: Enriched prompt MUST be strictly different from baseline prompt!"
    )

    # Enriched prompt MUST enforce Ta - Ngươi and canonical name
    assert "Ta - Ngươi" in enriched_prompt, (
        "CRITICAL FAILURE: Enriched prompt MUST contain active pronoun pair 'Ta - Ngươi'!"
    )
    assert "PRONOUN RELATIONSHIP" in enriched_prompt, (
        "CRITICAL FAILURE: Enriched prompt MUST contain PRONOUN RELATIONSHIP rule!"
    )
    assert "Tiêu Viêm" in enriched_prompt, (
        "CRITICAL FAILURE: Enriched prompt MUST contain canonical character name 'Tiêu Viêm'!"
    )
    assert "Ngươi muốn gì ở ta?" in enriched_prompt, (
        "CRITICAL FAILURE: Enriched prompt MUST contain preceding translated dialogue for continuity!"
    )

    # Baseline prompt MUST NOT contain these biased rules
    assert "Ta - Ngươi" not in baseline_prompt, (
        "CRITICAL FAILURE: Baseline prompt must NOT contain 'Ta - Ngươi'!"
    )
    assert "Tiêu Viêm" not in baseline_prompt, (
        "CRITICAL FAILURE: Baseline prompt must NOT contain 'Tiêu Viêm'!"
    )


def test_context_engine_dialogue_continuity_statuses():
    """
    ContextEngine must supply translated text for ACCEPTED, TRANSLATED, and EDITED subtitles,
    and fall back to original text for PENDING or untranslated lines.
    """
    subtitles = [
        {"original": "Line 1 original", "translation": "Câu 1 đã duyệt", "status": "ACCEPTED"},
        {"original": "Line 2 original", "translation": "Câu 2 vừa dịch", "status": "TRANSLATED"},
        {"original": "Line 3 original", "translation": "Câu 3 người dùng sửa", "status": "EDITED"},
        {"original": "Line 4 original", "translation": "", "status": "PENDING"},
        {"original": "Line 5 current", "translation": "", "status": "PENDING"},
        {"original": "Line 6 future", "translation": "", "status": "PENDING"},
    ]

    prev_ctx, current_sub, next_ctx = ContextEngine.get_context(subtitles, 4)

    assert current_sub == "Line 5 current"
    # Lines 1, 2, 3 must use translation; Line 4 uses original because translation is empty
    assert "Câu 1 đã duyệt" not in prev_ctx  # window 3 câu trước: index 1, 2, 3
    assert "Câu 2 vừa dịch" in prev_ctx
    assert "Câu 3 người dùng sửa" in prev_ctx
    assert "Line 4 original" in prev_ctx
    # Next subtitles always use original
    assert "Line 6 future" in next_ctx


def test_active_pronoun_pair_only_injected_for_vietnamese():
    """
    Active pronoun pair instructions are specific to Vietnamese localization.
    Targeting other languages (e.g. English, French) should not inject Vietnamese pronoun rules.
    """
    prompt_en = PromptBuilder.build(
        story_summary="Some summary",
        source_lang="Vietnamese",
        target_lang="English",
        prev_context=[],
        current_sub="Xin chào",
        next_context=[],
        active_pronoun_pair="Ta - Ngươi",
    )
    assert "VIETNAMESE LOCALIZATION RULES" not in prompt_en
    assert "PRONOUN RELATIONSHIP" not in prompt_en


def test_custom_archetype_omits_mandatory_pronoun_rule():
    """
    When active_pronoun_pair is 'Tự do (Theo ngữ cảnh)' or empty,
    mandatory pronoun constraint is omitted, falling back to general natural pronoun guidelines.
    """
    prompt = PromptBuilder.build(
        story_summary="Modern story",
        source_lang="English",
        target_lang="Vietnamese",
        prev_context=[],
        current_sub="Hello",
        next_context=[],
        active_pronoun_pair="Tự do (Theo ngữ cảnh)",
    )
    assert "VIETNAMESE LOCALIZATION RULES" in prompt
    assert "PRONOUN RELATIONSHIP" not in prompt
    assert "NATURAL PRONOUNS" in prompt
