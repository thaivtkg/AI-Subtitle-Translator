class PromptBuilder:
    @staticmethod
    def build(story_summary: str, source_lang: str, target_lang: str,
              prev_context: list, current_sub: str, next_context: list) -> str:
        """
        Tạo prompt hoàn chỉnh để gửi cho LLM dựa trên ngữ cảnh được cấp.
        """
        prompt = (
            f"You are a professional subtitle translator translating from {source_lang} to {target_lang}.\n\n"
        )

        if story_summary and story_summary.strip():
            prompt += f"<story_summary>\n{story_summary.strip()}\n</story_summary>\n\n"

        if prev_context:
            prompt += "<context_previous>\n"
            for text in prev_context:
                prompt += f"{text}\n"
            prompt += "</context_previous>\n\n"

        prompt += f"<current_subtitle_to_translate>\n{current_sub}\n</current_subtitle_to_translate>\n\n"

        if next_context:
            prompt += "<context_next>\n"
            for text in next_context:
                prompt += f"{text}\n"
            prompt += "</context_next>\n\n"

        # Ép model không trả về lời giải thích, chỉ trả về text nằm trong thẻ <current>
        prompt += (
            f"TASK: Translate ONLY the text inside <current_subtitle_to_translate>. "
            f"Do not explain. Do not translate the surrounding context. "
            f"Output the exact {target_lang} translation."
        )

        return prompt
