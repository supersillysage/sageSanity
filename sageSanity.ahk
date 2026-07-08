#Requires AutoHotkey v2.0
#SingleInstance Force

configFile := A_ScriptDir "\config.ini"

Machine := IniRead(configFile, "Settings", "Machine", "Main")
CooldownMs := Number(IniRead(configFile, "Settings", "Cooldown", 180000))
HoldE_Duration := Number(IniRead(configFile, "Settings", "HoldDuration", 2000))
ClickCount := Number(IniRead(configFile, "Settings", "Clicks", 3))
ClickGap := Number(IniRead(configFile, "Settings", "ClickGap", 1500))

myGui := Gui()
myGui.Title := "sageSanity"

statusText := myGui.AddText("w200", "Status: STOPPED")

machineText := myGui.AddText("w200", "Machine:")
machineBox := myGui.AddDropDownList("w200", ["Main", "Barney"])
machineBox.OnEvent("Change", ChangeMachine)

startButton := myGui.AddButton("w90", "Start")
stopButton := myGui.AddButton("w90 x+10", "Stop")

startButton.OnEvent("Click", (*) => StartMacro())
stopButton.OnEvent("Click", (*) => StopMacro())

myGui.Show()

running := false

F1:: {
    global running
    if running
        StopMacro()
    else
        StartMacro()
}

StartMacro() {
    global running, statusText
    WinActivate("ahk_exe RobloxPlayerBeta.exe")
	Sleep(500)
	MouseGetPos(&oldX, &oldY)
	MouseMove(A_ScreenWidth - 50, A_ScreenHeight - 50, 0)
	Click()
	MouseMove(oldX, oldY, 0)
	Sleep(200)
    running := true
    statusText.Text := "Status: RUNNING"
    ToolTip("sageSanity: RUNNING`nF1 to stop")
    SetTimer(() => ToolTip(), -1500)
    DrinkCoffee()
}

StopMacro() {
    global running, statusText
    running := false
    statusText.Text := "Status: STOPPED"
    SetTimer(DrinkCoffee, 0)
    SetTimer(CooldownTick, 0)
    ToolTip("sageSanity: STOPPED")
    SetTimer(() => ToolTip(), -1500)
}

ChangeMachine(*) {
    global Machine, CooldownMs, machineBox, configFile

    Machine := machineBox.Text

    if Machine = "Main"
        CooldownMs := 180000
    else if Machine = "Barney"
        CooldownMs := 300000

    IniWrite(Machine, configFile, "Settings", "Machine")
    IniWrite(CooldownMs, configFile, "Settings", "Cooldown")
}

DrinkCoffee() {
    global running, HoldE_Duration, ClickCount, ClickGap, CooldownMs
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
    global tickCount, running, CooldownMs
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