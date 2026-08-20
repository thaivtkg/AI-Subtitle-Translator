import unittest
from app.core.prompt_builder import PromptBuilder

class TestPromptBuilder(unittest.TestCase):
    def test_prompt_format_chatml(self):
        """Kiểm tra xem PromptBuilder có xuất đúng cấu trúc ChatML và nội dung không"""
        story_summary = "Main character is a hero."
        prev_ctx = ["I am here."]
        current = "Where are you?"
        next_ctx = ["Come quick!"]
        
        prompt = PromptBuilder.build(
            story_summary, "English", "Vietnamese", prev_ctx, current, next_ctx
        )
        
        # 1. Xác thực cấu trúc ChatML
        self.assertIn("<|im_start|>system", prompt)
        self.assertIn("<|im_start|>user", prompt)
        self.assertIn("<|im_start|>assistant", prompt)
        
        # 2. Xác thực nội dung được tiêm đúng chỗ
        self.assertIn("STORY SUMMARY:", prompt)
        self.assertIn("Main character is a hero.", prompt)
        self.assertIn("--- PREVIOUS SUBTITLES ---", prompt)
        self.assertIn("I am here.", prompt)
        self.assertIn("--- CURRENT SUBTITLE TO TRANSLATE ---", prompt)
        self.assertIn("Where are you?", prompt)
        
        # 3. Xác thực cờ Thinking OFF
        self.assertIn("DO NOT use reasoning", prompt)

if __name__ == "__main__":
    unittest.main()