#!/usr/bin/env python3
"""Build an unsigned, one-folder Haven 42 development package and evidence."""

from __future__ import annotations

import argparse
import hashlib
import importlib.metadata
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import sys
import tarfile
import zipfile


ROOT = Path(__file__).resolve().parent.parent
RESOURCE_PATHS = (
    "web/static/index.html",
    "web/static/app.js",
    "web/static/styles.css",
    "config/text-capability-model-recommendations.json",
    "config/evidence-catalog.tsv",
    "config/install-component-registry.json",
)
ALLOWED_PACKAGE_ENTRIES = {"haven42", "haven42.exe", "_internal", "DEVELOPMENT-BUILD.txt"}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_json(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def build_resource_manifest() -> None:
    resources = []
    for relative in RESOURCE_PATHS:
        path = ROOT / relative
        resources.append({
            "path": relative,
            "sha256": sha256(path),
            "sizeBytes": path.stat().st_size,
        })
    write_json(ROOT / "package/resource-integrity.json", {
        "schemaVersion": 1,
        "algorithm": "sha256",
        "resources": resources,
    })


def dependency_records() -> list[dict[str, str]]:
    records = []
    for distribution in importlib.metadata.distributions():
        name = distribution.metadata.get("Name")
        if name:
            records.append({
                "name": name,
                "version": distribution.version,
                "license": distribution.metadata.get("License") or "NOASSERTION",
            })
    return sorted(records, key=lambda item: item["name"].lower())


def create_archive(package_dir: Path, artifact_dir: Path, target: str) -> Path:
    artifact_dir.mkdir(parents=True, exist_ok=True)
    if platform.system() == "Windows":
        archive = artifact_dir / f"haven42-{target}-unsigned-development.zip"
        with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as output:
            for path in sorted(package_dir.rglob("*")):
                if path.is_file():
                    output.write(path, Path("haven42") / path.relative_to(package_dir))
        return archive
    archive = artifact_dir / f"haven42-{target}-unsigned-development.tar.gz"
    with tarfile.open(archive, "w:gz") as output:
        output.add(package_dir, arcname="haven42", recursive=True)
    return archive


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", default=str(ROOT / "dist" / "portable"))
    parser.add_argument("--skip-pyinstaller", action="store_true")
    args = parser.parse_args()
    output = Path(args.output).resolve()
    work = output / "work"
    artifact_dir = output / "artifacts"
    target = f"{platform.system().lower()}-{platform.machine().lower()}"
    build_resource_manifest()
    if not args.skip_pyinstaller:
        subprocess.run([
            sys.executable, "-m", "PyInstaller",
            "--noconfirm", "--clean",
            "--distpath", str(output / "bundle"),
            "--workpath", str(work),
            str(ROOT / "package/haven42.spec"),
        ], cwd=ROOT, check=True)
    package_dir = output / "bundle" / "haven42"
    if not package_dir.is_dir():
        raise SystemExit("PyInstaller one-folder output was not found.")
    unexpected = {path.name for path in package_dir.iterdir()} - ALLOWED_PACKAGE_ENTRIES
    if unexpected:
        raise SystemExit(f"Unexpected top-level package entries: {sorted(unexpected)}")
    (package_dir / "DEVELOPMENT-BUILD.txt").write_text(
        "Haven 42 unsigned development build.\n"
        "No installer, signing, notarization, updater activation, or production-readiness claim.\n",
        encoding="utf-8",
    )
    dependencies = dependency_records()
    evidence = output / "evidence"
    write_json(evidence / "dependency-inventory.json", {
        "schemaVersion": 1, "target": target, "dependencies": dependencies,
    })
    write_json(evidence / "haven42.cdx.json", {
        "bomFormat": "CycloneDX",
        "specVersion": "1.5",
        "version": 1,
        "metadata": {"component": {"type": "application", "name": "Haven 42", "version": "0.3.0"}},
        "components": [
            {"type": "library", "name": item["name"], "version": item["version"],
             "licenses": [{"license": {"name": item["license"]}}]}
            for item in dependencies
        ],
    })
    notices = [
        "THIRD-PARTY NOTICES — unsigned development package",
        "",
        "This inventory is generated from build-environment package metadata.",
        "NOASSERTION means the installed metadata did not provide a license expression.",
        "",
    ]
    notices.extend(f"{item['name']} {item['version']} — {item['license']}" for item in dependencies)
    (evidence / "THIRD-PARTY-NOTICES.txt").write_text("\n".join(notices) + "\n", encoding="utf-8")
    archive = create_archive(package_dir, artifact_dir, target)
    checksum_targets = [archive, *sorted(evidence.iterdir())]
    (artifact_dir / "SHA256SUMS").write_text(
        "".join(f"{sha256(path)}  {path.name}\n" for path in checksum_targets),
        encoding="utf-8",
    )
    shutil.copy2(evidence / "dependency-inventory.json", artifact_dir)
    shutil.copy2(evidence / "haven42.cdx.json", artifact_dir)
    shutil.copy2(evidence / "THIRD-PARTY-NOTICES.txt", artifact_dir)
    print(artifact_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
