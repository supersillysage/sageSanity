#Requires AutoHotkey v2.0
#SingleInstance Force

CurrentVersion := "1.4"

; ---------- hover tooltips (must init before any GUI controls register tips) ----------
CoordMode("Mouse", "Screen")
CoordMode("ToolTip", "Screen")
HoverTips := Map()

RegisterHoverTip(ctrl, text) {
    global HoverTips
    HoverTips[ctrl.Hwnd] := text
}

lastHoverHwnd := 0
CheckHover() {
    global HoverTips, lastHoverHwnd
    MouseGetPos(&mx, &my, &winHwnd, &ctrlHwnd, 2)
    if ctrlHwnd = lastHoverHwnd
        return
    lastHoverHwnd := ctrlHwnd
    if HoverTips.Has(ctrlHwnd)
        ToolTip(HoverTips[ctrlHwnd], mx + 16, my + 16, 2)
    else
        ToolTip(,,, 2)
}

; ---------- error handling / logging ----------
OnError(GlobalErrorHandler)

GlobalErrorHandler(err, mode) {
    crashFile := GetNextCrashLogPath()
    try FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") " ERROR: " err.Message " (in " err.What ", line " err.Line ")`n", crashFile)
    try MsgBox("sageSanity ran into a problem and had to stop that action.`n`n"
        . err.Message
        . "`n`nDetails were saved to " crashFile ".", "sageSanity - Error", "Icon!")
    return true
}

GetNextCrashLogPath() {
    n := 1
    Loop {
        path := A_ScriptDir "\sageSanity-crashlog-" n ".log"
        if !FileExist(path)
            return path
        n++
    }
}

Log(msg) {
    try FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") " - " msg "`n", A_ScriptDir "\sageSanity.log")
}

configFile := A_ScriptDir "\config.ini"
if !FileExist(configFile) {
    CreateConfig()
}
if GetPresetList().Length = 0 {
    CreateConfig()
}

; ---------- load active settings ----------
ActivePreset   := IniRead(configFile, "State", "ActivePreset", "Main")
CooldownMs     := Number(IniRead(configFile, "Preset:" ActivePreset, "Cooldown", 180000))
HoldE_Duration := Number(IniRead(configFile, "Preset:" ActivePreset, "HoldDuration", 2000))
ClickCount     := Number(IniRead(configFile, "Preset:" ActivePreset, "Clicks", 3))
ClickGap       := Number(IniRead(configFile, "Preset:" ActivePreset, "ClickGap", 1500))

ToggleHotkey := IniRead(configFile, "State", "ToggleHotkey", "F1")
TopHotkey    := IniRead(configFile, "State", "TopHotkey", "F2")

; ---------- gui ----------
myGui := Gui("+Resize", "sageSanity v" CurrentVersion)
tabs := myGui.AddTab3("x10 y10 w480 h270", ["Main", "Presets", "Settings", "Credits", "About"])

; ===== MAIN TAB (left: status, right: controls) =====
tabs.UseTab(1)
statusText    := myGui.AddText("x30 y50 w220", "Status: STOPPED")
presetText    := myGui.AddText("x30 y74 w220", "Preset: " ActivePreset)
drinkStatus   := myGui.AddText("x30 y98 w220", "Drinks: 0")
runtimeText   := myGui.AddText("x30 y122 w220", "Runtime: 00:00:00")
timerStatus   := myGui.AddText("x30 y146 w220", "Next Drink: Ready")

myGui.AddText("x270 y50 w200", "Quick Switch Preset:")
mainPresetBox := myGui.AddDropDownList("x270 y72 w200", GetPresetList())
if GetPresetList().Length > 0 {
    try mainPresetBox.Choose(ActivePreset)
    catch
        mainPresetBox.Choose(1)
}
mainPresetBox.OnEvent("Change", (*) => QuickSwitchPreset(mainPresetBox.Text))
RegisterHoverTip(mainPresetBox, "Switch the active preset immediately")

