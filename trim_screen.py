import sys

src = r"lib\screens\home\pcm_ai_designer_screen.dart"

with open(src, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Keep lines 0..1566 (lines 1 to 1567 in 1-indexed)
trimmed = lines[:1567]

# Write to temp
tmp = src + ".trimmed"
with open(tmp, 'w', encoding='utf-8') as f:
    f.writelines(trimmed)

print(f"Temp written: {len(trimmed)} lines")

import shutil
try:
    shutil.copy2(tmp, src)
    print("Original replaced successfully")
except Exception as e:
    print(f"Could not replace (file locked?): {e}")
    print(f"Temp file is at: {tmp}")

import os
if os.path.exists(tmp):
    os.remove(tmp)
