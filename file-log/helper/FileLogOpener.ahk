; File Log Helper (AutoHotkey v2)  -  v2.1: Open (window comes to front) + Sync
; Runs quietly in the background (green "H" icon near the clock).
; It reacts ONLY to two kinds of copied text (anything else you copy is ignored):
;   filelog:open?p=<path>  -> opens File Explorer at that place
;       folder  -> opens the folder
;       file    -> opens its folder with the file highlighted (the file is NOT opened)
;       missing -> opens the nearest folder that still exists + a short message
;   filelog:sync           -> scans Downloads + Documents (names, sizes, dates only;
;                             it never opens or reads inside your files) and puts the
;                             list on the clipboard. Then press Ctrl+V in File Log.

#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; Start with Windows: the first time this script runs, it puts its own shortcut
; into your Startup folder (only for your user). Delete that shortcut to undo.
startLink := A_Startup "\FileLogOpener.lnk"
if !FileExist(startLink) {
    try {
        FileCreateShortcut(A_ScriptFullPath, startLink, A_ScriptDir, , "File Log: opens folders from the Open button")
        TrayTip("File Log Opener will now start with Windows.", "File Log")
    }
}

; Folders the Sync scan skips (code build junk, system folders)
global SkipDirs := Map()
SkipDirs.CaseSense := "Off"
for nm in ["node_modules", ".git", ".idea", ".vscode", "target", "build", "dist", "__pycache__", ".gradle", "venv", ".venv", "My Music", "My Pictures", "My Videos"]
    SkipDirs[nm] := 1

OnClipboardChange(FileLogClip)

FileLogClip(type) {
    if (type != 1)                                   ; 1 = text was copied
        return
    txt := Trim(A_Clipboard)
    if (txt == "filelog:sync") {
        SetTimer(DoSync, -10)                        ; run the scan right after this
        return
    }
    prefix := "filelog:open?p="
    if !RegExMatch(txt, "^filelog:open\?p=[^\s`"]+$")
        return
    path := UriDecode(SubStr(txt, StrLen(prefix) + 1))
    ; safety: must be a normal local path like C:\... and contain no quotes
    if !RegExMatch(path, "^[A-Za-z]:\\") || InStr(path, '"')
        return
    path := RTrim(path, "\")
    if (StrLen(path) = 2)                            ; "C:" -> "C:\"
        path .= "\"

    if DirExist(path) {
        RunFront('explorer.exe "' path '"')
    } else if FileExist(path) {
        RunFront('explorer.exe /select,"' path '"')
    } else {
        parent := path
        loop 30 {
            SplitPath(parent, , &dir)
            if (dir = "" || dir = parent)
                break
            parent := dir
            if DirExist(parent)
                break
        }
        if DirExist(parent)
            RunFront('explorer.exe "' parent '"')
        MsgBox("Not found (moved or renamed?):`n" path, "File Log", "Icon! T6")
    }
}

; ---- Sync: list every file in Downloads + Documents ----
DoSync() {
    static busy := false
    if busy
        return
    busy := true
    ToolTip("File Log: scanning Downloads + Documents...")
    roots := [EnvGet("USERPROFILE") "\Downloads", A_MyDocuments]
    lines := []
    out := "FILELOG-SYNC 1`n"
    for r in roots {
        if DirExist(r) {
            out .= "#root`t" r "`n"
            ScanDir(r, lines)
        }
    }
    for l in lines
        out .= l "`n"
    A_Clipboard := out
    ToolTip()
    TrayTip("Sync ready: " lines.Length " files.`nGo back to File Log, click on the page, press Ctrl+V.", "File Log")
    busy := false
}

ScanDir(dir, lines) {
    try {
        Loop Files, dir "\*", "FD" {
            attr := A_LoopFileAttrib
            if InStr(attr, "H") || InStr(attr, "S")
                continue
            full := A_LoopFileFullPath
            nm := A_LoopFileName
            if InStr(attr, "D") {
                if !SkipDirs.Has(nm)
                    ScanDir(full, lines)
                continue
            }
            if (SubStr(nm, 1, 2) = "~$" || nm = "desktop.ini" || RegExMatch(nm, "i)\.(tmp|crdownload|part)$"))
                continue
            lines.Push(full "`t" A_LoopFileSize "`t" FormatTime(A_LoopFileTimeModified, "yyyy-MM-dd"))
        }
    }
}

; Turns %5C %20 etc. back into normal characters (UTF-8 aware, e.g. Hindi names)
UriDecode(str) {
    buf := Buffer(StrLen(str) * 3 + 1, 0), n := 0, i := 1, len := StrLen(str)
    while (i <= len) {
        c := SubStr(str, i, 1)
        hex := SubStr(str, i + 1, 2)
        if (c = "%" && RegExMatch(hex, "^[0-9A-Fa-f]{2}$")) {
            NumPut("UChar", Integer("0x" hex), buf, n), n += 1, i += 3
        } else {
            tmp := Buffer(8), k := StrPut(c, tmp, "UTF-8") - 1
            loop k
                NumPut("UChar", NumGet(tmp, A_Index - 1, "UChar"), buf, n), n += 1
            i += 1
        }
    }
    return StrGet(buf, n, "UTF-8")
}

; Opens Explorer and brings its window to the FRONT.
; (Windows sometimes keeps a window opened by a background script behind
;  the browser and only flashes the taskbar icon - this fixes that.)
RunFront(cmd) {
    before := Map()
    for h in WinGetList("ahk_class CabinetWClass")
        before[h] := 1
    Run(cmd)
    target := 0
    loop 30 {                                        ; wait up to ~3 seconds
        Sleep(100)
        for h in WinGetList("ahk_class CabinetWClass") {
            if !before.Has(h) {
                target := h
                break
            }
        }
        if target
            break
    }
    if !target                                       ; Explorer reused a window
        target := WinExist("ahk_class CabinetWClass")
    if target {
        try {
            if (WinGetMinMax(target) = -1)
                WinRestore(target)
            WinActivate(target)
        }
    }
}
