class PromptBuilder:
    @staticmethod
    def build(story_summary: str, source_lang: str, target_lang: str, 
              prev_context: list, current_sub: str, next_context: list) -> str:
        
        # 1. HỆ THỐNG LỆNH (SYSTEM PROMPT)
        system_prompt = (
            f"You are a professional subtitle translator translating from {source_lang} to {target_lang}.\n"
            "You must strictly follow the rules below. Do NOT output any explanations, tags, markdown, or thinking process.\n"
        )
        
        if story_summary and story_summary.strip():
            system_prompt += f"\nSTORY SUMMARY:\n{story_summary.strip()}\n"
            
        system_prompt += (
            "\nRULES:\n"
            "- Translate ONLY the current subtitle.\n"
            "- Do NOT translate character names.\n"
            "- Keep proper nouns and special formats intact.\n"
            "- Do NOT add, remove, or modify the core meaning.\n"
            "- Output ONLY the raw translated text. Absolutely no extra words."
        )

        # 2. DỮ LIỆU ĐẦU VÀO (USER PROMPT)
        user_prompt = ""
        if prev_context:
            user_prompt += "--- PREVIOUS SUBTITLES ---\n" + "\n".join(prev_context) + "\n\n"
            
        user_prompt += "--- CURRENT SUBTITLE TO TRANSLATE ---\n" + current_sub + "\n\n"
        
        if next_context:
            user_prompt += "--- NEXT SUBTITLES ---\n" + "\n".join(next_context) + "\n\n"
            
        user_prompt += f"Provide the exact {target_lang} translation for the current subtitle."

        # 3. ĐÓNG GÓI THEO CHUẨN CHATML CỦA QWEN
        prompt = (
            f"<|im_start|>system\n{system_prompt}<|im_end|>\n"
            f"<|im_start|>user\n{user_prompt}<|im_end|>\n"
            f"<|im_start|>assistant\n"
        )
        
        return prompt