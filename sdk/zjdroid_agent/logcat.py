# sdk/zjdroid_agent/logcat.py
"""后台 adb logcat 读取器：持续流 + 按需查询最近匹配行。"""
from __future__ import annotations
import subprocess, threading, time
from collections import deque
from typing import Iterable

class LogcatStream:
    def __init__(self, device: str | None, tags: Iterable[str]):
        self._buf: deque[str] = deque(maxlen=20000)
        self._stop = threading.Event()
        self._tags = tuple(tags)
        self._proc: subprocess.Popen | None = None
        self._device = device

    def start(self) -> None:
        cmd = ['adb']
        if self._device:
            cmd += ['-s', self._device]
        cmd += ['logcat', '-v', 'threadtime'] + [f'-s{t}' for t in self._tags]
        self._proc = subprocess.Popen(cmd, stdout=subprocess.PIPE,
                                      stderr=subprocess.STDOUT, text=True,
                                      bufsize=1)
        threading.Thread(target=self._pump, daemon=True).start()

    def _pump(self) -> None:
        assert self._proc and self._proc.stdout
        for line in self._proc.stdout:
            self._buf.append(line.rstrip('\n'))
            if self._stop.is_set():
                self._proc.terminate(); break

    def wait_for(self, predicate, timeout: float = 30.0, since_idx: int = 0) -> list[str]:
        """阻塞直到 predicate(line) 为真或超时，返回匹配行。"""
        deadline = time.time() + timeout
        while time.time() < deadline:
            snapshot = list(self._buf)
            matched = [ln for ln in snapshot[since_idx:] if predicate(ln)]
            if matched:
                return matched
            time.sleep(0.2)
        return []

    @property
    def index(self) -> int:
        return len(self._buf)

    def stop(self) -> None:
        self._stop.set()
