from pathlib import Path
import os
import zipfile

ROOT = Path(__file__).resolve().parents[1]
MODULES = [
    (ROOT / 'modules' / 'qinglong-2.10.13-sparse1024', ROOT / 'release' / 'QL-2.10.13-sparse1024-stuka.zip'),
    (ROOT / 'modules' / 'qinglong-2.15.5-full-sparse1024', ROOT / 'release' / 'QL-2.15.5-full-sparse1024-stuka.zip'),
    (ROOT / 'modules' / 'qinglong-2.15.5-online-sparse1024', ROOT / 'release' / 'QL-2.15.5-online-sparse1024-stuka.zip'),
]


def build_zip(src: Path, out: Path) -> None:
    if not src.exists():
        raise FileNotFoundError(src)
    out.parent.mkdir(parents=True, exist_ok=True)
    if out.exists():
        out.unlink()
    with zipfile.ZipFile(out, 'w', compression=zipfile.ZIP_DEFLATED, allowZip64=True) as zf:
        for root, _, files in os.walk(src):
            for name in files:
                path = Path(root) / name
                arcname = path.relative_to(src).as_posix()
                zf.write(path, arcname)
    print(f'{out.relative_to(ROOT)} {out.stat().st_size}')


def main() -> None:
    for src, out in MODULES:
        build_zip(src, out)


if __name__ == '__main__':
    main()