startButton := myGui.AddButton("x270 y110 w200", "Start")
stopButton  := myGui.AddButton("x270 y142 w200", "Stop")
startButton.OnEvent("Click", (*) => StartFromGUI())
stopButton.OnEvent("Click", (*) => StopMacro())
RegisterHoverTip(startButton, "Starts the macro using the active preset")
RegisterHoverTip(stopButton, "Stops the macro and releases any held keys")

; ===== PRESETS TAB (left: list, right: actions) =====
tabs.UseTab(2)
myGui.AddText("x30 y50 w220", "Saved Presets:")
presetListBox := myGui.AddListBox("x30 y72 w220 h160", GetPresetList())
RegisterHoverTip(presetListBox, "Your saved machine presets")

loadPresetBtn   := myGui.AddButton("x270 y72 w200", "Load Preset")
deletePresetBtn := myGui.AddButton("x270 y104 w200", "Delete Preset")
loadPresetBtn.OnEvent("Click", (*) => LoadSelectedPreset())
deletePresetBtn.OnEvent("Click", (*) => DeleteSelectedPreset())
RegisterHoverTip(loadPresetBtn, "Load the selected preset as active")
RegisterHoverTip(deletePresetBtn, "Delete the selected preset (can't delete the active one)")

savePresetBtn := myGui.AddButton("x270 y144 w200 h40", "Save Current Settings As New Preset")
savePresetBtn.OnEvent("Click", (*) => SaveAsNewPreset())
RegisterHoverTip(savePresetBtn, "Save the values on the Settings tab as a new preset")

renamePresetBtn := myGui.AddButton("x270 y194 w200", "Rename Preset")
renamePresetBtn.OnEvent("Click", (*) => RenameSelectedPreset())
RegisterHoverTip(renamePresetBtn, "Rename the selected preset")

; ===== SETTINGS TAB (left column / right column) =====
tabs.UseTab(3)
myGui.AddText("x30 y50 w200", "Cooldown (ms):")
cooldownInput := myGui.AddEdit("x30 y72 w200", CooldownMs)
RegisterHoverTip(cooldownInput, "Time between coffee drinks, in milliseconds (1000ms = 1s)")

myGui.AddText("x30 y104 w200", "Clicks:")
clickInput := myGui.AddEdit("x30 y126 w200", ClickCount)
RegisterHoverTip(clickInput, "How many times to click to drink coffee")

myGui.AddText("x270 y50 w200", "Hold Duration (ms):")
holdInput := myGui.AddEdit("x270 y72 w200", HoldE_Duration)
RegisterHoverTip(holdInput, "How long to hold E to interact with the machine, in milliseconds")

myGui.AddText("x270 y104 w200", "Click Gap (ms):")
gapInput := myGui.AddEdit("x270 y126 w200", ClickGap)
RegisterHoverTip(gapInput, "Delay between each drink click, in milliseconds")

myGui.AddText("x30 y158 w200", "Toggle Hotkey:")
toggleHotkeyCtrl := myGui.AddHotkey("x30 y180 w200", ToggleHotkey)
RegisterHoverTip(toggleHotkeyCtrl, "Key that starts/stops the macro")

myGui.AddText("x270 y158 w200", "Always-On-Top Hotkey:")
topHotkeyCtrl := myGui.AddHotkey("x270 y180 w200", TopHotkey)
RegisterHoverTip(topHotkeyCtrl, "Key that toggles the window staying on top")

saveSettingsBtn   := myGui.AddButton("x30 y220 w215", "Save To Current Preset")
resetDefaultsBtn  := myGui.AddButton("x255 y220 w215", "Reset to Default")
saveSettingsBtn.OnEvent("Click", (*) => SaveSettings())
resetDefaultsBtn.OnEvent("Click", (*) => ResetToDefaults())
RegisterHoverTip(saveSettingsBtn, "Save these values to the currently active preset")
RegisterHoverTip(resetDefaultsBtn, "Reset these fields to sageSanity's original defaults (doesn't save until you click Save)")

