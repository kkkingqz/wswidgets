#!/usr/bin/env python3
"""Run QML composition tests within Quickshell's configuration root."""
from pathlib import Path
import os
import shutil
import subprocess
import sys
import tempfile
import json
import time

root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix="widgets-qml-") as temporary:
    config = Path(temporary) / "config"
    shutil.copytree(root / "quickshell", config)
    config.chmod(0o755)
    (config / "shell.qml").unlink(missing_ok=True)
    shutil.copy(root / "tests/qml/shell.qml", config / "shell.qml")
    if (root / "tests/qml/broken").exists():
        shutil.copytree(root / "tests/qml/broken", config / "broken")
    env = dict(os.environ, QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software")
    env.pop("WAYLAND_DISPLAY", None)
    env["WIDGETS_SOCKET"] = str(Path(temporary)/"control.sock")
    result = subprocess.run([sys.argv[1], "-p", str(config)], env=env, timeout=15)
    if result.returncode:
        sys.exit(result.returncode)
    # Desktop facts through a fake wsdbus-ctl (quickshell/framework/Desktop.qml).
    desktop = Path(temporary) / "desktop"
    shutil.copytree(root / "quickshell", desktop)
    desktop.chmod(0o755)
    (desktop / "shell.qml").unlink()
    shutil.copy(root / "tests/qml/desktop/shell.qml", desktop / "shell.qml")
    fake = Path(temporary) / "wsdbus-ctl"
    fake.write_text(f"""#!{sys.executable}
import json, sys, time
assert sys.argv[1:] == ["--json", "watch"], sys.argv
def emit(frame): print(json.dumps(frame), flush=True)
emit({{"snapshot": True, "revision": 1, "provider": "fake", "version": 1, "capabilities": [],
      "facts": {{"session.locked": False, "appearance.scheme": "dark"}}, "windows": []}})
time.sleep(0.3)
emit({{"revision": 2, "windows": [], "removed": ["5"]}})
emit({{"revision": 3, "facts": {{"session.locked": True}}, "removed": []}})
time.sleep(0.3)
emit({{"revision": 4, "facts": {{}}, "removed": ["appearance.scheme"]}})
time.sleep(10)
""")
    fake.chmod(0o755)
    result = subprocess.run([sys.argv[1], "-p", str(desktop)], env=dict(env, WIDGETS_DESKTOP_CTL=str(fake)), timeout=15)
    if result.returncode:
        sys.exit(result.returncode)
    env["WIDGETS_IPC_TEST"] = "1"
    from socket_client import Peer
    endpoint = Path(temporary)/"control.sock"
    env["WIDGETS_SOCKET"] = str(endpoint)
    command = [sys.argv[1], "-p", str(config)]
    with tempfile.TemporaryFile(mode="w+") as log:
        process = subprocess.Popen(command, env=env, stdout=log, stderr=log, umask=0o077)
        peers = []
        def cli(method, **args):
            peer = Peer(endpoint); peers.append(peer)
            assert peer.greeting['type'] == 'hello'
            result = peer.call(method, **args); peer.close(); peers.remove(peer)
            return result
        try:
            deadline = time.monotonic()+3
            while (not endpoint.exists() or endpoint.stat().st_mode & 0o077) and time.monotonic()<deadline:
                assert process.poll() is None, "runtime exited"
                time.sleep(.02)
            assert endpoint.exists(), "missing runtime socket"
            assert not cli('show', id='example')['result'], 'no adapter must reject opening'
            adapter = Peer(endpoint, 'adapter'); peers.append(adapter)
            state = adapter.greeting['state']
            assert state['protocolVersion'] == 2 and state['pid'] == process.pid and state['adapter']['connected']
            colors = {'background':'#80203040', 'foreground':'#fff0f1f2'}
            assert not cli('setTheme', **colors)['ok'], 'CLI can replace desktop palette'
            assert not adapter.call('setTheme', **{**colors, 'background':'invalid'})['ok'], 'invalid palette accepted'
            assert not adapter.call('setTheme', **colors, font={'family':'Sans','pixelSize':0,'weight':400,'italic':False})['ok'], 'invalid font accepted'
            assert adapter.call('setTheme', **colors)['result'], 'native theme rejected'
            keys = ['normal','focus','hover','hover+focus','pressed','pressed+focus','pressed+hover','pressed+hover+focus',
                    'checked','checked+focus','checked+hover','checked+hover+focus','checked+pressed','checked+pressed+focus',
                    'checked+pressed+hover','checked+pressed+hover+focus','disabled']
            buttons = {'states': {key: {'background':'#ff123456','foreground':'#80abcdef','borderColor':'#ff405060',
                       'borderWidth':1,'focusColor':'#ffabcdef','focusWidth':2 if 'focus' in key else 0} for key in keys},
                       'metrics': {'radius':8,'paddingTop':3,'paddingRight':24,'paddingBottom':3,'paddingLeft':24,
                                   'minimumHeight':28,'transitionMs':0},
                       'font': {'family':'Sans','pixelSize':14.5,'weight':700,'italic':False}}
            font={'family':'Monospace','pixelSize':15.5,'weight':400,'italic':True}
            assert adapter.call('setTheme', **colors, buttons=buttons, font=font)['result'], 'font/button theme rejected by runtime socket'
            time.sleep(.05)
            log.seek(0)
            assert 'QML socket button applied: #ff123456/#80abcdef' in log.read(), 'socket button theme not rendered'
            log.seek(0)
            assert 'QML socket font applied: Monospace/11.625' in log.read(), 'socket font not rendered'
            assert not cli('show', id='unknown')['result']
            assert cli('show', id='example')['result']
            assert adapter.read()['state']['widgets']['example']['phase'] == 'preparing'
            assert not cli('placed', id='example', requestId=1)['ok'], 'role violation'
            assert adapter.call('placed', id='example', requestId=1)['result']
            assert adapter.call('setTheme', background='#fff6f5f4', foreground='#ff222226')['result']
            time.sleep(.05)
            log.seek(0)
            assert 'QML native theme applied: #80203040/#f0f1f2' in log.read(), 'native dark palette not rendered'
            log.seek(0)
            assert 'QML native theme applied: #f6f5f4/#222226' in log.read(), 'native light palette not rendered'
            replacement = Peer(endpoint, 'adapter'); peers.append(replacement)
            assert replacement.greeting['state']['widgets']['example']['phase'] == 'opening'
            adapter.close(); peers.remove(adapter)
            assert cli('status')['result']['adapter']['connected'], 'old EOF affected replacement'
            replacement.close(); peers.remove(replacement)
            time.sleep(.05)
            state = cli('status')['result']
            assert not state['adapter']['connected'] and state['widgets']['example']['phase'] == 'closed'
            adapter = Peer(endpoint, 'adapter'); peers.append(adapter)
            assert cli('show', id='example')['result']
            time.sleep(2.1)
            state = cli('status')['result']
            assert state['widgets']['example']['phase'] == 'closed' and 'timed out' in state['lastError']['reason']
            assert cli('show', id='example')['result']
            state = cli('status')['result']
            reason = 'Пример ошибки'
            frame = json.dumps({'protocolVersion':2, 'type':'command', 'seq':99, 'method':'placementFailed',
                                'args':{'id':'example', 'requestId':state['widgets']['example']['requestId'], 'reason':reason}}, ensure_ascii=False).encode()+b'\n'
            split = frame.index('П'.encode())+1
            adapter.socket.sendall(frame[:split]); time.sleep(.05); adapter.socket.sendall(frame[split:])
            while adapter.read().get('seq') != 99: pass
            assert cli('status')['result']['lastError']['reason'] == reason, 'fragmented UTF-8 corrupted'
            adapter.close(); peers.remove(adapter); time.sleep(.05)
            import socket
            follow = ''.join(json.dumps(frame)+'\n' for frame in [
                {'protocolVersion':2,'type':'hello','role':'adapter'},
                {'protocolVersion':2,'type':'command','seq':1,'method':'toggle','args':{'id':'example'}},
                {'protocolVersion':2,'type':'command','seq':2,'method':'placed','args':{'id':'example','requestId':state['widgets']['example']['requestId']+2}}])
            for bad in ['broken JSON', json.dumps({'protocolVersion':2,'type':'hello','role':'invalid'}), 'x'*65537]:
                with socket.socket(socket.AF_UNIX) as rejected:
                    rejected.connect(str(endpoint)); rejected.sendall((bad+'\n'+follow).encode()); time.sleep(.05)
                time.sleep(.05)
                result=cli('status')['result']
                assert not result['adapter']['connected'], 'rejected peer became ghost adapter'
                assert all(w['phase']=='closed' for w in result['widgets'].values()), 'rejected peer dispatched command'
            print("Socket snapshots, CLI, takeover, EOF, deadlines, UTF-8 and permanent rejection passed")
        except Exception:
            log.seek(0); print(log.read()); raise
        finally:
            for peer in peers: peer.close()
            process.terminate(); process.wait(timeout=3)
