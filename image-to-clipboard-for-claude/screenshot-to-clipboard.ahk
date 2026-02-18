#Requires AutoHotkey v2.0
#SingleInstance Force

; Screenshot to Clipboard (Ctrl+Alt+S)
; Takes interactive screenshot via Snipping Tool, saves to file,
; and copies the file path to clipboard for pasting into Claude Code.

^!s:: {
    ; Clear clipboard so we can detect when the screenshot arrives
    A_Clipboard := ""

    ; Launch Snipping Tool in screen clip mode
    Run "ms-screenclip:"

    ; Wait up to 30 seconds for image data on clipboard
    if !ClipWait(30, 1) {
        ToolTip "Screenshot cancelled or timed out"
        SetTimer () => ToolTip(), -2000
        return
    }

    ; Build save path: Documents\Screenshots\screenshot_YYYY-MM-DD_HH-MM-SS.png
    screenshotDir := A_MyDocuments "\Screenshots"
    DirCreate screenshotDir
    timestamp := FormatTime(, "yyyy-MM-dd_HH-mm-ss")
    savePath := screenshotDir "\screenshot_" timestamp ".png"

    ; Save clipboard image to file via PowerShell
    psCmd := "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.Clipboard]::GetImage().Save('" savePath "')"
    RunWait 'powershell.exe -WindowStyle Hidden -Command "' psCmd '"',, "Hide"

    ; Verify the file was created
    if !FileExist(savePath) {
        ToolTip "Failed to save screenshot"
        SetTimer () => ToolTip(), -2000
        return
    }

    ; Copy file path to clipboard (replacing image data)
    A_Clipboard := savePath

    ; Show confirmation tooltip for 2 seconds
    ToolTip "Screenshot saved:`n" savePath
    SetTimer () => ToolTip(), -2000
}
