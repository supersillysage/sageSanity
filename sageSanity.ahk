#Requires AutoHotkey v2.0
#SingleInstance Force

configFile := A_ScriptDir "\config.ini"
if !FileExist(configFile) {
    CreateConfig()
}

Machine := IniRead(configFile, "Settings", "Machine", "Main")
CooldownMs := Number(IniRead(configFile, "Settings", "Cooldown", 180000))
HoldE_Duration := Number(IniRead(configFile, "Settings", "HoldDuration", 2000))
ClickCount := Number(IniRead(configFile, "Settings", "Clicks", 3))
ClickGap := Number(IniRead(configFile, "Settings", "ClickGap", 1500))

myGui := Gui()
myGui.Title := "sageSanity"

statusText := myGui.AddText("w200", "Status: STOPPED")
machineStatus := myGui.AddText("w200", "Machine: " Machine)
timerStatus := myGui.AddText("w200", "Next Drink: Ready")
drinkStatus := myGui.AddText("w200", "Drinks: 0")
runtimeText := myGui.AddText("w200", "Runtime: 00:00:00")

myGui.AddText("w200", "Machine:")
machineBox := myGui.AddDropDownList("w200", ["Main", "Barney"])
machineBox.OnEvent("Change", ChangeMachine)

myGui.AddText("w200", "Cooldown:")
cooldownInput := myGui.AddEdit("w200", CooldownMs)

myGui.AddText("w200", "Hold Duration:")
holdInput := myGui.AddEdit("w200", HoldE_Duration)

myGui.AddText("w200", "Clicks:")
clickInput := myGui.AddEdit("w200", ClickCount)

myGui.AddText("w200", "Click Gap:")
gapInput := myGui.AddEdit("w200", ClickGap)

saveButton := myGui.AddButton("w90", "Save Settings")
saveButton.OnEvent("Click", SaveSettings)

startButton := myGui.AddButton("w90", "Start")
stopButton := myGui.AddButton("w90 x+10", "Stop")

startButton.OnEvent("Click", (*) => StartFromGUI())
stopButton.OnEvent("Click", (*) => StopMacro())

myGui.Show()
myGui.OnEvent("Close", (*) => myGui.Hide())

A_TrayMenu.Delete()
A_TrayMenu.Add("Open", (*) => myGui.Show())
A_TrayMenu.Add("Start", (*) => StartFromGUI())
A_TrayMenu.Add("Stop", (*) => StopMacro())
A_TrayMenu.Add()
A_TrayMenu.Add("Exit", (*) => ExitApp())
A_TrayMenu.Default := "Open"

guiTop         := false
running        := false
forceStop      := false
tickCount      := 0
drinkCount     := 0
clicksDone     := 0
runtimeSeconds := 0

CreateConfig() {
    global configFile
    IniWrite("Main", configFile, "Settings", "Machine")
    IniWrite(180000, configFile, "Settings", "Cooldown")
    IniWrite(2000, configFile, "Settings", "HoldDuration")
    IniWrite(3, configFile, "Settings", "Clicks")
    IniWrite(1500, configFile, "Settings", "ClickGap")
}

F1:: {
    global running
    if running
        StopMacro()
    else
        StartMacro()
}

F2:: {
    global guiTop, myGui
    guiTop := !guiTop
    if guiTop {
        myGui.Show("x" A_ScreenWidth - 300 " y50")
        WinSetAlwaysOnTop(true, "sageSanity")
    } else {
        WinSetAlwaysOnTop(false, "sageSanity")
    }
}

FocusRoblox() {
    if WinActive("ahk_exe RobloxPlayerBeta.exe")
        return
    if WinExist("ahk_exe RobloxPlayerBeta.exe") {
        WinActivate("ahk_exe RobloxPlayerBeta.exe")
        Sleep(1000)
    }
}

StartMacro() {
    global running, forceStop, statusText, machineStatus, runtimeSeconds
    forceStop := false
    running := true
    runtimeSeconds := 0
    statusText.Text := "Status: RUNNING"
    machineStatus.Text := "Machine: " Machine
    ToolTip("sageSanity: RUNNING`nF1 to stop")
    SetTimer(() => ToolTip(), -1500)
    SetTimer(RuntimeTick, 1000)
    FocusRoblox()
    SetTimer(Step_HoldE, -50)
}

