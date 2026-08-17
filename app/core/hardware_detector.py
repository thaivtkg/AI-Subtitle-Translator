import subprocess
import re

class HardwareDetector:
    @staticmethod
    def check_llama_cuda_backend() -> bool:
        """Kiểm tra CUDA backend thực tế của llama-cpp-python dùng llama_print_system_info()"""
        try:
            import llama_cpp
            # Gọi đúng API chuẩn của upstream llama-cpp-python 0.3.x
            info = llama_cpp.llama_print_system_info().decode("utf-8").upper()
            print(f"[DEBUG] llama.cpp system info: {info}")
            return "CUDA :" in info or "CUDA =" in info or "CUBLAS" in info
        except Exception as e:
            print(f"[Hardware Warning] Không thể kiểm tra CUDA Backend: {e}")
            return False

    @staticmethod
    def get_gpu_info():
        """Truy xuất thông tin GPU qua nvidia-smi"""
        try:
            result = subprocess.run(
                ['nvidia-smi', '--query-gpu=name,memory.total', '--format=csv,noheader'],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
                creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0)
            )
            if result.returncode == 0:
                output = result.stdout.strip().split(', ')
                if len(output) >= 2:
                    name = output[0]
                    vram_mb = int(re.sub(r'\D', '', output[1]))
                    vram_gb = vram_mb / 1024
                    return {"has_gpu_hardware": True, "name": name, "vram_gb": vram_gb}
        except Exception:
            pass
        return {"has_gpu_hardware": False, "name": "Unknown", "vram_gb": 0}

    @staticmethod
    def get_recommended_profile():
        gpu_info = HardwareDetector.get_gpu_info()
        
        try:
            llama_has_cuda = HardwareDetector.check_llama_cuda_backend()
        except Exception as e:
            return {
                "model_name": "qwen3-4b-q4.gguf",
                "n_gpu_layers": 0,
                "n_ctx": 2048,
                "gpu_info": gpu_info,
                "backend_status": f"CUDA Detection Error: {e}"
            }
        
        model_8b = "qwen3-8b-q4_k_m.gguf"
        model_4b = "qwen3-4b-q4.gguf"

        if not llama_has_cuda:
            return {
                "model_name": model_4b, 
                "n_gpu_layers": 0, 
                "n_ctx": 2048, 
                "gpu_info": gpu_info,
                "backend_status": "CPU Backend (CUDA Not Detected in Wheel)"
            }
        
        vram = gpu_info["vram_gb"]
        if vram >= 7.0: 
            return {
                "model_name": model_8b, 
                "n_gpu_layers": -1, 
                "n_ctx": 4096, 
                "gpu_info": gpu_info,
                "backend_status": "CUDA Enabled (Full Offload)"
            }
        else:
            return {
                "model_name": model_4b, 
                "n_gpu_layers": -1, 
                "n_ctx": 2048, 
                "gpu_info": gpu_info,
                "backend_status": "CUDA Enabled (Full Offload)"
            }