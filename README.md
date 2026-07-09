# sageSanity

auto sanity manager for **animal hospital** on roblox. automatically drinks coffee based on the selected machine cooldown so you never lose your sanity while sleepin

---

## requirements

- windows 10 or 11
- [autohotkey v2](https://www.autohotkey.com) , make sure you download **v2**, not v1.1

---

## features

- automatic coffee drinking while afk
- gui control panel
- configurable settings
- multiple coffee machine support
- cooldown countdown display

---

## installation

1. install autohotkey v2 from [autohotkey.com](https://www.autohotkey.com)
2. download the latest release from the releases page
3. make sure `config.ini` is in the same folder as `sageSanity.ahk`
4. right-click `sageSanity.ahk` → **run script**

---

## usage

| key | action |
|-----|--------|
| `F1` | toggle macro on/off |
| `F2` | toggle always-on-top |

- press **F1** to start, the macro will drink coffee immediately, then every selected machine cooldown automatically
- a countdown tooltip shows how long until the next drink
- press **F1** again to stop at any time
- you can also use the gui **start** and **stop** buttons

---

## gui

the gui allows you to:
- start and stop the macro
- select your coffee machine
- edit cooldown, hold duration, click count, and click gap live
- see runtime, drink count, and time until next drink
- minimize to tray and control the macro from the tray menu (open/start/stop/exit)

---

## configuration

settings can be customized through `config.ini`

example:

```ini
[Settings]
Machine=Main
Cooldown=180000
HoldDuration=2000
Clicks=3
ClickGap=1500
````

---

## how it works

when toggled on, sageSanity holds **E** for a set duration (default 2 seconds) to interact with the coffee machine, then clicks a set number of times (default 3) to drink. these values, along with the cooldown, can be changed in the gui or config.ini. it waits for the selected machine cooldown to expire, then repeats forever.

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
