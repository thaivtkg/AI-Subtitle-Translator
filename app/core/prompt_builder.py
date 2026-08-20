class PromptBuilder:
    @staticmethod
    def build(story_summary: str, source_lang: str, target_lang: str, 
              prev_context: list, current_sub: str, next_context: list) -> str:
        
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

        # 2. BỘ LUẬT "THÉP" DÀNH RIÊNG CHO TIẾNG VIỆT
        if target_lang.lower() == "vietnamese":
            system_prompt += (
                "\nVIETNAMESE LOCALIZATION RULES (MUST FOLLOW):\n"
                "1. STRICT PRONOUNS: ABSOLUTELY DO NOT use robotic literal pronouns like 'tôi', 'bạn', 'anh ấy', 'cô ấy' in casual dialogue. You MUST adapt pronouns naturally (e.g., anh, chị, em, mày, tao, ông, bà, hắn, nó) based strictly on the character relationships in the STORY SUMMARY.\n"
                "2. HONORIFICS: Completely REMOVE Japanese/Korean honorific suffixes (like -san, -kun, -chan, -sama, -ssi) OR translate them naturally into Vietnamese kinship terms. DO NOT leave them as literal words (e.g., never output 'Tanaka anh').\n"
                "3. NATURAL TONE: The dialogue must flow naturally like native Vietnamese speakers. Use appropriate sentence-ending particles (nhé, nha, đi, thôi) for casual speech.\n"
            )

        # 3. USER PROMPT (Giữ nguyên)
        user_prompt = ""
        if prev_context:
            user_prompt += "--- PREVIOUS SUBTITLES ---\n" + "\n".join(prev_context) + "\n\n"
        user_prompt += "--- CURRENT SUBTITLE TO TRANSLATE ---\n" + current_sub + "\n\n"
        if next_context:
            user_prompt += "--- NEXT SUBTITLES ---\n" + "\n".join(next_context) + "\n\n"
            
        user_prompt += f"Provide the exact natural {target_lang} translation for the current subtitle directly."

        # 4. CHATML WRAPPER
        prompt = (
            f"<|im_start|>system\n{system_prompt}<|im_end|>\n"
            f"<|im_start|>user\n{user_prompt}<|im_end|>\n"
            f"<|im_start|>assistant\n" 
        )
        return prompt