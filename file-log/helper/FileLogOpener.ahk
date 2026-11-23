; File Log Opener (AutoHotkey v2)  -  v2, no PowerShell (no black flash)
; Runs quietly in the background (green "H" icon near the clock).
; When the File Log "Open" button copies a line starting with  filelog:open?p=
; this script opens File Explorer at that place:
;   folder  -> opens the folder
;   file    -> opens its folder with the file highlighted (the file is NOT opened)
;   missing -> opens the nearest folder that still exists + a short message
; It reacts ONLY to filelog: lines. Anything else you copy is ignored.

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

OnClipboardChange(FileLogClip)

FileLogClip(type) {
    if (type != 1)                                   ; 1 = text was copied
        return
    txt := Trim(A_Clipboard)
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
        Run('explorer.exe "' path '"')
    } else if FileExist(path) {
        Run('explorer.exe /select,"' path '"')
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
            Run('explorer.exe "' parent '"')
        MsgBox("Not found (moved or renamed?):`n" path, "File Log", "Icon! T6")
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
