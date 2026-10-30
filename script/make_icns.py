from pathlib import Path
import struct
root=Path(__file__).resolve().parent.parent/'Resources'
chunks=[]
for size,kind in [(16,b'icp4'),(32,b'icp5'),(64,b'icp6'),(128,b'ic07'),(256,b'ic08'),(512,b'ic09'),(1024,b'ic10')]:
    data=(root/'Brand'/f'icon-{size}.png').read_bytes()
    chunks.append(kind+struct.pack('>I',len(data)+8)+data)
payload=b''.join(chunks)
(root/'AppIcon.icns').write_bytes(b'icns'+struct.pack('>I',len(payload)+8)+payload)
