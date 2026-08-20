class PromptBuilder:
    @staticmethod
    def build(story_summary: str, source_lang: str, target_lang: str, 
              prev_context: list, current_sub: str, next_context: list) -> str:
        
        # 1. SYSTEM PROMPT: Bổ sung cờ ép buộc "Thinking OFF"
        system_prompt = (
            f"You are a strict, direct subtitle translator from {source_lang} to {target_lang}.\n"
            "CRITICAL INSTRUCTION: DO NOT use reasoning, thinking processes, or <think> tags. "
            "You are operating in non-thinking mode (enable_thinking=False). Output ONLY the final translated text.\n"
        )
        
        if story_summary and story_summary.strip():
            system_prompt += f"\nSTORY SUMMARY:\n{story_summary.strip()}\n"
            
        system_prompt += (
            "\nRULES:\n"
            "- Translate ONLY the current subtitle.\n"
            "- Do NOT translate character names or proper nouns.\n"
            "- Do NOT add, remove, or modify the core meaning."
        )

        # 2. USER PROMPT
        user_prompt = ""
        if prev_context:
            user_prompt += "--- PREVIOUS SUBTITLES ---\n" + "\n".join(prev_context) + "\n\n"
        user_prompt += "--- CURRENT SUBTITLE TO TRANSLATE ---\n" + current_sub + "\n\n"
        if next_context:
            user_prompt += "--- NEXT SUBTITLES ---\n" + "\n".join(next_context) + "\n\n"
            
        user_prompt += f"Provide the exact {target_lang} translation for the current subtitle directly."

        # 3. CHATML WRAPPER: Ép thẳng vào phần trả lời, không cho mô hình cơ hội sinh thẻ <think>
        prompt = (
            f"<|im_start|>system\n{system_prompt}<|im_end|>\n"
            f"<|im_start|>user\n{user_prompt}<|im_end|>\n"
            f"<|im_start|>assistant\n" 
            # Dấu \n cuối cùng cực kỳ quan trọng trong ChatML để báo hiệu bắt đầu tạo token text
        )
        return prompt