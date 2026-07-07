#requires AutoHotkey v2.0
#SingleInstance Force

CooldownMs     := 180000
HoldE_Duration := 2000
ClickCount     := 3
ClickGap       := 1500

running := false

F1:: {
    global running
    running := !running
    if running {
        ToolTip("sageSanity: RUNNING`nF1 to stop")
        SetTimer(() => ToolTip(), -1500)
        DrinkCoffee()
    } else {
        SetTimer(DrinkCoffee, 0)
        SetTimer(CooldownTick, 0)
        ToolTip("sageSanity: STOPPED")
        SetTimer(() => ToolTip(), -1500)
    }
}

DrinkCoffee() {
    global running
    if !running
        return
    Send("{e down}")
    Sleep(HoldE_Duration)
    Send("{e up}")
    Loop ClickCount {
        Click()
        Sleep(ClickGap)
    }
    SetTimer(CooldownTick, 1000)
    SetTimer(DrinkCoffee, -CooldownMs)
}

tickCount := 0
CooldownTick() {
    global tickCount, running
    if !running {
        SetTimer(CooldownTick, 0)
        ToolTip()
        return
    }
    tickCount++
    secsLeft := Round((CooldownMs / 1000) - tickCount)
    if secsLeft <= 0 {
        tickCount := 0
        SetTimer(CooldownTick, 0)
        ToolTip()
    } else {
        ToolTip("sageSanity: next drink in " secsLeft "s")
    }
}
