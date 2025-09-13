# macOS Maintenance Kit

This kit gives you a safe, one-click **mac maintenance** you can run manually or on a schedule.

## What it does (by default)

1. **Quits open apps** gracefully (prompts if not `--auto`).
2. **Checks macOS updates** (opens Software Update pane if you're running it interactively).
3. **Updates Mac App Store apps** (via `mas` if available; otherwise opens the App Store Updates page).
4. **Updates Homebrew**: `brew update`, `brew upgrade` (formulae), optional `--cask --greedy`, `brew autoremove`, `brew cleanup -s`.
5. **Nudges Setapp** (opens Setapp if installed to let it refresh updates).
6. Logs everything to `~/Library/Logs/mac_maintenance.log`.

> Backups are intentionally **ignored** as requested.

---

## Files

- `maintenance.sh` – the zsh script.
- `com.user.mac.maintenance.plist` – sample **LaunchAgent** to schedule daily at 03:00.
- This README.

---

## Quick start (manual use)

1. Move the script somewhere in your home folder, e.g.:

   ```bash
   mkdir -p ~/Scripts
   mv maintenance.sh ~/Scripts/
   chmod +x ~/Scripts/maintenance.sh
   ```

2. Run it:

   ```bash
   ~/Scripts/maintenance.sh
   ```

   - It will show a confirmation before quitting apps.
   - A log file is written to `~/Library/Logs/mac_maintenance.log`.

3. Non-interactive mode (good for scheduling):

   ```bash
   ~/Scripts/maintenance.sh --auto
   ```

---

## Optional: install helpers

- **mas** (Mac App Store CLI) to auto-update App Store apps:

  ```bash
  brew install mas
  ```

- **Homebrew** (if you don't already have it): <https://brew.sh>

---

## Tuning the steps

Use flags to skip parts:

```bash
~/Scripts/maintenance.sh --no-quit --no-os --no-appstore --no-brew --no-casks --no-clean
```

- `--no-quit` — don't quit apps
- `--no-os` — skip macOS update check
- `--no-appstore` — skip App Store updates
- `--no-brew` — skip Homebrew
- `--no-casks` — don't run `brew upgrade --cask --greedy`
- `--no-clean` — skip `brew autoremove` and `brew cleanup -s`

---

## Scheduling with launchd (recommended on macOS)

1. Put the script at `~/Scripts/maintenance.sh` and make it executable.
2. Place the **plist** file into `~/Library/LaunchAgents/`:

   ```bash
   mkdir -p ~/Library/LaunchAgents
   mv com.user.mac.maintenance.plist ~/Library/LaunchAgents/
   ```

3. Load it:

   ```bash
   launchctl load ~/Library/LaunchAgents/com.user.mac.maintenance.plist
   ```

4. (Optional) Test immediately:

   ```bash
   launchctl start com.user.mac.maintenance
   ```

5. To unload/disable later:

   ```bash
   launchctl unload ~/Library/LaunchAgents/com.user.mac.maintenance.plist
   ```

**Customization**: Open the plist to adjust the time inside `StartCalendarInterval`.  
The plist runs: `zsh -lc "$HOME/Scripts/maintenance.sh --auto"` so `$HOME` expands correctly.

---

## Scheduling with Shortcuts (no plist needed)

1. Open **Shortcuts** → **New Shortcut**.
2. Add actions in this order:
   - **Run AppleScript** → `quit apps` (optional if you use the script's own quitting step).
   - **Run Shell Script** → `/bin/zsh` and command: `~/Scripts/maintenance.sh --auto`
3. In Shortcuts, create a **Personal Automation** → **Time of Day** → choose your schedule → **Run Shortcut**.

This approach gives you a quick on-demand button in the menu bar or Spotlight as well.

---

## Safety notes

- The script **does not force-quit** apps. If you have unsaved work, apps may prompt; in `--auto` mode macOS handles these prompts silently (apps may remain open).
- `softwareupdate` is **check-only**. Installing OS updates may reboot; do that manually when convenient.
- `brew upgrade --cask --greedy` updates even auto-updating apps (e.g., Chrome). If you want to skip those, add `--no-casks` or remove that line.

---

## Logs

All runs append to: `~/Library/Logs/mac_maintenance.log`  
The LaunchAgent also captures stdout/stderr to:

- `~/Library/Logs/mac_maintenance.launchd.out`
- `~/Library/Logs/mac_maintenance.launchd.err`

---

## Last built

2025-09-10T09:43:50.266532
