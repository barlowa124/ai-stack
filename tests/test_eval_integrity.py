"""Integrity checks for the eval battery.

The task directories are fixtures for eval.ps1: each holds a prompt plus
a verify_<id>.py oracle, and committed solutions may be intentionally
buggy. These tests validate harness structure, not model output; they
never execute a task verifier.
"""
from __future__ import annotations

import py_compile
import re
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
TASKS = ROOT / "eval" / "tasks"
TASK_DIRS = sorted(
    d for d in TASKS.iterdir() if d.is_dir() and re.fullmatch(r"t\d+", d.name)
)


def test_task_dirs_exist():
    assert TASK_DIRS, "no task directories found under eval/tasks"


@pytest.mark.parametrize("task_dir", TASK_DIRS, ids=lambda d: d.name)
def test_task_has_prompt_and_verifier(task_dir):
    prompt = task_dir / "prompt.txt"
    verifier = task_dir / f"verify_{task_dir.name}.py"
    assert prompt.is_file(), f"{task_dir.name}: missing prompt.txt"
    assert prompt.read_text().strip(), f"{task_dir.name}: empty prompt.txt"
    assert verifier.is_file(), f"{task_dir.name}: missing {verifier.name}"


@pytest.mark.parametrize("task_dir", TASK_DIRS, ids=lambda d: d.name)
def test_verifier_compiles_and_asserts(task_dir):
    verifier = task_dir / f"verify_{task_dir.name}.py"
    src = verifier.read_text()
    py_compile.compile(str(verifier), doraise=True)
    assert "assert" in src, f"{verifier.name}: verifier has no assertions"


@pytest.mark.parametrize("task_dir", TASK_DIRS, ids=lambda d: d.name)
def test_task_test_files_compile(task_dir):
    for test_file in task_dir.glob("test_*.py"):
        py_compile.compile(str(test_file), doraise=True)


def test_eval_ps1_enumerates_every_task():
    ps1 = (ROOT / "eval" / "eval.ps1").read_text()
    listed = set(re.findall(r"id='(t\d+)'", ps1))
    on_disk = {d.name for d in TASK_DIRS}
    assert listed == on_disk, (
        f"eval.ps1 task table {sorted(listed)} != dirs on disk {sorted(on_disk)}"
    )
