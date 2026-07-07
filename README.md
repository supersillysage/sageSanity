# sageSanity v1

Auto sanity manager for **Animal Hospital** on Roblox. Automatically drinks coffee every 3 minutes so you never lose your sanity while grinding.

---

## Requirements

- Windows 10 or 11
- [AutoHotkey v2](https://www.autohotkey.com) — make sure you download **v2**, not v1

---

## Installation

1. Install AutoHotkey v2 from [autohotkey.com](https://www.autohotkey.com)
2. Download `sageSanity.ahk` from this repo
3. Right-click `sageSanity.ahk` → **Run with AutoHotkey**

---

## Usage

| Key | Action |
|-----|--------|
| `F1` | Toggle macro on/off |

- Press **F1** to start — the macro will drink coffee immediately, then every 180 seconds automatically
- A countdown tooltip shows how long until the next drink
- Press **F1** again to stop at any time

---

## How it works

When toggled on, sageSanity holds **E** for 2 seconds (interact with coffee machine), then clicks 3 times to drink. It waits 180 seconds for the machine cooldown to expire, then repeats forever.

No screen reading, no image detection — just a timer.

---

## Notes

- Make sure you're near the coffee machine when you start the macro, or reposition yourself before each drink cycle
- The macro does not move your character — you need to already be in range of the machine
- Works while the game window is in the background as long as Roblox is running

---

## Credits

Built by **Sage** — inspired by [dolphSol-Macro](https://github.com/BuilderDolphin/dolphSol-Macro) by BuilderDolphin.
