import argparse
import hashlib
from pathlib import Path
import zipfile

parser = argparse.ArgumentParser()
parser.add_argument("binary", type=Path)
parser.add_argument("output", type=Path)
args = parser.parse_args()
data = args.binary.read_bytes()
if data[:6] != b"\x7fELF\x02\x01" or data[18:20] != b"\xb7\x00":
    raise SystemExit("Android arm64 ELF required")
root = Path(__file__).resolve().parent
args.output.parent.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(args.output, "w", zipfile.ZIP_DEFLATED) as bundle:
    bundle.writestr("ksud", data)
    bundle.writestr("ksud.sha256", hashlib.sha256(data).hexdigest() + "\n")
    bundle.write(root / "ksud-test.sh", "ksud-test.sh")
    bundle.write(root / "README.md", "README.md")
