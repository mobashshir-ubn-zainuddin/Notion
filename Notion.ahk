
#Requires AutoHotkey v2.0
#SingleInstance Force

A_IconTip := "Notion"

; ==========================================
; APP VISIBILITY & PROCESS MANAGER
; ==========================================
global TargetExe := "Spotify.exe"

global HideMode := false
global HiddenWindows := Map()

DetectHiddenWindows(true)
OnExit(RestoreOnExit)


; ==========================================
; GLOBAL SHORTCUTS
; ==========================================

; Ctrl + Shift + H = Hide all windows
^+h::EnableHide()

; Ctrl + Shift + S = Restore all windows
^+s::RestoreTarget()

; Ctrl + Shift + X = Normal close all windows
^+x::CloseAllWindows()

; Ctrl + Shift + Q = Force close all processes
^+q::ForceCloseTarget()

; Ctrl + Shift + W = Exit Notion completely
$^+w::ExitApp()


; ==========================================
; HIDE ALL WINDOWS
; ==========================================

EnableHide() {
    global TargetExe, HideMode

    if (TargetExe = "") {
        MsgBox("No target application configured.")
        return
    }

    HideMode := true

    SetTimer(MonitorTarget, 200)
    MonitorTarget()

    ToolTip("HIDE MODE ON: " TargetExe)
    SetTimer(() => ToolTip(), -1500)
}


; ==========================================
; AUTOMATIC WINDOW MONITORING
; ==========================================

MonitorTarget() {
    global TargetExe, HideMode, HiddenWindows

    if (!HideMode)
        return

    windows := WinGetList("ahk_exe " TargetExe)

    for hwnd in windows {

        if HiddenWindows.Has(hwnd)
            continue

        try {
            style := WinGetStyle("ahk_id " hwnd)

            ; WS_VISIBLE
            if !(style & 0x10000000)
                continue

            pid := WinGetPID("ahk_id " hwnd)

            WinHide("ahk_id " hwnd)

            HiddenWindows[hwnd] := pid

        } catch {
            continue
        }
    }
}


; ==========================================
; RESTORE ALL HIDDEN WINDOWS
; ==========================================

RestoreTarget() {
    global TargetExe, HideMode, HiddenWindows

    HideMode := false
    SetTimer(MonitorTarget, 0)

    restored := 0

    for hwnd, originalPID in HiddenWindows {

        try {
            if !WinExist("ahk_id " hwnd)
                continue

            currentPID := WinGetPID("ahk_id " hwnd)
            currentEXE := WinGetProcessName("ahk_id " hwnd)

            if (currentPID = originalPID
                && StrLower(currentEXE) = StrLower(TargetExe)) {

                WinShow("ahk_id " hwnd)
                restored++
            }

        } catch {
            continue
        }
    }

    HiddenWindows := Map()

    ToolTip("RESTORED WINDOWS: " restored)
    SetTimer(() => ToolTip(), -1500)
}


; ==========================================
; NORMAL CLOSE ALL WINDOWS
; Ctrl + Shift + X
; ==========================================

CloseAllWindows() {
    global TargetExe, HideMode, HiddenWindows

    HideMode := false
    SetTimer(MonitorTarget, 0)

    windows := WinGetList("ahk_exe " TargetExe)

    if (windows.Length = 0) {
        HiddenWindows := Map()
        ToolTip("No application windows found")
        SetTimer(() => ToolTip(), -1500)
        return
    }

    closedRequests := 0

    for hwnd in windows {

        try {
            if !WinExist("ahk_id " hwnd)
                continue

            ; Reveal hidden windows before closing
            WinShow("ahk_id " hwnd)

            ; Send normal close request
            WinClose("ahk_id " hwnd)

            closedRequests++

        } catch {
            continue
        }
    }

    HiddenWindows := Map()

    ToolTip("CLOSE REQUESTS SENT: " closedRequests)
    SetTimer(() => ToolTip(), -2000)
}


; ==========================================
; FORCE CLOSE ALL PROCESSES
; Ctrl + Shift + Q
; ==========================================

ForceCloseTarget() {
    global TargetExe, HideMode, HiddenWindows

    if (TargetExe = "") {
        MsgBox("No target application configured.")
        return
    }

    answer := MsgBox(
        "WARNING: This will FORCE TERMINATE every process named "
        TargetExe ".`n`n"
        "Unsaved work will be lost.`n`n"
        "Continue?",
        "Confirm Force Close",
        "YesNo Icon!"
    )

    if (answer != "Yes")
        return

    HideMode := false
    SetTimer(MonitorTarget, 0)

    HiddenWindows := Map()

    terminated := 0

    ; Find and terminate every matching process
    Loop 100 {

        pid := ProcessExist(TargetExe)

        if (!pid)
            break

        try {
            ProcessClose(pid)
            ProcessWaitClose(pid, 2)

            if ProcessExist(pid)
                break

            terminated++

        } catch as err {
            MsgBox(
                "Process termination failed:`n" err.Message,
                "Error",
                "Icon!"
            )
            break
        }
    }

    remaining := ProcessExist(TargetExe)

    if (remaining) {
        ToolTip("Some processes remain. Check Task Manager.")
    } else {
        ToolTip("FORCE CLOSED: " terminated " process(es)")
    }

    SetTimer(() => ToolTip(), -2500)
}


; ==========================================
; SAFE EXIT
; Ctrl + Shift + W
; ==========================================

RestoreOnExit(*) {
    global HiddenWindows, TargetExe

    SetTimer(MonitorTarget, 0)

    for hwnd, originalPID in HiddenWindows {

        try {
            if WinExist("ahk_id " hwnd) {

                currentPID := WinGetPID("ahk_id " hwnd)
                currentEXE := WinGetProcessName("ahk_id " hwnd)

                if (currentPID = originalPID
                    && StrLower(currentEXE) = StrLower(TargetExe)) {

                    WinShow("ahk_id " hwnd)
                }
            }

        } catch {
            continue
        }
    }
}