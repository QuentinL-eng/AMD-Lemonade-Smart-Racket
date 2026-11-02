"""Create a new transfer folder on an explicitly selected USB drive; never overwrite."""
from pathlib import Path
import argparse
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parent
PROJECT = Path('D:/EpsonRC70/Projects/TennisBuddyDayOne_20261029')
SCENE = Path('D:/EpsonRC70/Simulator/Simulator/SimObjects.dat')
CAD = Path('C:/Users/qslma/Downloads/Robot Arm Test Setup.xv3')


def sha(path):
    h = hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def copy_bundle(dest):
    dest = dest.resolve()
    if dest.exists():
        raise FileExistsError(f'Refusing to overwrite {dest}')
    items = []
    for p in PROJECT.iterdir():
        if p.is_file() and p.suffix.lower() in {'.sprj', '.prg', '.pts', '.dat', '.fg', '.pf', '.prgfg', '.vis'}:
            if p.name in {'IOLabels.dat', 'UserErrors.dat'} or p.suffix.lower() != '.dat':
                items.append((p, Path('RCPlusProject') / p.name))
    items += [(SCENE, Path('SimulatorScene/SimObjects.dat')),
              (CAD, Path('CAD') / CAD.name),
              (ROOT / 'TRANSFER_INSTRUCTIONS.md', Path('START_HERE.md'))]
    for name in ['README.md', 'paths.json', 'export_rcplus_logs.py', 'check_trajectory.py',
                 'generate_native_dayone.py', 'update_native_manifest.py',
                 'match_native_recording.py', 'plot_native_envelope.py', 'make_native_recap.py']:
        items.append((ROOT / name, Path('Sources') / name))
    for name in ['DayOne.prg', 'defined_points.json']:
        items.append((ROOT / 'rcplus' / name, Path('Sources') / name))
    for p in (ROOT / 'recordings/native').rglob('*'):
        if p.is_file() and p.suffix.lower() not in {'.avi', '.mp4', '.svg', '.png'}:
            items.append((p, Path('Recordings') / p.relative_to(ROOT / 'recordings/native')))
    items.append((ROOT / 'recordings/native/executed_envelope.png', Path('Recordings/executed_envelope.png')))
    for source, _ in items:
        if not source.is_file():
            raise FileNotFoundError(source)
    dest.mkdir(parents=False)
    hashes = {}
    for source, relative in items:
        target = dest / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
        digest = sha(source)
        if sha(target) != digest:
            raise OSError(f'Copy verification failed: {relative}')
        hashes[relative.as_posix()] = digest
    (dest / 'SHA256SUMS.json').write_text(json.dumps(hashes, indent=2), encoding='utf-8')
    print(json.dumps(dict(destination=str(dest), verified_files=len(hashes),
                          bytes=sum((dest / r).stat().st_size for r in hashes)), indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('destination', type=Path)
    copy_bundle(parser.parse_args().destination)
