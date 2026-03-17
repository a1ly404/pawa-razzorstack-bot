#!/usr/bin/env python3
"""Pawa recording retention cleanup.

Deletes oldest WAV/MP3 recordings when total usage in the recordings
directory exceeds a configurable threshold (default 250 GB).

Usage:
    python3 pawa_retention_cleanup.py [--dry-run] [--limit-gb 250]
"""

import argparse
import os
import sys
from pathlib import Path

RECORDINGS_DIR = Path(os.environ.get("PAWA_RECORDINGS_PATH", "/home/daffy/pawa-recordings"))
DEFAULT_LIMIT_GB = 250
AUDIO_EXTENSIONS = {".wav", ".mp3", ".ogg", ".flac", ".pcm"}


def get_recordings(directory: Path) -> list[tuple[Path, float, int]]:
    """Return list of (path, mtime, size) for audio files, oldest first."""
    files: list[tuple[Path, float, int]] = []
    for f in directory.rglob("*"):
        if f.is_file() and f.suffix.lower() in AUDIO_EXTENSIONS:
            stat = f.stat()
            files.append((f, stat.st_mtime, stat.st_size))
    files.sort(key=lambda x: x[1])  # oldest first
    return files


def get_total_size(files: list[tuple[Path, float, int]]) -> int:
    return sum(size for _, _, size in files)


def cleanup(limit_gb: float, dry_run: bool = False) -> None:
    if not RECORDINGS_DIR.exists():
        print(f"Recordings directory not found: {RECORDINGS_DIR}")
        return

    files = get_recordings(RECORDINGS_DIR)
    total_bytes = get_total_size(files)
    limit_bytes = int(limit_gb * 1024 * 1024 * 1024)

    total_gb = total_bytes / (1024**3)
    print(f"Current usage: {total_gb:.2f} GB / {limit_gb:.0f} GB limit")
    print(f"Total recordings: {len(files)}")

    if total_bytes <= limit_bytes:
        print("Within limit. Nothing to delete.")
        return

    excess = total_bytes - limit_bytes
    deleted_count = 0
    deleted_bytes = 0

    for path, mtime, size in files:
        if deleted_bytes >= excess:
            break
        if dry_run:
            print(f"  [DRY RUN] Would delete: {path} ({size / (1024**2):.1f} MB)")
        else:
            try:
                path.unlink()
                print(f"  Deleted: {path} ({size / (1024**2):.1f} MB)")
                # Remove empty parent dirs
                parent = path.parent
                if parent != RECORDINGS_DIR and not any(parent.iterdir()):
                    parent.rmdir()
            except OSError as e:
                print(f"  Error deleting {path}: {e}", file=sys.stderr)
                continue
        deleted_count += 1
        deleted_bytes += size

    action = "Would delete" if dry_run else "Deleted"
    print(f"\n{action} {deleted_count} files ({deleted_bytes / (1024**3):.2f} GB)")
    remaining = (total_bytes - deleted_bytes) / (1024**3)
    print(f"Remaining usage: {remaining:.2f} GB")


def main() -> None:
    parser = argparse.ArgumentParser(description="Pawa recording retention cleanup")
    parser.add_argument(
        "--dry-run", action="store_true", help="Show what would be deleted"
    )
    parser.add_argument(
        "--limit-gb",
        type=float,
        default=DEFAULT_LIMIT_GB,
        help=f"Max GB before cleanup (default: {DEFAULT_LIMIT_GB})",
    )
    args = parser.parse_args()
    cleanup(limit_gb=args.limit_gb, dry_run=args.dry_run)


if __name__ == "__main__":
    main()
