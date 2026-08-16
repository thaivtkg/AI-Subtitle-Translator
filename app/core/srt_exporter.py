import os

class SRTExporter:
    @staticmethod
    def export(subtitles: list, output_path: str):
        """Xuất dữ liệu ra file SRT. Ưu tiên bản dịch, nếu chưa dịch thì giữ nguyên gốc."""
        try:
            with open(output_path, 'w', encoding='utf-8') as f:
                for sub in subtitles:
                    f.write(f"{sub['index']}\n")
                    f.write(f"{sub['start_time']} --> {sub['end_time']}\n")
                    
                    # Ưu tiên bản dịch nếu đã ACCEPTED
                    if sub.get('status') == 'accepted' and sub.get('translation'):
                        text = sub['translation']
                    else:
                        text = sub['original']
                        
                    f.write(f"{text}\n\n")
            return True, f"Thành công! Đã lưu tại: {os.path.abspath(output_path)}"
        except Exception as e:
            return False, f"Lỗi: {str(e)}"
