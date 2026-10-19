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

    # 4. BỘ LUẬT "THÉP" DÀNH RIÊNG CHO TIẾNG VIỆT (PRONOUN BIASING & DIALOGUE CONTINUITY)
    if target_lang.lower() == "vietnamese":
        rules = ["\nVIETNAMESE LOCALIZATION RULES (MUST FOLLOW):"]
        
        # Định hướng cặp đại từ xưng hô nếu có thể loại xác định
        if active_pronoun_pair and active_pronoun_pair.strip() and "tự do" not in active_pronoun_pair.lower():
            rules.append(
                f"1. MANDATORY PRONOUN PAIR: You MUST prioritize the pronoun pair '{active_pronoun_pair.strip()}' for addressing between the main characters. Ensure consistent addressing throughout dialogue."
            )
            rules.append(
                "2. STRICT PRONOUNS: ABSOLUTELY DO NOT use robotic literal pronouns like 'tôi', 'bạn', 'anh ấy', 'cô ấy' in casual dialogue unless matching the active pronoun pair. Adapt pronouns naturally based on character relationships."
            )
        else:
            rules.append(
                "1. STRICT PRONOUNS: ABSOLUTELY DO NOT use robotic literal pronouns like 'tôi', 'bạn', 'anh ấy', 'cô ấy' in casual dialogue. You MUST adapt pronouns naturally (e.g., anh, chị, em, mày, tao, ông, bà, hắn, nó) based strictly on the character relationships in the STORY SUMMARY."
            )

        # CHỈ kích hoạt luật ép dịch 'senior' -> 'tiền bối' KHI được đánh dấu là sub dịch từ Nhật
        is_marked_ja_origin = (
            is_ja_origin 
            or source_lang.lower() in ("ja", "japanese")
        )
        if is_marked_ja_origin:
            rules.append(
                "JAPANESE TRANSLATION ARTIFACTS (CRITICAL):\n"
                "- This dialogue is explicitly marked as originating from Japanese (Anime/Drama).\n"
                "- When encountering 'senior' or 'seniors' used as a title, address, or reference to colleagues/schoolmates, you MUST translate it as 'tiền bối' (or 'anh/chị tiền bối'). ABSOLUTELY DO NOT translate 'senior' as 'người lớn tuổi', 'người già', or 'học sinh lớp trên'.\n"
                "- Translate 'senpai' as 'tiền bối'.\n"
                "- Translate 'junior' as 'hậu bối' or 'em'.\n"
                "- Translate 'master' (when addressing a mentor) as 'sư phụ' or 'tiên sinh'."
            )
            
        rules.append(
            "3. DIALOGUE CONTINUITY: Follow the tone, pronouns, and terminology of the preceding translated subtitles (in --- PREVIOUS SUBTITLES ---). If the previous line used a specific pronoun pair, you MUST continue using that exact pair."
        )
        rules.append(
            "4. HONORIFICS: Completely REMOVE Japanese/Korean honorific suffixes (like -san, -kun, -chan, -sama, -ssi) OR translate them naturally into Vietnamese kinship terms. DO NOT leave them as literal words (e.g., never output 'Tanaka anh')."
        )
        rules.append(
            "5. NATURAL TONE: The dialogue must flow naturally like native Vietnamese speakers. Use appropriate sentence-ending particles (nhé, nha, đi, thôi) for casual speech."
        )
        system_prompt += "\n".join(rules) + "\n"

    # 5. USER PROMPT
    user_prompt = ""
    if prev_context:
        user_prompt += "--- PREVIOUS SUBTITLES ---\n" + "\n".join(prev_context) + "\n\n"
    user_prompt += "--- CURRENT SUBTITLE TO TRANSLATE ---\n" + current_sub + "\n\n"
    if next_context:
        user_prompt += "--- NEXT SUBTITLES ---\n" + "\n".join(next_context) + "\n\n"
        
    user_prompt += f"Provide the exact natural {target_lang} translation for the current subtitle directly."

    # 6. CHATML WRAPPER
    prompt = (
        f"<|im_start|>system\n{system_prompt}<|im_end|>\n"
        f"<|im_start|>user\n{user_prompt}<|im_end|>\n"
        f"<|im_start|>assistant\n" 
    )
    return prompt


class PromptBuilder:
    build = staticmethod(build_translation_prompt)