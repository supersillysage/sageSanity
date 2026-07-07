# sageSanity v1

auto sanity manager for **animal hospital** on roblox. automatically drinks coffee every 3 minutes (aka cooldown time) so you never lose your sanity while sleepin

---

## requirements

- windows 10 or 11
- [autohotkey v2](https://www.autohotkey.com) , make sure you download **v2**, not v1.1

---

## installation

1. install autohotkey v2 from [autohotkey.com](https://www.autohotkey.com)
2. download `sageSanity.ahk` from this repo
3. right-click `sageSanity.ahk` → **run script**

---

## usage

| key | action |
|-----|--------|
| `F1` | toggle macro on/off |

- press **F1** to start, the macro will drink coffee immediately, then every 180 seconds (cooldown time) automatically
- a countdown tooltip shows how long until the next drink
- press **F1** again to stop at any time

---

## how it works

when toggled on, sageSanity holds **E** for 2 seconds (interact with coffee machine), then clicks 3 times to drink. it waits 180 seconds for the machine cooldown to expire, then repeats forever.

<img width="500" alt="sageSanity quick preview" src="./preview.gif">


---

## notes

- make sure you're on top of the coffee machine when you start the macro, or reposition yourself before each drink cycle
- the macro does not move your character, you need to already be in range of the machine
- works while the game window is in the background as long as roblox is running

---

## credits

built by **sage,** inspired by [dolphSol-Macro](https://github.com/BuilderDolphin/dolphSol-Macro) by BuilderDolphin

sweet dreams :3
