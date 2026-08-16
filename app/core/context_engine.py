class ContextEngine:
    @staticmethod
    def get_context(subtitles: list, current_index: int, prev_count: int = 5, next_count: int = 5):
        """
        Trích xuất ngữ cảnh xung quanh một subtitle cụ thể.
        :param subtitles: Danh sách toàn bộ subtitle từ parse
        :param current_index: Vị trí của subtitle đang cần dịch (trong mảng, bắt đầu từ 0)
        :param prev_count: Số câu ngữ cảnh phía trước
        :param next_count: Số câu ngữ cảnh phía sau
        :return: Tuple (prev_context, current_sub, next_context)
        """
        if not subtitles or current_index < 0 or current_index >= len(subtitles):
            return [], "", []

        prev_context = []
        next_context = []

        # 1. Lấy ngữ cảnh quá khứ (ưu tiên bản dịch đã ACCEPTED)
        start_prev = max(0, current_index - prev_count)
        for i in range(start_prev, current_index):
            sub = subtitles[i]
            # Nếu user đã sửa/chấp nhận, lấy bản dịch để model bám sát văn phong
            if sub.get("status") == "accepted" and sub.get("translation"):
                prev_context.append(sub["translation"])
            else:
                prev_context.append(sub["original"])

        # 2. Lấy subtitle hiện tại
        current_sub = subtitles[current_index]["original"]

        # 3. Lấy ngữ cảnh tương lai (luôn lấy bản gốc vì chưa được dịch)
        end_next = min(len(subtitles), current_index + next_count + 1)
        for i in range(current_index + 1, end_next):
            sub = subtitles[i]
            next_context.append(sub["original"])

        return prev_context, current_sub, next_context
