# sdk/tests/test_logcat.py
from zjdroid_agent.logcat import LogcatStream

def _fake_stream():
    s = LogcatStream(device=None, tags=['zjdroid-shell-com.example'])
    for ln in ['xxx unrelated', 'zjdroid-shell the cmd = backsmali', 'done']:
        s._buf.append(ln)
    return s

def test_wait_for_matches():
    s = _fake_stream()
    res = s.wait_for(lambda ln: 'backsmali' in ln, timeout=1.0)
    assert any('backsmali' in r for r in res)

def test_wait_for_timeout_returns_empty():
    s = _fake_stream()
    res = s.wait_for(lambda ln: 'never-here' in ln, timeout=0.5)
    assert res == []
