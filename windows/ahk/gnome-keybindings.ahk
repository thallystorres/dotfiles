#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn Off
; =============================================================================
; windows/ahk/gnome-keybindings.ahk
; -----------------------------------------------------------------------------
; Replicates gnome/keybindings.ini on Windows 11 so muscle memory transfers.
; Super = Win key. AHK v2 syntax: # Win, ! Alt, ^ Ctrl, + Shift.
;
; Binding                       GNOME action            -> Windows action
;   Super+w                     close                   -> Alt+F4
;   Super+k                     maximize                -> Win+Up
;   Super+j                     unmaximize/restore      -> Win+Down
;   Super+d                     minimize                -> Win+Down (Windows
;                                                            restores then
;                                                            minimizes; the OS
;                                                            picks the right
;                                                            step from state)
;   Super+h                     tile left               -> Win+Left
;   Super+l                     tile right              -> Win+Right
;   Shift+Super+h               move to monitor left   -> Win+Shift+Left
;   Shift+Super+l               move to monitor right  -> Win+Shift+Right
;   Shift+Super+j               move to monitor down   -> Win+Shift+Down
;   Shift+Super+k               move to monitor up     -> Win+Shift+Up
;   Shift+Super+s               screenshot UI           -> Win+Shift+S
;   Super+q                     screen lock             -> LockWorkStation()
;   Super+Enter                 launch terminal         -> Windows Terminal
;
; PRE-REQ: Win+L is reserved by Windows for lock. To bind Super+l to snap
; right instead, disable the lock handler once by running (as admin):
;     powershell -ExecutionPolicy Bypass -File windows\enable-super-l.ps1
; then reboot. Super+q still locks via the API directly, so you don't lose
; lock — you only change WHICH key locks and which one snaps.
; =============================================================================

; --- close ------------------------------------------------------------------
#w::Send "!{F4}"                      ; Super+w -> Alt+F4

; --- maximize / restore / minimize -----------------------------------------
#k::Send "#{Up}"                      ; Super+k -> maximize
#j::Send "#{Down}"                    ; Super+j -> restore
#d::Send "#{Down}"                    ; Super+d -> minimize (Win+Down minimizes when already restored)

; --- tiling ------------------------------------------------------------------
#h::Send "#{Left}"                    ; Super+h -> snap left
#l::Send "#{Right}"                   ; Super+l -> snap right (needs enable-super-l)

; --- move between monitors --------------------------------------------------
+#h::Send "#+{Left}"                  ; Shift+Super+h -> monitor left
+#l::Send "#+{Right}"                 ; Shift+Super+l -> monitor right
+#j::Send "#+{Down}"                  ; Shift+Super+j -> monitor down
+#k::Send "#+{Up}"                    ; Shift+Super+k -> monitor up

; --- screenshot UI ----------------------------------------------------------
+#s::Send "#+s"                       ; Shift+Super+s -> Snipping Tool

; --- lock screen (calls the API so it works even with Win+L disabled) ------
#q::DllCall("user32.dll\LockWorkStation")

; --- launch Windows Terminal ------------------------------------------------
#Enter::Run "wt.exe"