; ===== CREDITS TAB (left: creator, right: inspiration, bottom: other) =====
tabs.UseTab(4)

myGui.AddText("x30 y50 w200", "The Creator")
; sage
if FileExist(A_ScriptDir "\assets\sagepfp.jpg")
    myGui.AddPicture("x30 y74 w64 h64", A_ScriptDir "\assets\sagepfp.jpg")
myGui.AddText("x110 y74 w130", "sage (notsupersillysage)")
myGui.AddText("x110 y96 w130", "`"made this for fun lol`"")

myGui.AddText("x270 y50 w200", "The Inspiration")
; dolphSol inspiration
if FileExist(A_ScriptDir "\assets\dolphpfp.png")
    myGui.AddPicture("x270 y74 w64 h64", A_ScriptDir "\assets\dolphpfp.png")
myGui.AddText("x350 y74 w130", "BuilderDolphin")
myGui.AddText("x350 y96 w130 h64", "The creator of DolphSol, a macro for Sol's RNG, heavily inspired this project and helped with ideas overall.")

; ===== ABOUT TAB (left: version/updates, right: other/links) =====
tabs.UseTab(5)

myGui.AddText("x30 y50 w200", "Version: v" CurrentVersion)
updateStatusText := myGui.AddText("x30 y72 w200", "")
checkUpdateBtn := myGui.AddButton("x30 y96 w200", "Check for Updates")
checkUpdateBtn.OnEvent("Click", (*) => CheckForUpdates())
RegisterHoverTip(checkUpdateBtn, "Checks GitHub for a newer release")

myGui.AddText("x270 y50 w200", "Other")
myGui.AddText("x270 y72 w200", "ask me anything on discord:")
myGui.AddText("x270 y94 w200", "@notsupersillysage")

if FileExist(A_ScriptDir "\assets\githublogo.jpg") {
    githubLogoBtn := myGui.AddPicture("x270 y126 w48 h48", A_ScriptDir "\assets\githublogo.jpg")
    githubLogoBtn.OnEvent("Click", (*) => Run("https://github.com/supersillysage/sageSanity"))
    RegisterHoverTip(githubLogoBtn, "Visit the GitHub! (updates, readme, versions)")
} else {
    githubLink := myGui.AddLink("x270 y126 w200", '<a href="https://github.com/supersillysage/sageSanity">visit the github!</a>')
}

tabs.UseTab()

myGui.Show()
myGui.OnEvent("Close", (*) => myGui.Hide())

; ---------- tray ----------
A_TrayMenu.Delete()
A_TrayMenu.Add("Open", (*) => myGui.Show())
A_TrayMenu.Add("Start", (*) => StartFromGUI())
A_TrayMenu.Add("Stop", (*) => StopMacro())
A_TrayMenu.Add()
A_TrayMenu.Add("Reload Script", (*) => Reload())
A_TrayMenu.Add("Exit", (*) => ExitApp())
A_TrayMenu.Default := "Open"

; ---------- state ----------
guiTop         := false
running        := false
forceStop      := false
tickCount      := 0
drinkCount     := 0
clicksDone     := 0
runtimeSeconds := 0

SetTimer(CheckHover, 200)

; ---------- config helpers ----------
CreateConfig() {
    global configFile
    IniWrite("Main", configFile, "State", "ActivePreset")
    IniWrite("F1",   configFile, "State", "ToggleHotkey")
    IniWrite("F2",   configFile, "State", "TopHotkey")
    IniWrite(180000, configFile, "Preset:Main", "Cooldown")
    IniWrite(2000,   configFile, "Preset:Main", "HoldDuration")
    IniWrite(3,      configFile, "Preset:Main", "Clicks")
    IniWrite(1500,   configFile, "Preset:Main", "ClickGap")

    IniWrite(300000, configFile, "Preset:Barney", "Cooldown")
    IniWrite(2000,   configFile, "Preset:Barney", "HoldDuration")
    IniWrite(3,      configFile, "Preset:Barney", "Clicks")
    IniWrite(1500,   configFile, "Preset:Barney", "ClickGap")
}

GetPresetList() {
    global configFile
    sections := IniRead(configFile)
    presets := []
    Loop Parse, sections, "`n" {
        if InStr(A_LoopField, "Preset:") = 1
            presets.Push(SubStr(A_LoopField, 8))
    }
    return presets
}

