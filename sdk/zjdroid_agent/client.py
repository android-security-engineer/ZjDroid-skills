# sdk/zjdroid_agent/client.py
"""Agent 调用入口：发命令、取结果。"""
from __future__ import annotations
import subprocess
from .commands import Command
from .logcat import LogcatStream

class ZjDroidClient:
    def __init__(self, package: str, device: str | None = None):
        self.package = package
        self.device = device
        shell_tag = f'zjdroid-shell-{package}'
        api_tag = f'zjdroid-apimonitor-{package}'
        self.stream = LogcatStream(device, [shell_tag, api_tag])
        self.stream.start()

    def _adb(self, *args: str) -> str:
        cmd = ['adb'] + (['-s', self.device] if self.device else []) + list(args)
        return subprocess.run(cmd, capture_output=True, text=True, check=True).stdout

    def pidof(self) -> int | None:
        out = self._adb('shell', 'pidof', self.package).strip()
        return int(out) if out.isdigit() else None

    def invoke(self, cmd: Command, timeout: float = 30.0) -> list[str]:
        """发送命令并返回 logcat 中本次命令产生的输出行。"""
        pid = self.pidof()
        if pid is None:
            raise RuntimeError(f'目标进程未运行: {self.package}')
        from_idx = self.stream.index
        # 转义 JSON 中的单引号，避免破坏 shell 引用
        cmd_json = cmd.to_json().replace("'", r"'\''")
        self._adb('shell', 'am', 'broadcast', '-a', 'com.zjdroid.invoke',
                  '--ei', 'target', str(pid),
                  '--es', 'cmd', f"'{cmd_json}'")
        action = cmd.action
        lines = self.stream.wait_for(
            lambda ln: action in ln or 'dump' in ln.lower() or 'backsmali' in ln.lower(),
            timeout=timeout, since_idx=from_idx)
        return lines if lines else ['(timeout) no output for action=' + action]

    def close(self) -> None:
        self.stream.stop()
