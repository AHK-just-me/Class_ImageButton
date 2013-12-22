#NoEnv
#Include Class_ImageButton.ahk
; ----------------------------------------------------------------------------------------------------------------------
; Button states:
; PBS_NORMAL    = 1
; PBS_HOT       = 2
; PBS_PRESSED   = 3
; PBS_DISABLED  = 4
; PBS_DEFAULTED = 5
; PBS_STYLUSHOT = 6 <- used only on tablet computers
; ----------------------------------------------------------------------------------------------------------------------
MsgBox, Start!
; ----------------------------------------------------------------------------------------------------------------------
Gui, Margin, 50, 20
Gui, Font, s10
Gui, Color, Gray
; Common button --------------------------------------------------------------------------------------------------------
Gui, Add, Button, w200, Common Button
; Image button with different colors for states normal, hot and defaulted ----------------------------------------------
Gui, Add, Button, vBT1 w200 hwndHBT1, Button 1
Opt1 := [0xCF0000, "White"]                  ; normal flat background & text colors
Opt2 := ["Red"]                              ; hot flat background color
Opt5 := [ , "Red"]                           ; defaulted text color
If !ImageButton.Create(HBT1, Opt1, Opt2, , , Opt5)
   MsgBox, 0, ImageButton Error Btn1, % ImageButton.LastError
; Image button with different 3D-style colors for states normal, hot, and pressed --------------------------------------
Gui, Add, Button, vBT2 w200 Default hwndHBT2, Button 2
Opt1 := [[0x404040, 0xC0C0C0, 2], "Blue"]    ; normal 3D-style background & text colors
Opt2 := [[0x606060, 0xF0F0F0, 2], "Green"]   ; hot 3D-style background & text colors
Opt3 := [ , "Red"]                           ; pressed text color
If !ImageButton.Create(HBT2,Opt1, Opt2, Opt3)
   MsgBox, 0, ImageButton Error Btn2, % ImageButton.LastError
; Image button with different 3D-style colors for states normal, hot, and disabled -------------------------------------
Gui, Add, Button, vBT3 w200 Disabled hwndHBT3, Button 3
Opt1 := [[0x404040, 0xC0C0C0, 3], "Yellow"]  ; normal 3D-style background & text colors
Opt2 := [[0x606060, 0xF0F0F0, 3], 0x606000]  ; hot 3D-style background & text colors
Opt4 := [0xA0A0A0, 0x606000]                 ; disabled flat background & text colors
If !ImageButton.Create(HBT3, Opt1, Opt2, , Opt4)
   MsgBox, 0, ImageButton Error Btn3, % ImageButton.LastError
Gui, Font
Gui, Add, CheckBox, xp y+0 w200 gCheck vCheckBox, Enable!
; Image button without caption with different pictures for states normal and hot ---------------------------------------
Gui, Add, Button, vBT4 w200 h30 hwndHBT4
Opt1 := ["PIC1.jpg"]                         ; normal image
Opt2 := ["PIC2.jpg"]                         ; hot image
If !ImageButton.Create(HBT4, Opt1, Opt2)
   MsgBox, 0, ImageButton Error Btn4, % ImageButton.LastError
GuiControl, Focus, BT2
Gui, Show, , Image Buttons
Return
; ----------------------------------------------------------------------------------------------------------------------
GuiClose:
GuiEscape:
ExitApp
; ----------------------------------------------------------------------------------------------------------------------
Check:
   GuiControlGet, CheckBox
   GuiControl, Enable%CheckBox%, BT3
   GuiControl, Text, CheckBox, % (CheckBox ? "Disable!" : "Enable!")
Return
