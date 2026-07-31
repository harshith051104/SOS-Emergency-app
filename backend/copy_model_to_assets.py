import shutil
from pathlib import Path

src = Path(r"c:\Users\sriha\My work\SOS\backend\models\silero_vad.onnx")

dest1 = Path(r"c:\Users\sriha\My work\SOS\elly\assets\models\silero_vad.onnx")
dest2 = Path(r"c:\Users\sriha\My work\SOS\elly\android\app\src\main\assets\silero_vad.onnx")

dest1.parent.mkdir(parents=True, exist_ok=True)
dest2.parent.mkdir(parents=True, exist_ok=True)

if src.is_file():
    shutil.copy2(src, dest1)
    shutil.copy2(src, dest2)
    print(f"✅ Copied {src} to:\n  - {dest1}\n  - {dest2}")
else:
    print(f"❌ Source file {src} does not exist.")
