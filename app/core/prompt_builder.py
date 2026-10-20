from __future__ import annotations

from typing import Any


def build_translation_prompt(
    story_summary: str = "",
    source_lang: str = "English",
    target_lang: str = "Vietnamese",
    prev_context: list[str] | None = None,
    current_sub: str = "",
    next_context: list[str] | None = None,
    glossary_hits: tuple | list = (),
    entity_hits: tuple | list = (),
    active_pronoun_pair: str = "",
    canonical_names: tuple[str, ...] = (),
    is_ja_origin: bool = False,
    model_family: str = "qwen",
) -> str:
    # 1. Nâng cấp vai trò thành Chuyên gia Bản địa hóa
    system_prompt = (
        f"You are a master localization expert translating from {source_lang} to {target_lang}.\n"
        "CRITICAL INSTRUCTION: DO NOT use reasoning, thinking processes, or <think> tags. "
        "You are operating in non-thinking mode. Output ONLY the final translated text without any quotes or explanations.\n"
    )
    
    if story_summary and story_summary.strip():
        system_prompt += f"\nSTORY SUMMARY (CRITICAL CONTEXT):\n{story_summary.strip()}\n"
        
    system_prompt += (
        "\nGENERAL RULES:\n"
        "- Translate ONLY the current subtitle.\n"
        "- Do NOT translate character names or proper nouns.\n"
    )

    # 2. KHỐI TÊN RIÊNG CHUẨN HÓA (CANONICAL NAMES)
    if canonical_names:
        system_prompt += "\nCANONICAL CHARACTER NAMES (DO NOT TRANSLATE DIFFERENTLY):\n"
        for name in canonical_names:
            system_prompt += f"- {name}\n"

    # 3. KHỐI TÍCH HỢP NGỮ CẢNH DỰ ÁN (GLOSSARY & ENTITIES)
    if glossary_hits or entity_hits:
        system_prompt += "\nPROJECT-SPECIFIC TRANSLATION RULES (MANDATORY):\n"
        system_prompt += "You must strictly follow these rules for the matching terms and entities in this subtitle:\n"

        if glossary_hits:
            system_prompt += "\n[GLOSSARY]\n"
            sorted_glossary_hits = sorted(
                glossary_hits,
                key=lambda item: getattr(item[0] if isinstance(item, (tuple, list)) else item, "start", 0)
            )
            for item in sorted_glossary_hits:
                if isinstance(item, (tuple, list)) and len(item) == 2:
                    hit, forbidden = item
                else:
                    hit, forbidden = item, ()
                rule = f'- "{hit.source_term}" MUST be translated as "{hit.preferred_translation}".'
                if forbidden:
                    forbidden_str = '", "'.join(forbidden)
                    rule += f' (ABSOLUTELY FORBIDDEN: "{forbidden_str}")'
                system_prompt += rule + "\n"

        if entity_hits:
            system_prompt += "\n[ENTITIES]\n"
            sorted_entity_hits = sorted(
                entity_hits,
                key=lambda hit: getattr(hit, "start", 0)
            )
            for hit in sorted_entity_hits:
                rule = f'- "{hit.matched_form}" ({hit.entity_type}, canonical name: "{hit.entity_name}") MUST be translated as "{hit.canonical_translation}".'
                system_prompt += rule + "\n"

    # 4. BỘ LUẬT DÀNH CHO TIẾNG VIỆT (TỰ NHIÊN, KHÔNG CỨNG NHẮC, KHÔNG RÒ RỈ SUY NGHĨ)
    if target_lang.lower() == "vietnamese":
        rules = ["\nVIETNAMESE LOCALIZATION RULES (MUST FOLLOW):"]
        
        # Khóa chống rò rỉ suy luận / commentary
        rules.append(
            "1. STRICT OUTPUT FORMAT: Output ONLY the direct translated Vietnamese subtitle. ABSOLUTELY DO NOT output any reasoning, explanation, alternatives, or English notes (e.g., NEVER output 'Either this...', 'Given the...', 'Switch to...', 'Note:')."
        )
        # Định hướng xưng hô linh hoạt, cho phép 'tôi' tự nhiên
        if active_pronoun_pair and active_pronoun_pair.strip() and "tự do" not in active_pronoun_pair.lower():
            rules.append(
                f"2. PRONOUN RELATIONSHIP: Main character relationship is '{active_pronoun_pair.strip()}'. "
                "However, dialogue has ALTERNATING SPEAKERS: When the junior speaks, they address the other as 'tiền bối' and refer to themselves as 'em'. "
                "When the senior replies (e.g. 'I will not give up'), they refer to themselves naturally as 'tôi' or 'chị/anh' (e.g. 'Tôi sẽ không đầu hàng'). "
                "NEVER refer to oneself as 'Tiền bối không đầu hàng'!"
            )
        else:
            rules.append(
                "2. NATURAL PRONOUNS: Use natural pronouns suitable for the context. 'Tôi' is completely valid and natural for self-affirmation (e.g., 'Tôi sẽ không đầu hàng')."
            )
        # Luật tiếng Nhật khi được đánh dấu
        is_marked_ja_origin = (
            is_ja_origin 
            or source_lang.lower() in ("ja", "japanese")
        )
        if is_marked_ja_origin:
            rules.append(
                "3. JAPANESE TRANSLATION ARTIFACTS:\n"
                "- Subtitle originates from Japanese (Anime/Drama).\n"
                "- Translate 'senior' / 'seniors' as 'tiền bối' (or 'anh/chị tiền bối') when addressing schoolmates/colleagues. NEVER translate as 'người lớn tuổi' or 'học sinh lớp trên'.\n"
                "- Translate 'senpai' as 'tiền bối'.\n"
                "- Translate 'junior' as 'hậu bối' or 'em'."
            )
        rules.append(
            "4. NATURAL DIALOGUE: The translation must sound like native spoken Vietnamese in movies/anime. Avoid unnatural word-by-word phrasing."
        )
        # CẤM TUYỆT ĐỐI CHỮ HÁN / CJK TRONG BẢN DỊCH TIẾNG VIỆT
        rules.append(
            "5. VIETNAMESE PURITY (NO CJK / NO HANZI): You MUST translate 100% into natural Vietnamese using the Latin alphabet (chữ Quốc ngữ). "
            "ABSOLUTELY DO NOT output Chinese Hanzi (e.g., NEVER output '太天真了', translate as 'quá ngây thơ' or 'ngây thơ quá'), "
            "Japanese Kanji/Kana, or mixed script. Every single word in the output must be proper Vietnamese."
        )
        system_prompt += "\n".join(rules) + "\n"

    # 5. USER PROMPT
    user_prompt = ""
    if prev_context:
        user_prompt += "--- PREVIOUS SUBTITLES ---\n" + "\n".join(prev_context) + "\n\n"
    user_prompt += "--- CURRENT SUBTITLE TO TRANSLATE ---\n" + current_sub + "\n\n"
    if next_context:
        user_prompt += "--- NEXT SUBTITLES ---\n" + "\n".join(next_context) + "\n\n"
        
    user_prompt += f"Output ONLY the final {target_lang} translation for the current subtitle directly. No extra words."

    # 6. MODEL-SPECIFIC CHAT TEMPLATE WRAPPER
    return format_chat(system_prompt, user_prompt, model_family)


def format_chat(system_prompt: str, user_prompt: str, model_family: str = "qwen") -> str:
    family = (model_family or "qwen").lower()
    if "gemma" in family:
        return (
            f"<start_of_turn>user\n{system_prompt}\n\n{user_prompt}<end_of_turn>\n"
            f"<start_of_turn>model\n"
        )
    elif "llama" in family:
        return (
            f"<|start_header_id|>system<|end_header_id|>\n\n{system_prompt}<|eot_id|>"
            f"<|start_header_id|>user<|end_header_id|>\n\n{user_prompt}<|eot_id|>"
            f"<|start_header_id|>assistant<|end_header_id|>\n\n"
        )
    else:
        return (
            f"<|im_start|>system\n{system_prompt}<|im_end|>\n"
            f"<|im_start|>user\n{user_prompt}<|im_end|>\n"
            f"<|im_start|>assistant\n"
        )


class PromptBuilder:
    build = staticmethod(build_translation_prompt)
    format_chat = staticmethod(format_chat)