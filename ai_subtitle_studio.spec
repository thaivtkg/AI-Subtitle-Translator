# -*- mode: python ; coding: utf-8 -*-
import os
import sys
import llama_cpp

block_cipher = None

# Locate llama_cpp dynamic libraries
llama_cpp_dir = os.path.dirname(llama_cpp.__file__)
llama_cpp_lib = os.path.join(llama_cpp_dir, "lib")

llama_cpp_binaries = []
llama_cpp_datas = []

if os.path.isdir(llama_cpp_lib):
    for f in os.listdir(llama_cpp_lib):
        full_path = os.path.join(llama_cpp_lib, f)
        if os.path.isfile(full_path):
            llama_cpp_binaries.append((full_path, os.path.join("llama_cpp", "lib")))
            llama_cpp_datas.append((full_path, os.path.join("llama_cpp", "lib")))

datas = [
    ('ui', 'ui'),
    ('app_settings.json', '.'),
] + llama_cpp_datas

binaries = llama_cpp_binaries

hiddenimports = [
    'llama_cpp',
    'app.core.runtime_check',
    'app.core.hardware_detector',
    'app.core.model_catalog',
    'app.core.app_settings',
    'app.core.srt_parser',
    'app.core.srt_exporter',
    'app.core.srt_validator',
    'app.core.prompt_builder',
    'app.core.context_engine',
    'app.core.qa_engine',
    'app.core.glossary',
    'app.core.entity_dictionary',
    'app.core.translation_memory',
    'app.core.backends.base_backend',
    'app.core.backends.llama_cpp_backend',
    'app.core.backends.ollama_backend',
    'app.controllers.translation_controller',
    'app.controllers.project_controller',
    'app.controllers.batch_controller',
    'app.controllers.batch_runtime_bridge',
    'app.controllers.model_controller',
    'app.models.subtitle',
    'app.services.download_manager',
    'app.services.batch_translation_service',
    'app.services.translation_execution_port',
    'app.services.translation_pipeline_adapter',
    'PySide6.QtQml',
    'PySide6.QtQuick',
    'PySide6.QtQuickControls2',
    'PySide6.QtCore',
    'PySide6.QtGui',
]

a = Analysis(
    ['main.py'],
    pathex=['.'],
    binaries=binaries,
    datas=datas,
    hiddenimports=hiddenimports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=['matplotlib', 'scipy', 'tkinter', 'unittest', 'IPython'],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='AISubtitleStudio',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=False,
    upx_exclude=[],
    name='AISubtitleStudio',
)
