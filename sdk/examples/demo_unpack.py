# sdk/examples/demo_unpack.py
"""端到端示例：Agent 用 SDK 对加固 App 脱壳。
用法: python demo_unpack.py com.example.target /sdcard/zjdroid-out/
"""
import sys, re
from zjdroid_agent import ZjDroidClient, DumpDexInfo, BackSmali

def main(pkg: str, outdir: str):
    client = ZjDroidClient(package=pkg)
    print('[1] 取已加载 DEX 信息...')
    lines = client.invoke(DumpDexInfo(), timeout=60)
    # ZjDroid 输出形如 "... dexpath=/data/app/.../base.apk classes=N ..."
    dex_paths = re.findall(r'dexpath=([^\s,]+)', '\n'.join(lines))
    if not dex_paths:
        print('未发现 dex，可能目标未运行或未注入。原始输出:'); print('\n'.join(lines)); return 1

    print(f'[2] 发现 {len(dex_paths)} 个 dex，逐个 backsmali...')
    for dp in dex_paths:
        print(f'  -> {dp}')
        client.invoke(BackSmali(dexpath=dp), timeout=120)

    print('[3] 拉取产物到', outdir)
    client._adb('shell', 'mkdir', '-p', outdir)
    files = client._adb('shell', f'ls /data/data/{pkg}/files/ 2>/dev/null').split()
    for f in files:
        client._adb('pull', f'/data/data/{pkg}/files/{f}', outdir)
    print('完成。')
    client.close()
    return 0

if __name__ == '__main__':
    sys.exit(main(sys.argv[1], sys.argv[2]))
