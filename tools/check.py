from pathlib import Path
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ZIPS = [
    ROOT / 'release' / 'QL-2.10.13-sparse1024-stuka.zip',
    ROOT / 'release' / 'QL-2.15.5-full-sparse1024-stuka.zip',
    ROOT / 'release' / 'QL-2.15.5-online-sparse1024-stuka.zip',
]
FORBIDDEN = ['auto_resize_if_needed', 'manual_resize_from_config', 'ROOTFS_MB', 'ROOTFS_SIZE_FILE', 'resize2fs']


def read_text(zf: zipfile.ZipFile, name: str) -> str:
    return zf.read(name).decode('utf-8')


def check_zip(path: Path) -> bool:
    ok = True
    print(path.relative_to(ROOT))
    if not path.exists():
        print('  missing=True')
        return False
    with zipfile.ZipFile(path) as zf:
        bad_file = zf.testzip()
        customize = read_text(zf, 'customize.sh')
        qlctl = read_text(zf, 'system/bin/qlctl')
        prop = read_text(zf, 'module.prop')
        checks = {
            'zip_ok': bad_file is None,
            'sparse_dd': 'count=0 seek=1024' in customize,
            'busybox_mount': '"$BB" mount -o loop,rw' in customize or '"$BUSYBOX" mount -o loop,rw' in qlctl,
            'default_auth': 'admin123' in customize and 'admin/admin123' in prop,
            'python_cmd': 'install_python_ql()' in qlctl and 'python) install_python_ql ;;' in qlctl,
            'no_resize_logic': not any(token in customize + qlctl for token in FORBIDDEN),
        }
        for key, value in checks.items():
            print(f'  {key}={value}')
            ok = ok and value
        name = next((line for line in prop.splitlines() if line.startswith('name=')), '')
        print(f'  {name}')
    return ok


def main() -> None:
    ok = True
    for path in ZIPS:
        ok = check_zip(path) and ok
    if not ok:
        sys.exit(1)


if __name__ == '__main__':
    main()
