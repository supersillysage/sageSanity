# sageSanity
auto sanity manager for **animal hospital** on roblox. automatically drinks coffee based on the selected machine cooldown so you never lose your sanity while sleepin

---

## requirements
- windows 10 or 11
- [autohotkey v2](https://www.autohotkey.com) , make sure you download **v2**, not v1.1

---

## features
- automatic coffee drinking while afk
- tabbed gui control panel (main, presets, settings, credits, about)
- save, load, rename, and delete your own machine presets
- remappable hotkeys
- reset to default button
- update checker
- friendly error handling with crash logs

---

## installation
1. install autohotkey v2 from [autohotkey.com](https://www.autohotkey.com)
2. download the latest release from the releases page
3. make sure `config.ini` is in the same folder as `sageSanity.ahk`
4. make sure the `assets` folder (with the profile pictures and github logo) is in the same folder as `sageSanity.ahk`, without it, the credits/about tabs will just skip the images
5. right-click `sageSanity.ahk` → **run script**

---

## usage
| key | action |
|-----|--------|
| `F1` (default) | toggle macro on/off |
| `F2` (default) | toggle always-on-top |

- press the toggle hotkey to start, the macro will drink coffee immediately, then every selected preset's cooldown automatically
- a countdown tooltip shows how long until the next drink
- press the toggle hotkey again to stop at any time
- you can also use the gui **start** and **stop** buttons
- both hotkeys can be remapped from the **settings** tab

---

## gui
sageSanity's gui is split into 5 tabs:

**main:** start/stop the macro, quick-switch presets, and view live status (drinks, runtime, next drink countdown)

**presets:** save, load, rename, and delete your own named presets (cooldown, hold duration, clicks, click gap all included per preset)

**settings:** edit the active preset's values, remap hotkeys, and reset to sageSanity's original defaults

**credits:** the people behind this project

**about:** current version, check for updates, discord, and a link to the github repo

---

## configuration
settings live in `config.ini`, organized by preset. each preset is its own section:
```ini
[State]
ActivePreset=Main
ToggleHotkey=F1
TopHotkey=F2

[Preset:Main]
Cooldown=180000
HoldDuration=2000
Clicks=3
ClickGap=1500

[Preset:Barney]
Cooldown=300000
HoldDuration=2000
Clicks=3
ClickGap=1500
```
> ⚠️ only edit `config.ini` directly if you know what you're doing!! `ActivePreset` must match an existing `[Preset:Name]` section exactly, and hotkey values need to be valid AutoHotkey hotkey syntax (e.g. `F1`, `^F2`, `#q`). it's usually safer to change these from the gui instead.

---

## updates & crash logs
- check for a newer release anytime from the **about** tab
- if sageSanity runs into an unexpected error, it'll show a message instead of crashing silently, and save details to a numbered `sageSanity-crashlog-N.log` file next to the script
- normal activity (start/stop times) is logged to `sageSanity.log`

---

## how it works
when toggled on, sageSanity holds **E** for a set duration (default 2 seconds) to interact with the coffee machine, then clicks a set number of times (default 3) to drink. these values, along with the cooldown, are per-preset and can be changed in the gui or config.ini. it waits for the active preset's cooldown to expire, then repeats forever.

<img width="500" alt="RobloxPlayerBeta_Cd7HhUpb1Q" src="https://github.com/user-attachments/assets/5aa759ec-23d7-4d8c-afe2-ded42aaff85c" />

---

## notes
- make sure you're on top of the coffee machine when you start the macro, or reposition yourself before each drink cycle
- the macro does not move your character, you need to already be in range of the machine
- roblox must already be open before starting the macro

---

## known limitations
- the macro does not detect player position
- you must already be within range of the coffee machine
- the macro cannot tell if another ui is blocking interaction

---

## credits
built by **sage,** inspired by [dolphSol-Macro](https://github.com/BuilderDolphin/dolphSol-Macro) by BuilderDolphin

sweet dreams :3