; ---------- hotkeys (dynamic so they can be remapped from Settings) ----------
ToggleMacroHandler(*) {
    global running
    if running
        StopMacro()
    else
        StartMacro()
}

ToggleAlwaysOnTopHandler(*) {
    global guiTop, myGui
    guiTop := !guiTop
    if guiTop {
        myGui.Show("x" A_ScreenWidth - 520 " y50")
        WinSetAlwaysOnTop(true, "sageSanity")
    } else {
        WinSetAlwaysOnTop(false, "sageSanity")
    }
}

Hotkey(ToggleHotkey, ToggleMacroHandler)
Hotkey(TopHotkey, ToggleAlwaysOnTopHandler)

; ---------- focus handling ----------
FocusRoblox() {
    if WinActive("ahk_exe RobloxPlayerBeta.exe")
        return
    if WinExist("ahk_exe RobloxPlayerBeta.exe") {
        WinActivate("ahk_exe RobloxPlayerBeta.exe")
        Sleep(1000)
    }
}

; ---------- start / stop ----------
StartMacro() {
    global running, forceStop, statusText, presetText, ActivePreset, runtimeSeconds, ToggleHotkey

    if !WinExist("ahk_exe RobloxPlayerBeta.exe") {
        MsgBox("sageSanity couldn't find Roblox running.`n`nPlease open Roblox and try again.", "sageSanity", "Icon!")
        Log("Start blocked: Roblox not running")
        return
    }

    forceStop := false
    running := true
    runtimeSeconds := 0
    statusText.Text := "Status: RUNNING"
    presetText.Text := "Preset: " ActivePreset
    ToolTip("sageSanity: RUNNING`n" ToggleHotkey " to stop")
    SetTimer(() => ToolTip(), -1500)
    SetTimer(RuntimeTick, 1000)
    FocusRoblox()
    SetTimer(Step_HoldE, -50)
    Log("Macro started (preset: " ActivePreset ")")
}

StartFromGUI() {
    global running, forceStop, statusText, presetText, ActivePreset, guiTop, myGui, runtimeSeconds, ToggleHotkey

    if !WinExist("ahk_exe RobloxPlayerBeta.exe") {
        MsgBox("sageSanity couldn't find Roblox running.`n`nPlease open Roblox and try again.", "sageSanity", "Icon!")
        Log("Start blocked: Roblox not running")
        return
    }

    forceStop := false
    running := true
    runtimeSeconds := 0
    statusText.Text := "Status: RUNNING"
    presetText.Text := "Preset: " ActivePreset
    ToolTip("sageSanity: RUNNING`n" ToggleHotkey " to stop")
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
    Log("Macro started from GUI (preset: " ActivePreset ")")
}

StopMacro() {
    global running, forceStop, statusText, timerStatus, tickCount, clicksDone, runtimeText, drinkCount, runtimeSeconds

    wasRunning := running
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

    if wasRunning
        Log("Macro stopped. Drinks: " drinkCount ", Runtime: " FormatHMS(runtimeSeconds))
}

