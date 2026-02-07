# Day 2: Home Lab Hardware Selection Assistant (AI Gold Rush Edition)

## About This Project

This application is a **Bash script** that helps you plan and document the hardware for a **secure headless home lab**. It guides you through selecting components (CPU, motherboard, RAM, storage, network, PSU, case, and BMC/IPMI) and records your choices and justifications in a Markdown inventory. It is designed to leverage hardware insights from the "AI Gold Rush" surplus market (used enterprise and data-center hardware suitable for home labs).

**What it does:**

- Creates a planning directory and a hardware inventory document.
- Collects your component selections and justifications (interactively or with sensible defaults).
- Optionally installs the `lshw` tool on your system so you can verify hardware once the lab is built.
- Produces a single, editable document you can share or refine as your plan evolves.

---

## Features

| Feature | Description |
|--------|-------------|
| **Interactive or non-interactive** | Run in a terminal to type your choices, or run without a TTY (e.g. CI/automation) and use built-in defaults. |
| **Markdown inventory** | Output is `home_lab_planning/hardware_inventory.md` — easy to read, version-control, and edit. |
| **Optional lshw install** | Script can install `lshw` (Linux hardware lister) via `apt` or `yum`; records success or skip in a status file. |
| **Optional sudo password** | For non-interactive runs where sudo requires a password, you can set `SUDO_PASSWORD` so the script can install `lshw` (see Implementation Guide). |
| **Docker-friendly** | When run inside a container, it prints the inventory to stdout and suggests `docker cp` to retrieve the file. |

---

## Prerequisites

- **Bash** (script uses `set -euo pipefail` and modern Bash features).
- **Linux** with either:
  - **apt** (Debian/Ubuntu) or **yum** (RHEL/CentOS) if you want automatic `lshw` installation.
- **sudo** (optional) — required only if you want the script to install `lshw`; otherwise the script skips install and continues.

---

## Implementation Guide (Step by Step)

### Step 1: Clone or Navigate to the Project

Ensure you have the `day2` project on your machine (e.g. part of the `Linux-Server-Administration` repo). Open a terminal and go to the `day2` directory:

```bash
cd /path/to/Linux-Server-Administration/day2
```

Replace `/path/to/` with your actual path (e.g. `/home/systemdr/git/Linux-Server-Administration/day2`).

---

### Step 2: Make the Script Executable (Optional)

You can run the script with `bash setup.sh`; making it executable is optional:

```bash
chmod +x setup.sh
```

Then you can run `./setup.sh` instead of `bash setup.sh`.

---

### Step 3: Run the Script

**Option A — Interactive (recommended for first run)**  
Run from the `day2` directory. The script will prompt you for each component and a short justification:

```bash
cd /path/to/day2
bash setup.sh
```

You will see prompts like:

- `Enter your chosen CPU (e.g., Intel Xeon E5-2690v4):`
- `Justify your CPU choice: Why this CPU? ...`

Press Enter to accept the suggested value, or type your own.

**Option B — Non-interactive (defaults only)**  
When stdin is not a terminal (e.g. piping, cron, or some IDEs), the script does not prompt; it uses built-in default components and a generic justification for each. Example:

```bash
cd /path/to/day2
bash setup.sh
```

**Option C — With sudo password (for lshw install)**  
If the script cannot run `sudo` without a password (e.g. in automation), you can pass the password via an environment variable. **Do not commit this or share it.** Example:

```bash
cd /path/to/day2
SUDO_PASSWORD=your_sudo_password bash setup.sh
```

The script uses `SUDO_PASSWORD` only to run `apt`/`yum` for installing `lshw`; it is not stored in any file.

---

### Step 4: Understand What the Script Does (Internal Steps)

When you run `setup.sh`, it performs these steps in order:

1. **Set strict mode**  
   `set -euo pipefail` — exit on error, treat unset variables as errors, and use pipe failure propagation.

2. **Define paths**  
   - `LAB_DIR="home_lab_planning"` — directory for all output.  
   - `INVENTORY_FILE="$LAB_DIR/hardware_inventory.md"` — main inventory.  
   - `LSHW_INSTALL_FILE="$LAB_DIR/lshw_install_status.txt"` — lshw install result.

3. **Create directory**  
   `mkdir -p "$LAB_DIR"` — creates `home_lab_planning` if it does not exist.