StartFromGUI() {
    global running, forceStop, statusText, machineStatus, guiTop, myGui, runtimeSeconds
    forceStop := false
    running := true
    runtimeSeconds := 0
    statusText.Text := "Status: RUNNING"
    machineStatus.Text := "Machine: " Machine
    ToolTip("sageSanity: RUNNING`nF1 to stop")
    SetTimer(() => ToolTip(), -1500)
    SetTimer(RuntimeTick, 1000)

    if !WinActive("ahk_exe RobloxPlayerBeta.exe") {
        myGui.Opt("-AlwaysOnTop")
        WinActivate("ahk_exe RobloxPlayerBeta.exe")
        WinWaitActive("ahk_exe RobloxPlayerBeta.exe", , 2)
        Sleep(300)
        MouseGetPos(&oldX, &oldY)
        MouseMove(50, A_ScreenHeight // 2, 0)
        Sleep(100)
        Click()
        Sleep(200)
        if guiTop
            myGui.Opt("+AlwaysOnTop")
    }

    SetTimer(Step_HoldE, -1000)
}

StopMacro() {
    global running, forceStop, statusText, timerStatus, tickCount, clicksDone, runtimeText

    forceStop := true
    running := false
    clicksDone := 0

    SetTimer(Step_HoldE, 0)
    SetTimer(Step_ReleaseE, 0)
    SetTimer(Step_Click, 0)
    SetTimer(Step_NextClick, 0)
    SetTimer(CooldownTick, 0)
    SetTimer(RuntimeTick, 0)

    ControlSend("{e up}", , "ahk_exe RobloxPlayerBeta.exe")
    Send("{e up}")
    Click("Up")

    tickCount := 0
    statusText.Text := "Status: STOPPED"
    timerStatus.Text := "Next Drink: Ready"
    runtimeText.Text := "Runtime: 00:00:00"
    ToolTip("sageSanity: STOPPED")
    SetTimer(() => ToolTip(), -1500)
}

RuntimeTick() {
    global runtimeSeconds, running, runtimeText
    if !running {
        SetTimer(RuntimeTick, 0)
        return
    }
    runtimeSeconds++
    h := runtimeSeconds // 3600
    m := Mod(runtimeSeconds, 3600) // 60
    s := Mod(runtimeSeconds, 60)
    runtimeText.Text := "Runtime: " Format("{:02}", h) ":" Format("{:02}", m) ":" Format("{:02}", s)
}

Step_HoldE() {
    global running, forceStop
    if !running || forceStop
        return
    Send("{e down}")
    SetTimer(Step_ReleaseE, -HoldE_Duration)
}

Step_ReleaseE() {
    global running, forceStop, clicksDone
    if !running || forceStop {
        Send("{e up}")
        return
    }
    Send("{e up}")
    clicksDone := 0
    SetTimer(Step_Click, -100)
}

Step_Click() {
    global running, forceStop, clicksDone, ClickCount, drinkCount, drinkStatus
    if !running || forceStop
        return
    Click()
    clicksDone++
    if clicksDone < ClickCount
        SetTimer(Step_NextClick, -ClickGap)
    else {
        drinkCount++
        drinkStatus.Text := "Drinks: " drinkCount
        SetTimer(CooldownTick, 1000)
        SetTimer(Step_HoldE, -CooldownMs)
    }
}

Step_NextClick() {
    global running, forceStop
    if !running || forceStop
        return
    Step_Click()
}

CooldownTick() {
    global tickCount, running, CooldownMs, timerStatus
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
        timerStatus.Text := "Next Drink: Ready"
        ToolTip()
    } else {
        timerStatus.Text := "Next Drink: " secsLeft "s"
        ToolTip("sageSanity: next drink in " secsLeft "s")
    }
}

ChangeMachine(*) {
    global Machine, CooldownMs, machineBox, configFile, machineStatus
    Machine := machineBox.Text
    if Machine = "Main"
        CooldownMs := 180000
    else if Machine = "Barney"
        CooldownMs := 300000
    machineStatus.Text := "Machine: " Machine
    IniWrite(Machine, configFile, "Settings", "Machine")
    IniWrite(CooldownMs, configFile, "Settings", "Cooldown")
}

SaveSettings(*) {
    global configFile, CooldownMs, HoldE_Duration, ClickCount, ClickGap
    global cooldownInput, holdInput, clickInput, gapInput

    if !IsNumber(cooldownInput.Value) || !IsNumber(holdInput.Value)
    || !IsNumber(clickInput.Value) || !IsNumber(gapInput.Value) {
        ToolTip("sageSanity: Invalid settings")
        SetTimer(() => ToolTip(), -1500)
        return
    }

    newCooldown := Number(cooldownInput.Value)
    newHold     := Number(holdInput.Value)
    newClicks   := Number(clickInput.Value)
    newGap      := Number(gapInput.Value)

    if newCooldown <= 0 || newHold <= 0 || newClicks < 0 || newGap < 0 {
        ToolTip("sageSanity: Invalid settings")
        SetTimer(() => ToolTip(), -1500)
        return
    }

    CooldownMs     := newCooldown
    HoldE_Duration := newHold
    ClickCount     := newClicks
    ClickGap       := newGap

    IniWrite(CooldownMs,     configFile, "Settings", "Cooldown")
    IniWrite(HoldE_Duration, configFile, "Settings", "HoldDuration")
    IniWrite(ClickCount,     configFile, "Settings", "Clicks")
    IniWrite(ClickGap,       configFile, "Settings", "ClickGap")

    ToolTip("sageSanity: Settings Saved")
    SetTimer(() => ToolTip(), -1500)
}
