# Hermes-Manager
An interactive TUI manager for [Hermes] (https://github.com/nousresearch/hermes-agent) — built with `whiptail`, zero dependencies beyond what ships with Debian/Ubuntu.

Stop copy-pasting commands. Navigate everything from one clean menu.

---

## Features

- **Dynamic profile discovery** — scans `~/.hermes/profiles/` at every startup, no hardcoded names
- **Per-profile panel** — edit, backup, remove and manage `SOUL.md`, `config.yaml`, `.env` for each profile
- **SOUL.md import** — copy a SOUL.md from one profile to another in two keystrokes
- **Gateway control** — status / restart / stop per profile, or blast all of them at once
- **Quick profile switcher** — activate any profile from the main menu instantly
- **General Hermes commands** — setup wizard, model/provider, config view/edit, key-value setter
- **Self-install prompt** — on first run, offers to copy itself to `/usr/local/bin/hermes-manager`
- **Re-scan option** — refresh the profile list at any time without restarting the script

---

## Requirements

- Bash 4+
- `whiptail` (ships with most Debian/Ubuntu installs, otherwise: `sudo apt install whiptail`)
- [Hermes] (https://github.com/nousresearch/hermes-agent) installed and configured for the current user

---

## Installation

### Option A — let the script install itself

```bash
chmod +x hermes-manager.sh
./hermes-manager.sh
```

On first run it will detect it's not in your `PATH` and offer to install itself to `/usr/local/bin/hermes-manager`. Accept and you're done.

### Option B — manual

```bash
chmod +x hermes-manager.sh
sudo cp hermes-manager.sh /usr/local/bin/hermes-manager
```

Then just run:

```bash
hermes-manager
```

---

## Menu structure

```
⚡ Hermes Manager
│
├── 👤  Profiles
│   ├── [dynamically lists all discovered profiles]
│   ├── 🔍  Re-scan profiles
│   │
│   └── Per-profile panel
│       ├── 📝  EDIT
│       │   ├── SOUL.md
│       │   ├── config.yaml
│       │   └── .env
│       ├── 💾  BACKUP
│       │   ├── config.yaml  (custom filename, date-stamped default)
│       │   └── SOUL.md      (custom filename, date-stamped default)
│       ├── 🗑️   REMOVE
│       │   ├── SOUL.md      (irreversible — double confirmation)
│       │   ├── config.yaml  (irreversible — double confirmation)
│       │   └── .env         (irreversible — double confirmation)
│       ├── 📥  Import SOUL.md from another profile
│       ├── ▶️   Gateway status
│       ├── 🔁  Gateway restart
│       ├── ⏹️   Gateway stop
│       ├── 🔀  Activate this profile
│       └── ℹ️   Show paths
│
├── 🩺  Hermes Doctor
├── 🔄  Hermes Update
│
├── 🌐  Gateway — Stop / Restart ALL
│   ├── ⏹️  Stop ALL profiles
│   └── 🔁  Restart ALL profiles
│
├── ⚙️   Hermes General Commands
│   ├── Start chat
│   ├── Start gateway
│   ├── Setup wizard (full / model / terminal / gateway / tools)
│   ├── View / edit config
│   └── Set config key/value
│
└── 🔀  Quick Profile Switcher
```

---

## How profile discovery works

On every startup, `hermes-manager` scans `~/.hermes/profiles/` for subdirectories and builds the profile list dynamically. The `default` profile (rooted at `~/.hermes/`) is always prepended.

If you add or remove a Hermes profile while the script is running, use the **Re-scan profiles** option inside the Profiles menu to refresh the list without restarting.

The Gateway ALL commands automatically apply to every discovered profile — no manual editing needed when you add new ones.

---

## File locations per profile

| File | Default profile | Named profile |
|---|---|---|
| `config.yaml` | `~/.hermes/config.yaml` | `~/.hermes/profiles/<name>/config.yaml` |
| `.env` | `~/.hermes/.env` | `~/.hermes/profiles/<name>/.env` |
| `SOUL.md` | `~/.hermes/SOUL.md` | `~/.hermes/profiles/<name>/SOUL.md` |
| Sessions | `~/.hermes/sessions/` | `~/.hermes/profiles/<name>/sessions/` |
| Logs | `~/.hermes/logs/` | `~/.hermes/profiles/<name>/logs/` |
| Cron | `~/.hermes/cron/` | `~/.hermes/profiles/<name>/cron/` |

Backups are saved **in the same directory as the source file**, with a date-stamped default name (`SOUL_profilename_YYYYMMDD.md`) that you can override at save time.

---

## Notes

- The script uses `nano` as the default editor for all file editing. If you prefer a different editor, change the `nano` calls in the `menu_edit_profile` function.
- REMOVE operations require explicit confirmation and display a warning before deleting. There is no undo — always backup first.
- The SOUL.md import overwrites the destination file. A confirmation dialog is shown before proceeding.

---

## License

GNU GPLv3

---

*Made by [drag0n](github.com/EmEmArBee/)
