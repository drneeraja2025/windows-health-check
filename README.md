# Windows Health Check

Automated **SFC** and **DISM** maintenance for Windows laptops. One-time setup registers scheduled tasks; logs are stored per-machine outside the repo.

Works on any Windows 10/11 laptop after a clone — no hardcoded user paths.

## What it does

| Task | Schedule | Command |
|------|----------|---------|
| **WinHealth-SFC-Weekly** | Sundays 3:00 AM | `sfc /scannow` (~10–20 min) |
| **WinHealth-Full-Monthly** | 1st of month 3:30 AM | DISM + SFC (~30–90 min) |

Logs: `%LOCALAPPDATA%\WindowsHealthCheck\logs\`

## Quick start

### 1. Clone to a permanent location

Pick a folder you won't move or delete — scheduled tasks point to this path.

```powershell
git clone https://github.com/drneeraja2025/windows-health-check.git C:\Tools\windows-health-check
cd C:\Tools\windows-health-check
```

### 2. Run setup (Administrator)

Right-click **`Run-Setup-As-Admin.bat`** → **Run as administrator** → click **Yes** on UAC.

Setup will:
- Register weekly and monthly scheduled tasks
- Run SFC immediately (~10–20 min)

### 3. Optional — run SFC anytime

Double-click **`Run-SFC-Now.bat`** (auto-prompts for admin).

## File layout

```
windows-health-check/
├── Run-Setup-As-Admin.bat    # One-time setup + first SFC scan
├── Run-SFC-Now.bat           # Manual SFC anytime
├── run-sfc-task.bat            # Used by weekly scheduled task
├── run-full-repair-task.bat    # Used by monthly scheduled task
└── scripts/
    ├── _config.ps1             # Paths (repo root + log dir)
    ├── setup-schedule.ps1        # Registers tasks
    ├── run-sfc.ps1
    └── run-full-repair.ps1
```

## Logs

| File | Meaning |
|------|---------|
| `setup-log.txt` | Setup run history |
| `last-sfc.txt` | Last SFC result |
| `last-full-repair.txt` | Last DISM+SFC result |
| `sfc-YYYY-MM-DD-HHmm.log` | Full SFC output |
| `tasks-status.txt` | Scheduled task details |

## Requirements

- Windows 10 or 11
- Administrator rights for setup and scans
- Laptop **plugged in** for scheduled runs (tasks skip on battery)

## Uninstall

```powershell
schtasks /Delete /TN WinHealth-SFC-Weekly /F
schtasks /Delete /TN WinHealth-Full-Monthly /F
```

Then delete the clone folder and optionally `%LOCALAPPDATA%\WindowsHealthCheck\logs`.

## Notes

- **SFC** checks system file integrity; **DISM** repairs the Windows component store.
- Keep the repo in the same path after setup — moving it breaks scheduled tasks until you re-run setup.
- Safe to run on a fresh install or any stable system as preventive maintenance.

## License

MIT
