# tools-lab

Small, single-file tools I built for my own study and work. Each one runs entirely in the browser, with no sign-in and no backend.

| Tool | What it does | Live link |
|---|---|---|
| Page Pacer (v1.4) | Reads a PDF at a steady pace and lets you highlight and export it | https://ashujavadev.github.io/tools-lab/page-pacer/ |
| File Log (v2.1) | A searchable list of what I saved and where: list + folder-tree view, Copy folder, one-click Open in File Explorer, and a 🔄 Sync button that mirrors Downloads + Documents (with the helper below). Stored in your browser here | https://ashujavadev.github.io/tools-lab/file-log/ |

## File Log helper (Windows, optional)
`file-log/helper/FileLogOpener.ahk` (AutoHotkey v2) makes the 📂 Open button work: the button copies a `filelog:open?p=<path>` line, and the script, running in the background, opens File Explorer at that folder (or with that file highlighted). The 🔄 Sync button copies `filelog:sync`; the script then scans Downloads + Documents (names, sizes, dates only) and puts the list on the clipboard, and you press Ctrl+V on the page. It never opens or runs your files, and ignores anything else you copy. Double-click it to start; put a shortcut in `shell:startup` to start it with Windows.

## Tech
Plain HTML, CSS and JavaScript. Page Pacer uses pdf.js and pdf-lib from cdnjs.

Built by Ashu (PadhakuGang), with Claude's help.
