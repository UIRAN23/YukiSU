import hashlib
import os
from pathlib import Path
import subprocess
import tempfile

source = Path(__file__).with_name("ksud-test.sh").read_text()
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    base = root / "backup"
    live = root / "live"
    package = root / "package"
    package.mkdir()
    commands = root / "commands"
    commands.mkdir()
    for name, output in (("id", "0"), ("chcon", ""), ("chown", ""), ("sync", "")):
        command = commands / name
        command.write_text("#!/bin/sh\nprintf '%s\\n' '" + output + "'\n")
        command.chmod(0o755)
    old = b"#!/bin/sh\necho 'uapi_version: 3'\n"
    new = b"#!/bin/sh\necho 'ksud version test (code: 1, uapi: 3)'\n"
    live.write_bytes(old)
    live.chmod(0o755)
    (package / "ksud").write_bytes(new)
    (package / "ksud.sha256").write_text("bad\n")
    script = package / "ksud-test.sh"
    script.write_text(source.replace("BASE=/data/adb/ace5-ksud-test", "BASE=" + str(base)).replace("LIVE=/data/adb/ksud", "LIVE=" + str(live)))
    env = dict(os.environ, PATH=str(commands) + os.pathsep + os.environ["PATH"])
    def run(action):
        return subprocess.run(["sh", str(script), action], env=env, capture_output=True, text=True)
    assert run("install").returncode != 0
    assert live.read_bytes() == old and not (base / "original").exists()
    incompatible = new.replace(b"uapi: 3", b"uapi: 4")
    (package / "ksud").write_bytes(incompatible)
    (package / "ksud.sha256").write_text(hashlib.sha256(incompatible).hexdigest())
    assert run("install").returncode != 0
    assert live.read_bytes() == old and not (base / "original").exists()
    (package / "ksud").write_bytes(new)
    (package / "ksud.sha256").write_text(hashlib.sha256(new).hexdigest())
    result = run("install")
    assert result.returncode == 0, result.stderr
    assert live.read_bytes() == new and (base / "original").read_bytes() == old
    assert run("install").returncode != 0
    (base / "original.sha256").write_text("bad")
    assert run("restore").returncode != 0 and live.read_bytes() == new
    (base / "original.sha256").write_text(hashlib.sha256(old).hexdigest())
    result = run("restore")
    assert result.returncode == 0, result.stderr
    assert live.read_bytes() == old
    print("Hash/UAPI rejection, backup protection, install and restore fixtures passed")
