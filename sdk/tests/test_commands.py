# sdk/tests/test_commands.py
import json
from zjdroid_agent.commands import (DumpDexInfo, DumpClass, BackSmali,
                                    DumpDex, DumpMem, DumpHeap, InvokeLua)

def parse(cmd):
    return json.loads(cmd.to_json())

def test_dump_dexinfo_has_action():
    assert parse(DumpDexInfo()) == {"action": "dump_dexinfo"}

def test_dump_class_carries_dexpath():
    assert parse(DumpClass(dexpath="/data/x.dex"))["dexpath"] == "/data/x.dex"

def test_backsmali_action_field():
    assert parse(BackSmali(dexpath="/x.dex"))["action"] == "backsmali"

def test_dump_dex_no_extra_fields():
    d = parse(DumpDex(dexpath="/y.dex"))
    assert d == {"dexpath": "/y.dex", "action": "dump_dexfile"}

def test_dump_mem_types():
    d = parse(DumpMem(start=100, length=10))
    assert isinstance(d["start"], int) and d["length"] == 10

def test_dump_heap_minimal():
    assert parse(DumpHeap()) == {"action": "dump_heap"}

def test_invoke_lua_filepath():
    assert parse(InvokeLua(filepath="/sdcard/a.lua"))["filepath"] == "/sdcard/a.lua"

def test_json_is_compact_no_spaces():
    assert " " not in DumpDexInfo().to_json()
