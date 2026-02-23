# Secure Headless Lab — Implementation Guide

Step-by-step guide to run the Secure Headless Lab: a Multipass VM with Nginx, UFW, and a sysadmin user, plus a dashboard that shows real VM metrics.

---

## First: Clone the Repo and Go to the Project Directory

1. **Clone the repository** (if you don’t have it yet):

   ```bash
   git clone <repository-url>
   cd Linux-Server-Administration
   ```

2. **Go into the project directory** — all commands in this guide are run from here:

   ```bash
   cd day7/secure_headless_lab
   ```

   You must be inside **`secure_headless_lab`** when you run `./start.sh`, `./stop.sh`, `./run_tests.sh`, or `sudo ./fix-multipass-wsl2.sh`.

---

## What This Project Does

- **Launches** an Ubuntu VM (Multipass) with cloud-init.
- **Configures** the VM: Nginx, UFW (SSH + HTTP allowed), and a `sysadmin` user.
- **Verifies** Nginx, UFW, and SSH; writes results to `status.json`.
- **Starts** a web dashboard so you can see VM metrics and, from Windows, view the VM’s Nginx page via a proxy.

---

## Prerequisites

| Requirement | Purpose |
|------------|---------|
| **Multipass** | Run the Ubuntu VM |
| **jq** | Parse VM info (IP, etc.) in scripts |
| **Python 3** | Run the dashboard |
| **user-data.yaml** | Must exist in this directory (cloud-init config) |

---

## Step 1: Install Multipass and jq

**Linux (e.g. Ubuntu / WSL2):**

```bash
sudo snap install multipass --classic
sudo apt-get update && sudo apt-get install -y jq
```

**Check:**

```bash
multipass version
jq --version
```

---

## Step 2: Fix Multipass on WSL2 (if you see a cert error)

If you get:

`failed to open file '.../multipass_root_cert.pem': No such file or directory`

run this **once** from the project directory:

```bash
sudo ./fix-multipass-wsl2.sh
```

Then try:

```bash
multipass list
```

---

## Step 3: (Optional) Add Your SSH Key

Edit `user-data.yaml` and replace `REPLACE_WITH_YOUR_SSH_PUBLIC_KEY` with your public key, or leave it as-is; `start.sh` will inject `~/.ssh/id_rsa.pub` if that file exists.

---

## Step 4: Start the Lab

From the **project directory** (where `start.sh` and `user-data.yaml` live):

```bash
./start.sh
```

Or with full path:

```bash
/path/to/secure_headless_lab/start.sh
```

**What happens:**

1. Checks that the dashboard is not already running (if it is, run `./stop.sh` first).
2. Launches the VM with cloud-init (can take a few minutes).
3. Waits for the VM to get an IP and for cloud-init to finish.
4. Verifies Nginx, UFW, and the `sysadmin` user.
5. Writes real metrics to `status.json`.
6. Starts the dashboard on port 5000.

When it finishes you’ll see something like:

`[SUCCESS] VM ready (real). IP: 10.x.x.x Nginx: true UFW: true SSH user: true`

---

## Step 5: Use the Dashboard and Nginx (including from Windows)

- **Dashboard (metrics):**  
  In your browser open: **http://localhost:5000**

- **VM’s Nginx page from Windows:**  
  The VM IP (e.g. `10.208.78.124`) is only reachable from inside WSL2, so from a **Windows** browser use the proxy instead:  
  **http://localhost:5000/nginx**

From WSL2 you can also use:

```bash
curl http://<VM_IP>
```

(Use the VM IP shown on the dashboard or in `status.json`.)

---

## Step 6: Stop the Lab

From the project directory:

```bash
./stop.sh
```

This:

- Stops the dashboard process.
- Deletes the Multipass VM and purges it.
- Removes `status.json`.

---

## Step 7: Run Tests (optional)

With the lab **running** (VM + dashboard):

```bash
./run_tests.sh
```

Tests check:

- Required files exist.
- Dashboard API responds and returns expected metrics (e.g. `vm_ip`, `nginx_ok`, `ufw_ok`, `ssh_ok`).
- Only one dashboard process is running.

---

## Project Files (reference)

| File or folder | Purpose |
|----------------|---------|
| `start.sh` | Start VM, run checks, write `status.json`, start dashboard |
| `stop.sh` | Stop dashboard and delete VM |
| `user-data.yaml` | Cloud-init: packages (nginx, ufw), sysadmin user, SSH key placeholder |
| `dashboard.py` | Flask app: metrics API and `/nginx` proxy |
| `templates/index.html` | Dashboard UI |
| `requirements.txt` | Python deps (Flask) |
| `run_tests.sh` | Check files, API, and dashboard process count |
| `cleanup.sh` | Stop dashboard and Docker; remove unused containers, images, volumes, networks |
| `fix-multipass-wsl2.sh` | One-time fix for Multipass cert error on WSL2 |
| `status.json` | Written by `start.sh`; real VM metrics (do not edit) |
| `venv/` | Python virtualenv (created by `start.sh` if missing) |
| `.pids/` | Dashboard PID file (runtime) |

---

## Troubleshooting

### "This site can’t be reached" / ERR_CONNECTION_TIMED_OUT for http://&lt;VM IP&gt;

- The VM IP is only valid **inside WSL2**. From a **Windows** browser, use **http://localhost:5000/nginx** instead of `http://<VM_IP>`.

### "multipass is required"

- Install Multipass: `sudo snap install multipass --classic`, then run `./start.sh` again.

### "jq is required"

- Install jq: `sudo apt-get install -y jq`.

### "Dashboard already running"

- Run `./stop.sh` first, then `./start.sh`. Or stop only the dashboard (e.g. kill the process in `.pids/dashboard.pid`) if you want to keep the VM.

### "VM already exists. Use stop.sh first."

- Run `./stop.sh` to delete the existing VM, then `./start.sh`.

### Multipass cert error (multipass_root_cert.pem)

- Run: `sudo ./fix-multipass-wsl2.sh`, then try `multipass list` and `./start.sh` again.

### Restart only the dashboard (keep VM)

```bash
# Stop dashboard process(es)
pkill -f "dashboard.py"

# From project directory, start dashboard again
. venv/bin/activate && PORT=5000 python3 dashboard.py &
echo $! > .pids/dashboard.pid
```

Then use **http://localhost:5000** and **http://localhost:5000/nginx** as above.

---

## Quick Reference

| Action | Command |
|--------|--------|
| Start lab (VM + dashboard) | `./start.sh` |
| Stop lab (VM + dashboard) | `./stop.sh` |
| Cleanup (dashboard + Docker) | `./cleanup.sh` |
| Run tests | `./run_tests.sh` |
| Fix Multipass on WSL2 | `sudo ./fix-multipass-wsl2.sh` |
| Dashboard | http://localhost:5000 |
| Nginx from Windows | http://localhost:5000/nginx |

All commands are intended to be run from the **project directory** (`secure_headless_lab`).
