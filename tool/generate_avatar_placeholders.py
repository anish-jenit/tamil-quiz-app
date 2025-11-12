import base64
import os

# Tiny 1x1 PNG (transparent)
PNG_BASE64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII="

OUT_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'avatars')
os.makedirs(OUT_DIR, exist_ok=True)

names = [f'male_{i+1}.png' for i in range(4)] + [f'female_{i+1}.png' for i in range(4)]

for name in names:
    path = os.path.join(OUT_DIR, name)
    with open(path, 'wb') as f:
        f.write(base64.b64decode(PNG_BASE64))
    print('Wrote', path)

print('Done: placeholder avatars created:', len(names))
