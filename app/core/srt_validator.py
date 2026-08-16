import re

class SRTValidator:
    TIME_PATTERN = re.compile(r"^(\d{2}):(\d{2}):(\d{2}),(\d{3})$")

    @staticmethod
    def _time_to_ms(time_str: str) -> int:
        match = SRTValidator.TIME_PATTERN.match(time_str)
        if not match: return -1
        h, m, s, ms = map(int, match.groups())
        return h * 3600000 + m * 60000 + s * 1000 + ms

    @staticmethod
    def validate_for_export(subtitles: list) -> tuple[bool, str]:
        if not subtitles:
            return False, "Không có dữ liệu subtitle để xuất."

        ids = set()
        prev_start_ms = -1

        for i, sub in enumerate(subtitles):
            # 1. Kiểm tra Index
            if not isinstance(sub.get("index"), int):
                return False, f"Dòng {i+1}: Index không hợp lệ."
            if sub["index"] in ids:
                return False, f"Trùng lặp Index #{sub['index']}."
            ids.add(sub["index"])

            # 2. KHÓA EXPORT NẾU CÒN CÂU CHƯA ĐƯỢC DUYỆT (ACCEPTED)
            status = str(sub.get("status", "")).upper()
            if status != "ACCEPTED":
                return False, f"Subtitle #{sub['index']} chưa được duyệt (Đang {status}). Cần dịch và duyệt 100% để xuất file."

            trans = sub.get("translation", "").strip()
            orig = sub.get("original", "").strip()
            if not trans:
                return False, f"Subtitle #{sub['index']}: Bản dịch bị bỏ trống."
            if trans == orig:
                return False, f"Subtitle #{sub['index']}: Chưa dịch (Bản dịch giống y hệt gốc)."

            # 3. Kiểm tra Timestamp Logic
            start = sub.get("start_time", "").strip()
            end = sub.get("end_time", "").strip()
            start_ms = SRTValidator._time_to_ms(start)
            end_ms = SRTValidator._time_to_ms(end)

            if start_ms == -1 or end_ms == -1:
                return False, f"Subtitle #{sub['index']}: Timestamp sai định dạng."
            if start_ms >= end_ms:
                return False, f"Subtitle #{sub['index']}: Start Time phải nhỏ hơn End Time."
            if start_ms < prev_start_ms:
                return False, f"Subtitle #{sub['index']}: Thứ tự thời gian bị ngược so với câu trước."
            
            prev_start_ms = start_ms

        return True, "Hợp lệ."