"""Bounded monitor for the project container; stops it on pressure or timeout.

Run on the Ubuntu host. Default is observation of an already running container;
--start explicitly starts the named project container after baseline checks.
Thresholds are conservative test policy, not hardware thermal specifications.
"""
import argparse
import json
from pathlib import Path
import signal
import subprocess
import time


def sample():
    memory={line.split(':')[0]:int(line.split()[1]) for line in Path('/proc/meminfo').read_text().splitlines()}
    values={'available_mib':memory['MemAvailable']/1024,'cpu_c':None,'gpu_c':None}
    for directory in Path('/sys/class/hwmon').glob('hwmon*'):
        try:
            name=(directory/'name').read_text().strip()
            if name in ('k10temp','coretemp','amdgpu'):
                temps=[int(p.read_text())/1000 for p in directory.glob('temp*_input')]
                key='gpu_c' if name=='amdgpu' else 'cpu_c'
                if temps:values[key]=max(temps)
        except (OSError,ValueError):pass
    return values


def unsafe(values):
    return (values['cpu_c'] is None or values['gpu_c'] is None
            or values['cpu_c']>=75 or values['gpu_c']>=75
            or values['available_mib']<4096)


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--start',action='store_true')
    p.add_argument('--seconds',type=int,default=60)
    a=p.parse_args()
    if not 1<=a.seconds<=60:p.error('Test windows must be between one and sixty seconds')
    container='tennis-lemonade'
    def interrupted(*_):raise KeyboardInterrupt
    for sig in (signal.SIGINT,signal.SIGTERM,signal.SIGHUP):signal.signal(sig,interrupted)
    try:
        baseline=sample();print(json.dumps({'baseline':baseline}),flush=True)
        if unsafe(baseline):raise SystemExit('Baseline failed; stopping the project container')
        if a.start:subprocess.run(['docker','start',container],check=True,timeout=15)
        end=time.monotonic()+a.seconds
        while time.monotonic()<end:
            values=sample();print(json.dumps(values),flush=True)
            if unsafe(values):raise RuntimeError('Temperature, memory, or sensor-availability limit reached')
            time.sleep(1)
    finally:
        subprocess.run(['docker','stop','-t','5',container],check=False,timeout=15)
        print('Project container stopped; no automatic restart.',flush=True)


if __name__=='__main__':main()
