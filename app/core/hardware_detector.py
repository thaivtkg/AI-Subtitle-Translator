import subprocess
import re

class HardwareDetector:
    @staticmethod
    def get_gpu_info():
        """Truy xuất thông tin GPU qua nvidia-smi (Chỉ hoạt động tốt trên Windows/Linux có NVIDIA driver)"""
        try:
            # Tham số creationflags=subprocess.CREATE_NO_WINDOW giúp ẩn cửa sổ CMD đen trên Windows
            result = subprocess.run(
                ['nvidia-smi', '--query-gpu=name,memory.total', '--format=csv,noheader'],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
                creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0)
            )
            if result.returncode == 0:
                output = result.stdout.strip().split(', ')
                if len(output) >= 2:
                    name = output[0]
                    # Chuyển đổi '8192 MiB' thành số nguyên (GB)
                    vram_mb = int(re.sub(r'\D', '', output[1]))
                    vram_gb = vram_mb / 1024
                    return {"has_cuda": True, "name": name, "vram_gb": vram_gb}
        except Exception:
            pass
        return {"has_cuda": False, "name": "CPU / Unknown GPU", "vram_gb": 0}

    @staticmethod
    def get_recommended_profile():
        """Đưa ra profile cấu hình Model tối ưu dựa trên lượng VRAM"""
        gpu_info = HardwareDetector.get_gpu_info()
        
        if not gpu_info["has_cuda"]:
            return {"model_name": "Qwen3-4B-CPU", "n_gpu_layers": 0, "n_ctx": 2048, "gpu_info": gpu_info}
        
        vram = gpu_info["vram_gb"]
        if vram >= 7.0: 
            # Profile cho RTX 4060 (8GB VRAM) -> Offload toàn bộ (-1), dùng Model 8B
            return {"model_name": "Qwen3-8B-Q4_K_M.gguf", "n_gpu_layers": -1, "n_ctx": 4096, "gpu_info": gpu_info}
        else:
            # Profile cho RTX 3050 (4GB VRAM) -> Offload toàn bộ (-1), dùng Model 4B
            return {"model_name": "Qwen3-4B-Q4.gguf", "n_gpu_layers": -1, "n_ctx": 2048, "gpu_info": gpu_info}