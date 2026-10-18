import os


class SRTExporter:
    VALID_EXPORT_STATUSES = {"ACCEPTED", "EDITED", "TRANSLATED"}

    @staticmethod
    def export(subtitles: list, output_path: str) -> tuple[bool, str]:
        """Xuất dữ liệu ra file SRT. Ưu tiên bản dịch hợp lệ, fallback an toàn về câu gốc."""
        try:
            with open(output_path, "w", encoding="utf-8") as f:
                for sub in subtitles:
                    f.write(f"{sub['index']}\n")
                    f.write(f"{sub['start_time']} --> {sub['end_time']}\n")

                    status = str(sub.get("status") or "PENDING").upper()
                    clean_trans = str(sub.get("translation") or "").strip()
                    clean_orig = str(sub.get("original") or "").strip()

                    if status in SRTExporter.VALID_EXPORT_STATUSES and clean_trans:
                        text = clean_trans
                    else:
                        text = clean_orig

                    f.write(f"{text}\n\n")
            return True, f"Thành công! Đã lưu tại: {os.path.abspath(output_path)}"
        except Exception as e:
            return False, f"Lỗi: {str(e)}"
