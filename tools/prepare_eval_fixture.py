"""Restore the unchanged validation conversations and their synthetic shot context."""
import hashlib
import json
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
out = ROOT / 'data' / 'whatif-val'
with zipfile.ZipFile(ROOT / 'evaluation' / 'whatif-val.zip') as archive:
    manifest = json.loads(archive.read('manifest.json'))
    for name, expected in manifest['files'].items():
        if name not in {'shots.csv', 'sessions.csv', 'conversations_val.jsonl'}:
            raise ValueError('Unexpected fixture member')
        data = archive.read(name)
        if hashlib.sha256(data).hexdigest() != expected:
            raise ValueError(f'Fixture checksum failed: {name}')
        destination = out / name
        if destination.exists() and destination.read_bytes() != data:
            raise ValueError(f'Refusing to overwrite a different fixture: {destination}')
        out.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(data)
print(f'Verified validation fixture: {out}')
