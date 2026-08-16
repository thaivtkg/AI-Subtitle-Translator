from app.core.context_engine import ContextEngine
from app.core.prompt_builder import PromptBuilder

# 1. Tạo dữ liệu giả lập
subtitles = [
    {"index": 1, "original": "Where are you going?", "translation": "Cậu đi đâu thế?", "status": "accepted"},
    {"index": 2, "original": "I finally came back.", "translation": "", "status": "pending"}, # Đang dịch câu này
    {"index": 3, "original": "You really took your time.", "translation": "", "status": "pending"}
]

# 2. Test Context Engine tại vị trí index = 1 (Tương đương câu số 2)
prev_ctx, current, next_ctx = ContextEngine.get_context(subtitles, 1, prev_count=2, next_count=2)

# 3. Test Prompt Builder
prompt = PromptBuilder.build(
    story_summary="John trở về quê sau 10 năm.",
    source_lang="English",
    target_lang="Vietnamese",
    prev_context=prev_ctx,
    current_sub=current,
    next_context=next_ctx
)

print("--- KẾT QUẢ PROMPT ---")
print(prompt)