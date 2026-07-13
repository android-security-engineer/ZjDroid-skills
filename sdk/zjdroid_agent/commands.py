# sdk/zjdroid_agent/commands.py
"""ZjDroid 命令对象。每个命令 = 一个 action JSON。"""
from __future__ import annotations
from dataclasses import dataclass, asdict, field
import json

@dataclass
class Command:
    """基类：所有命令最终产出 {'action': ..., ...} JSON。"""
    action: str
    def to_json(self) -> str:
        d = {k: v for k, v in asdict(self).items() if v is not None}
        d['action'] = self.action
        return json.dumps(d, separators=(',', ':'), ensure_ascii=False)

@dataclass
class DumpDexInfo(Command):
    action: str = 'dump_dexinfo'

@dataclass
class DumpClass(Command):
    dexpath: str = field(kw_only=True, default=None)
    action: str = 'dump_class'

@dataclass
class BackSmali(Command):
    dexpath: str = field(kw_only=True, default=None)
    action: str = 'backsmali'

@dataclass
class DumpDex(Command):
    dexpath: str = field(kw_only=True, default=None)
    action: str = 'dump_dexfile'

@dataclass
class DumpMem(Command):
    start: int = field(kw_only=True, default=0)
    length: int = field(kw_only=True, default=0)
    action: str = 'dump_mem'

@dataclass
class DumpHeap(Command):
    action: str = 'dump_heap'

@dataclass
class InvokeLua(Command):
    filepath: str = field(kw_only=True, default=None)
    action: str = 'invoke'