4. **Initialize inventory**  
   Writes the top of `hardware_inventory.md`: title, short intro, and a "Selected Components" section.

5. **Collect component data**  
   For each of CPU, Motherboard, RAM, Storage (OS/Apps), Storage (Bulk Data), Network Card, PSU, Case, and BMC/IPMI:
   - If stdin is a TTY: prompt for selection and justification (with defaults).
   - If not: use default selection and a default justification.
   - Append a `### Component` block to `hardware_inventory.md` with **Selection** and **Justification**.

6. **Append “Next Steps & Tools”**  
   Adds a section recommending `lshw` and an example install command to the inventory file.

7. **Try to install lshw**  
   - If `apt` is available: run `apt update` and `apt install -y lshw` (using `sudo -n` or, if set, `SUDO_PASSWORD` with `sudo -S`).  
   - Else if `yum` is available: same idea with `yum install -y lshw`.  
   - Writes `lshw installation: SUCCESS` or a `SKIPPED` message to `lshw_install_status.txt`.  
   - If sudo fails or is unavailable, the script does not exit; it records SKIPPED and continues.

8. **Print completion message**  
   Tells you where the inventory is and how to view it (`cat home_lab_planning/hardware_inventory.md`).

9. **Docker behavior**  
   If `DOCKER_CONTAINER_ID` is set or `/.dockerenv` exists, the script also prints the full inventory to stdout and suggests using `docker cp` to copy the file out of the container.

---

### Step 5: Check the Output

After a successful run you should see:

**Console:**

- Banner: `Home Lab Hardware Selection Assistant (AI Gold Rush Edition)`
- Messages about creating `home_lab_planning` and initializing `hardware_inventory.md`
- Either prompts (interactive) or no prompts (non-interactive)
- Message about attempting to install `lshw`
- `Hardware Inventory Complete!` and the path to the inventory file

**Files:**

| File | Purpose |
|------|--------|
| `home_lab_planning/hardware_inventory.md` | Your chosen components and justifications in Markdown, plus “Next Steps & Tools”. |
| `home_lab_planning/lshw_install_status.txt` | One line: `lshw installation: SUCCESS` or a SKIPPED message. |

View the inventory:

```bash
cat home_lab_planning/hardware_inventory.md
```

---

### Step 6: Edit the Inventory (Optional)

You can edit `hardware_inventory.md` in any text editor: change selections, fix typos, or add more sections. The script only creates/overwrites the file on run; it does not merge. So re-running `setup.sh` will overwrite the inventory with a fresh one based on prompts or defaults.

---

### Step 7: Verify lshw (Optional)

If `lshw_install_status.txt` says `SUCCESS`, you can list hardware with:

```bash
sudo lshw -short
```

Or a full tree:

```bash
sudo lshw
```

This is useful later when your lab hardware is assembled, to confirm what is installed.

---

## Project Layout

```
day2/
├── README.md                 # This file
├── setup.sh                  # Main application script
└── home_lab_planning/        # Created by setup.sh
    ├── hardware_inventory.md # Component selections and justifications
    └── lshw_install_status.txt # lshw install result (SUCCESS or SKIPPED)
```

---

## Security Notes

- **Do not** put real passwords in scripts or in files that are committed to git.
- **Do not** share `SUDO_PASSWORD` in chat or logs; use it only when you run the script locally.
- For automation, consider configuring passwordless sudo only for the specific commands needed (e.g. in `/etc/sudoers.d/`) instead of passing a password.

---

## Quick Reference

| Goal | Command |
|------|--------|
| Run interactively (prompts) | `cd day2 && bash setup.sh` |
| Run with defaults (no prompts) | Same, when stdin is not a TTY. |
| Run and allow lshw install via sudo | `SUDO_PASSWORD=yourpass bash setup.sh` (use only locally, never commit). |
| View inventory | `cat home_lab_planning/hardware_inventory.md` |
| Check lshw status | `cat home_lab_planning/lshw_install_status.txt` |

---

## Summary

This application is a single Bash script (`setup.sh`) that produces a documented hardware plan for a headless home lab. The implementation consists of: (1) navigating to `day2`, (2) running `setup.sh` interactively or non-interactively, (3) optionally providing `SUDO_PASSWORD` for lshw install, and (4) reading or editing `home_lab_planning/hardware_inventory.md` and checking `home_lab_planning/lshw_install_status.txt`. Every step above is explained so you can run and adapt the script to your environment.
