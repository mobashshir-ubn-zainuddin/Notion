#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; Show Notion icon in system tray when Notion.exe is opened directly
TraySetIcon(A_ScriptDir "\NotionIcon.ico")
A_IconTip := "Notion"
