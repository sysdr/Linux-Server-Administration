import psutil
import datetime
import platform
import time
import os
import json

def get_system_health_dict():
    cpu_percent = psutil.cpu_percent(interval=0.5)
    mem = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    boot_time_timestamp = psutil.boot_time()
    boot_time = datetime.datetime.fromtimestamp(boot_time_timestamp)
    uptime_seconds = (datetime.datetime.now() - boot_time).total_seconds()
    uptime_human = str(datetime.timedelta(seconds=int(uptime_seconds)))
    return {
        "timestamp": datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        "hostname": platform.node(),
        "os": f"{platform.system()} {platform.release()}",
        "cpu_percent": round(cpu_percent, 1),
        "mem_total_gb": round(mem.total / (1024**3), 2),
        "mem_used_gb": round(mem.used / (1024**3), 2),
        "mem_free_gb": round(mem.free / (1024**3), 2),
        "mem_percent": round(mem.percent, 1),
        "disk_total_gb": round(disk.total / (1024**3), 2),
        "disk_used_gb": round(disk.used / (1024**3), 2),
        "disk_free_gb": round(disk.free / (1024**3), 2),
        "disk_percent": round(disk.percent, 1),
        "uptime": uptime_human,
    }

def get_system_health():
    d = get_system_health_dict()
    print(f"--- System Health Report ({d['timestamp']}) ---")
    print(f"Hostname: {d['hostname']}")
    print(f"OS: {d['os']}")
    print(f"CPU Usage: {d['cpu_percent']}%")
    print(f"Memory: Total={d['mem_total_gb']}GB, Used={d['mem_used_gb']}GB, Free={d['mem_free_gb']}GB, Percent={d['mem_percent']}%")
    print(f"Disk (/): Total={d['disk_total_gb']}GB, Used={d['disk_used_gb']}GB, Free={d['disk_free_gb']}GB, Percent={d['disk_percent']}%")
    print(f"Uptime: {d['uptime']}")
    print("-" * 50)

if __name__ == "__main__":
    if os.getenv('RUN_IN_LOOP', 'false').lower() == 'true':
        while True:
            get_system_health()
            time.sleep(30)
    else:
        get_system_health()