; ---------- timers ----------
RuntimeTick() {
    global runtimeSeconds, running, runtimeText
    if !running {
        SetTimer(RuntimeTick, 0)
        return
    }
    runtimeSeconds++
    runtimeText.Text := "Runtime: " FormatHMS(runtimeSeconds)
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

; ---------- time formatting (v1.3: M:SS / H:MM:SS instead of raw seconds) ----------
FormatMS(totalSeconds) {
    m := totalSeconds // 60
    s := Mod(totalSeconds, 60)
    return m ":" Format("{:02}", s)
}

FormatHMS(totalSeconds) {
    h := totalSeconds // 3600
    m := Mod(totalSeconds, 3600) // 60
    s := Mod(totalSeconds, 60)
    return Format("{:02}", h) ":" Format("{:02}", m) ":" Format("{:02}", s)
}

; ---------- presets ----------
QuickSwitchPreset(name) {
    global ActivePreset, configFile
    ApplyPreset(name)
    IniWrite(name, configFile, "State", "ActivePreset")
}

LoadSelectedPreset() {
    global presetListBox, mainPresetBox, configFile
    name := presetListBox.Text
    if name = ""
        return
    ApplyPreset(name)
    IniWrite(name, configFile, "State", "ActivePreset")
    mainPresetBox.Delete()
    mainPresetBox.Add(GetPresetList())
    mainPresetBox.Choose(name)
    ToolTip("sageSanity: Loaded preset " name)
    SetTimer(() => ToolTip(), -1500)
}

ApplyPreset(name) {
    global configFile, ActivePreset, CooldownMs, HoldE_Duration, ClickCount, ClickGap
    global cooldownInput, holdInput, clickInput, gapInput, presetText

    ActivePreset   := name
    CooldownMs     := Number(IniRead(configFile, "Preset:" name, "Cooldown", 180000))
    HoldE_Duration := Number(IniRead(configFile, "Preset:" name, "HoldDuration", 2000))
    ClickCount     := Number(IniRead(configFile, "Preset:" name, "Clicks", 3))
    ClickGap       := Number(IniRead(configFile, "Preset:" name, "ClickGap", 1500))

    cooldownInput.Value := CooldownMs
    holdInput.Value     := HoldE_Duration
    clickInput.Value    := ClickCount
    gapInput.Value       := ClickGap
    presetText.Text      := "Preset: " ActivePreset
}

SaveAsNewPreset() {
    global configFile, cooldownInput, holdInput, clickInput, gapInput
    global presetListBox, mainPresetBox

    result := InputBox("Enter a name for this preset:", "sageSanity - New Preset")
    if result.Result != "OK" || Trim(result.Value) = ""
        return
    name := Trim(result.Value)

    IniWrite(cooldownInput.Value, configFile, "Preset:" name, "Cooldown")
    IniWrite(holdInput.Value,     configFile, "Preset:" name, "HoldDuration")
    IniWrite(clickInput.Value,    configFile, "Preset:" name, "Clicks")
    IniWrite(gapInput.Value,      configFile, "Preset:" name, "ClickGap")

    presetListBox.Delete()
    presetListBox.Add(GetPresetList())
    mainPresetBox.Delete()
    mainPresetBox.Add(GetPresetList())

    ToolTip("sageSanity: Saved preset " name)
    SetTimer(() => ToolTip(), -1500)
}

DeleteSelectedPreset() {
    global presetListBox, mainPresetBox, configFile, ActivePreset

    name := presetListBox.Text
    if name = ""
        return
    if name = ActivePreset {
        ToolTip("sageSanity: Can't delete the active preset")
        SetTimer(() => ToolTip(), -1500)
        return
    }
    IniDelete(configFile, "Preset:" name)
    presetListBox.Delete()
    presetListBox.Add(GetPresetList())
    mainPresetBox.Delete()
    mainPresetBox.Add(GetPresetList())
    mainPresetBox.Choose(ActivePreset)
}

RenameSelectedPreset() {
    global presetListBox, mainPresetBox, configFile, ActivePreset, presetText

    name := presetListBox.Text
    if name = ""
        return

    result := InputBox("Enter a new name for `"" name "`":", "sageSanity - Rename Preset", , name)
    if result.Result != "OK"
        return
    newName := Trim(result.Value)
    if newName = "" || newName = name
        return

    ; copy old values to the new name, then remove the old section
    cd := IniRead(configFile, "Preset:" name, "Cooldown")
    hd := IniRead(configFile, "Preset:" name, "HoldDuration")
    ck := IniRead(configFile, "Preset:" name, "Clicks")
    cg := IniRead(configFile, "Preset:" name, "ClickGap")

    IniWrite(cd, configFile, "Preset:" newName, "Cooldown")
    IniWrite(hd, configFile, "Preset:" newName, "HoldDuration")
    IniWrite(ck, configFile, "Preset:" newName, "Clicks")
    IniWrite(cg, configFile, "Preset:" newName, "ClickGap")
    IniDelete(configFile, "Preset:" name)

    if ActivePreset = name {
        ActivePreset := newName
        IniWrite(ActivePreset, configFile, "State", "ActivePreset")
        presetText.Text := "Preset: " ActivePreset
    }

    presetListBox.Delete()
    presetListBox.Add(GetPresetList())
    mainPresetBox.Delete()
    mainPresetBox.Add(GetPresetList())
    try mainPresetBox.Choose(ActivePreset)

    ToolTip("sageSanity: Renamed to " newName)
    SetTimer(() => ToolTip(), -1500)
}

; ---------- settings ----------
ResetToDefaults() {
    global cooldownInput, holdInput, clickInput, gapInput
    cooldownInput.Value := 180000
    holdInput.Value     := 2000
    clickInput.Value    := 3
    gapInput.Value       := 1500
    ToolTip("sageSanity: Defaults loaded, click Save to apply")
    SetTimer(() => ToolTip(), -1500)
}

SaveSettings(*) {
    global configFile, CooldownMs, HoldE_Duration, ClickCount, ClickGap, ActivePreset
    global cooldownInput, holdInput, clickInput, gapInput
    global ToggleHotkey, TopHotkey, toggleHotkeyCtrl, topHotkeyCtrl

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

    IniWrite(CooldownMs,     configFile, "Preset:" ActivePreset, "Cooldown")
    IniWrite(HoldE_Duration, configFile, "Preset:" ActivePreset, "HoldDuration")
    IniWrite(ClickCount,     configFile, "Preset:" ActivePreset, "Clicks")
    IniWrite(ClickGap,       configFile, "Preset:" ActivePreset, "ClickGap")

    ; apply hotkey changes if the user remapped either one
    newToggle := toggleHotkeyCtrl.Value
    newTop     := topHotkeyCtrl.Value

    if newToggle != "" && newToggle != ToggleHotkey {
        try Hotkey(ToggleHotkey, "Off")
        ToggleHotkey := newToggle
        Hotkey(ToggleHotkey, ToggleMacroHandler)
        IniWrite(ToggleHotkey, configFile, "State", "ToggleHotkey")
    }

    if newTop != "" && newTop != TopHotkey {
        try Hotkey(TopHotkey, "Off")
        TopHotkey := newTop
        Hotkey(TopHotkey, ToggleAlwaysOnTopHandler)
        IniWrite(TopHotkey, configFile, "State", "TopHotkey")
    }

    ToolTip("sageSanity: Settings Saved to " ActivePreset)
    SetTimer(() => ToolTip(), -1500)
}

; ---------- version checker ----------
CheckForUpdates() {
    global CurrentVersion, updateStatusText

    updateStatusText.Text := "checking..."

    try {
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        req.Open("GET", "https://api.github.com/repos/supersillysage/sageSanity/releases/latest", false)
        req.SetRequestHeader("User-Agent", "sageSanity-updatecheck")
        req.Send()

        if req.Status != 200 {
            updateStatusText.Text := "update check failed"
            return
        }

        responseText := req.ResponseText
        if !RegExMatch(responseText, '"tag_name"\s*:\s*"v?([\d\.]+[a-z]?)"', &m) {
            updateStatusText.Text := "update check failed"
            return
        }

        latestVersion := m[1]

        if latestVersion = CurrentVersion
            updateStatusText.Text := "you're up to date (v" CurrentVersion ")"
        else
            updateStatusText.Text := "v" latestVersion " available!"
    } catch as err {
        updateStatusText.Text := "update check failed"
    }
}
