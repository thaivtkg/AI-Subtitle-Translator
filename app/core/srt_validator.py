import re

class SRTValidator:
    TIME_PATTERN = re.compile(r"^\d{2}:\d{2}:\d{2},\d{3}$")

    @staticmethod
    def validate_for_export(subtitles: list) -> tuple[bool, str]:
        if not subtitles:
            return False, "Không có dữ liệu subtitle để xuất."

        ids = set()
        for i, sub in enumerate(subtitles):
            if not isinstance(sub.get("index"), int):
                return False, f"Dòng {i+1}: Index không hợp lệ."
            
            if sub["index"] in ids:
                return False, f"Trùng lặp Index #{sub['index']}."
            ids.add(sub["index"])

            start = sub.get("start_time", "").strip()
            end = sub.get("end_time", "").strip()
            if not SRTValidator.TIME_PATTERN.match(start) or not SRTValidator.TIME_PATTERN.match(end):
                return False, f"Subtitle #{sub['index']}: Timestamp sai định dạng."

            # --- FIX LỖI Ở ĐÂY: ĐỒNG NHẤT CHỮ HOA VÀ CHỮ THƯỜNG ---
            status = str(sub.get("status", "")).upper()
            
            if status == "ACCEPTED":
                trans = sub.get("translation", "").strip()
                orig = sub.get("original", "").strip()
                
                if not trans:
                    return False, f"Subtitle #{sub['index']}: Bản dịch bị bỏ trống."
                
                # Bắt lỗi nếu user bấm Accept mà chưa hề dịch (chữ y hệt bản gốc)
                if trans == orig:
                    return False, f"Subtitle #{sub['index']}: Chưa dịch (Bản dịch giống y hệt bản gốc)."

        return True, "Hợp lệ."