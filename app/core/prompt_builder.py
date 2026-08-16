class PromptBuilder:
    @staticmethod
    def build(story_summary: str, source_lang: str, target_lang: str, 
              prev_context: list, current_sub: str, next_context: list) -> str:
        prompt = (
            f"You are a professional subtitle translator translating from {source_lang} to {target_lang}.\n\n"
        )

        if story_summary and story_summary.strip():
            prompt += f"<story_summary>\n{story_summary.strip()}\n</story_summary>\n\n"

        prompt += "<rules>\n"
        prompt += "- Translate ONLY the current subtitle.\n"
        prompt += "- Do NOT translate character names (Name Protection).\n"
        prompt += "- Keep proper nouns and special formats intact.\n"
        prompt += "- Do NOT add, remove, or modify the core meaning.\n"
        prompt += "- Do NOT translate the surrounding context.\n"
        prompt += "- Do NOT output any explanations or notes.\n"
        prompt += "- Follow the tone and character relationships defined in story_summary.\n"
        prompt += "</rules>\n\n"

        if prev_context:
            prompt += "<context_previous>\n" + "\n".join(prev_context) + "\n</context_previous>\n\n"

        prompt += f"<current_subtitle_to_translate>\n{current_sub}\n</current_subtitle_to_translate>\n\n"

        if next_context:
            prompt += "<context_next>\n" + "\n".join(next_context) + "\n</context_next>\n\n"

        prompt += f"TASK: Output the exact {target_lang} translation for <current_subtitle_to_translate> now."
        return prompt
