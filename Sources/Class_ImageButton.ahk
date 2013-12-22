; ======================================================================================================================
; Namespace:         ImageButton
; Function:          Create images and assign them pushbuttons.
; AHK version:       1.1.13.01 (A32/U32/U64)
; Tested on:         Win 7 (x64)
; Version:           1.0.00.00/2013-12-21/just me
; How to use:
;     1. Create a push button (e.g. "Gui, Add, Button, vMyButton hwndHwndButton, Caption") using the 'Hwnd' option
;        to get its HWND.
;     2. Call ImageButton.Create() passing three parameters:
;        HWND        -  Button's HWND.
;        Margins     -  Distance to the button's borders in pixels.
;                       Valid values:  0, 1, 2, 3, 4
;                       Default value: 0
;        Options*    -  variadic array containing up to 6 option arrays (see below).
;        ---------------------------------------------------------------------------------------------------------------
;        The index of each option object determines the corresponding button state on which the bitmap will be shown.
;        MSDN defines 6 states (http://msdn.microsoft.com/en-us/windows/bb775975):
;           PBS_NORMAL    = 1
;	         PBS_HOT       = 2
;	         PBS_PRESSED   = 3
;	         PBS_DISABLED  = 4
;	         PBS_DEFAULTED = 5
;	         PBS_STYLUSHOT = 6 <- used only on tablet computers
;        If you don't want the button to be 'animated' on themed GUIs, just pass one option object with index 1.
;        ---------------------------------------------------------------------------------------------------------------
;        Each option array may contain the following values:
;           1. Background  -  mandatory for index 1, higher indices will use the value of index 1, if omitted.
;                             Unichrome:
;                             -  RGB integer value (0xRRGGBB) or HTML color name ("Red").
;                             Bitmap:
;                             -  Path of an image file or HBITMAP handle
;                             3D-styled:
;                             -  Array containing three values:
;                                1. Outer color as RGB integer value (0xRRGGBB) or HTML color name ("Red").
;                                2. Inner color as RGB integer value (0xRRGGBB) or HTML color name ("Red").
;                                3. Mode: 1 = raised, 2 = horizontal gradient, 3 = vertical gradient
;           2. TextColor   -  optional, if omitted, the default color will be used for index 1, higher indices will
;                             use the color of index 1.
;                             -  RGB integer value (0xRRGGBB) or HTML color name ("Red").
;                                Default: 0x000000 (black)
;        ---------------------------------------------------------------------------------------------------------------
;        If the the button has a caption it will be drawn above the bitmap.
; Credits:           THX tic     for GDIP.AHK     : http://www.autohotkey.com/forum/post-198949.html
;                    THX tkoi    for ILBUTTON.AHK : http://www.autohotkey.com/forum/topic40468.html
; ======================================================================================================================
; This software is provided 'as-is', without any express or implied warranty.
; In no event will the authors be held liable for any damages arising from the use of this software.
; ======================================================================================================================
; ======================================================================================================================
; CLASS CreateImageButton()
; ======================================================================================================================
Class ImageButton {
   ; ===================================================================================================================
   ; PRIVATE PROPERTIES ================================================================================================
   ; ===================================================================================================================
   Static BitMaps := []
   Static GDIPDll := 0
   Static GDIPToken := 0
   ; HTML colors
   Static HTML := {BLACK: 0x000000, GRAY: 0x808080, SILVER: 0xC0C0C0, WHITE: 0xFFFFFF, MAROON: 0x800000
                 , PURPLE: 0x800080, FUCHSIA: 0xFF00FF, RED: 0xFF0000, GREEN: 0x008000, OLIVE: 0x808000
                 , YELLOW: 0xFFFF00, LIME: 0x00FF00, NAVY: 0x000080, TEAL: 0x008080, AQUA: 0x00FFFF, BLUE: 0x0000FF}
   ; ===================================================================================================================
   ; PUBLIC PROPERTIES =================================================================================================
   ; ===================================================================================================================
   Static DefTextColor := "Black"   ; default caption color                         (read/write)
   Static LastError := ""           ; will contain the last error message, if any   (readonly)
   ; ===================================================================================================================
   ; PRIVATE METHODS ===================================================================================================
   ; ===================================================================================================================
   __New(P*) {
      Return False
   }
   ; ===================================================================================================================
   GdiplusStartup() {
      This.GDIPDll := This.GDIPToken := 0
      If (This.GDIPDll := DllCall("Kernel32.dll\LoadLibrary", "Str", "Gdiplus.dll", "Ptr")) {
         VarSetCapacity(SI, 24, 0)
         Numput(1, SI, 0, "Int")
         If !DllCall("Gdiplus.dll\GdiplusStartup", "PtrP", GDIPToken, "Ptr", &SI, "Ptr", 0)
            This.GDIPToken := GDIPToken
         Else
            This.GdiplusShutdown()
      }
      Return This.GDIPToken
   }
   ; ===================================================================================================================
   GdiplusShutdown() {
      If This.GDIPToken
         DllCall("Gdiplus.dll\GdiplusShutdown", "Ptr", This.GDIPToken)
      If This.GDIPDll
         DllCall("Kernel32.dll\FreeLibrary", "Ptr", This.GDIPDll)
      This.GDIPDll := This.GDIPToken := 0
   }
   ; ===================================================================================================================
   CheckOption(Index, ByRef Option) {
      Static OBJ_BITMAP := 7
      If (Index = 1) {
         If !Option.HasKey(1)
            Return This.SetError("Missing value for background in Options[" . Index . "]!")
         If !Option.HasKey(2)
            Option.2 := This.DefTextColor
      }
      If IsObject(Option.1) {
         If (Option.1.1 = "") || (!(Option.1.1 + 0) && !This.HTML.HasKey(Option.1.1))
            Return This.SetError("Invalid value for background 1 in Options[" . Index . "]!")
         If (Option.1.2 = "") || (!(Option.1.2 + 0) && !This.HTML.HasKey(Option.1.2))
            Return This.SetError("Invalid value for background 2 in Options[" . Index . "]!")
         If (Option.1.3 = "") || !InStr("123", SubStr(Option.1.3, 1, 1))
            Return This.SetError("Invalid value for background 3 in Options[" . Index . "]!")
      }
      Else If (Option.1 <> "") {
         If !(Option.1 + 0) && !This.HTML.HasKey(Option.1) && !FileExist(Option.1)
            Return This.SetError("Invalid value for background in Options[" . Index . "]!")
      }
      If (Option.2 <> "") {
         If !(Option.2 + 0) && !This.HTML.HasKey(Option.2)
            Return This.SetError("Invalid value for text color in Options[" . Index . "]!")
      }
      Return True
   }
   ; ===================================================================================================================
   FreeBitmaps() {
      For I, HBITMAP In This.BitMaps
         DllCall("Gdi32.dll\DeleteObject", "Ptr", HBITMAP)
      This.BitMaps := []
   }
   ; ===================================================================================================================
   SetError(Msg) {
      This.FreeBitmaps()
      This.GdiplusShutdown()
      This.LastError := Msg
      Return False
   }
   ; ===================================================================================================================
   ; PUBLIC METHODS ====================================================================================================
   ; ===================================================================================================================
   Create(HWND, Options*) {
      ; Windows constants
      Static BCM_SETIMAGELIST := 0x1602
           , BS_CHECKBOX := 0x02, BS_RADIOBUTTON := 0x04, BS_GROUPBOX := 0x07, BS_AUTORADIOBUTTON := 0x09
           , BS_LEFT := 0x0100, BS_RIGHT := 0x0200, BS_CENTER := 0x0300, BS_TOP := 0x0400, BS_BOTTOM := 0x0800
           , BS_VCENTER := 0x0C00, BS_BITMAP := 0x0080
           , BUTTON_IMAGELIST_ALIGN_LEFT := 0, BUTTON_IMAGELIST_ALIGN_RIGHT := 1, BUTTON_IMAGELIST_ALIGN_CENTER := 4
           , ILC_COLOR32 := 0x20
           , OBJ_BITMAP := 7
           , RCBUTTONS := BS_CHECKBOX | BS_RADIOBUTTON | BS_AUTORADIOBUTTON
           , SA_LEFT := 0x00, SA_CENTER := 0x01, SA_RIGHT := 0x02
           , WM_GETFONT := 0x31
      ; ----------------------------------------------------------------------------------------------------------------
      This.LastError := ""
      Margins := 0
      ; ----------------------------------------------------------------------------------------------------------------
      ; Check HWND
      If !DllCall("User32.dll\IsWindow", "Ptr", HWND)
         Return This.SetError("Invalid parameter HWND!")
      ; ----------------------------------------------------------------------------------------------------------------
      ; Check Options
      If !(IsObject(Options)) || (Options.MinIndex() <> 1) || (Options.MaxIndex() > 6)
         Return This.SetError("Invalid parameter Options!")
      For Index In Options {
         If !This.CheckOption(Index, Options[Index])
            Return False
      }
      ; ----------------------------------------------------------------------------------------------------------------
      ; Get and check control's class and styles
      WinGetClass, BtnClass, ahk_id %HWND%
      ControlGet, BtnStyle, Style, , , ahk_id %HWND%
      If (BtnClass != "Button") || ((BtnStyle & 0xF ^ BS_GROUPBOX) = 0) || ((BtnStyle & RCBUTTONS) > 1)
         Return This.SetError("The control must be a pushbutton!")
      ; ----------------------------------------------------------------------------------------------------------------
      ; Load GdiPlus
      If !This.GdiplusStartup()
         Return This.SetError("GDIPlus could not be started!")
      ; ----------------------------------------------------------------------------------------------------------------
      ; Get the button's font
      GDIPFont := 0
      HFONT := DllCall("User32.dll\SendMessage", "Ptr", HWND, "UInt", WM_GETFONT, "Ptr", 0, "Ptr", 0, "Ptr")
      DC := DllCall("User32.dll\GetDC", "Ptr", HWND, "Ptr")
      DllCall("Gdi32.dll\SelectObject", "Ptr", DC, "Ptr", HFONT)
      DllCall("Gdiplus.dll\GdipCreateFontFromDC", "Ptr", DC, "PtrP", GDIPFont)
      DllCall("User32.dll\ReleaseDC", "Ptr", HWND, "Ptr", DC)
      If !(GDIPFont)
         Return This.SetError("Couldn't get button's font!")
      ; ----------------------------------------------------------------------------------------------------------------
      ; Get the button's rectangle
      VarSetCapacity(RECT, 16, 0)
      If !DllCall("User32.dll\GetWindowRect", "Ptr", HWND, "Ptr", &RECT)
         Return This.SetError("Couldn't get button's rectangle!")
      BtnW := NumGet(RECT,  8, "Int") - NumGet(RECT, 0, "Int") - (Margins * 2)
      BtnH := NumGet(RECT, 12, "Int") - NumGet(RECT, 4, "Int") - (Margins * 2)
      ; ----------------------------------------------------------------------------------------------------------------
      ; Get the button's caption
      ControlGetText, BtnCaption, , ahk_id %HWND%
      If (ErrorLevel)
         Return This.SetError("Couldn't get button's caption!")
      ; ----------------------------------------------------------------------------------------------------------------
      ; Create the BitMap(s)
      This.BitMaps := []
      For Index, Option In Options {
         ; Check option
         BkgColor1 := BkgColor2 := Gradient := Image := ""
         If (Option.1 = "")
            Option.1 := Options.1.1
         If (Option.2 = "")
            Option.2 := Options.1.2
         If IsObject(Option.1) {
            BkgColor1 := Option.1.1
            BkgColor2 := Option.1.2
            Gradient := SubStr(Option.1.3, 1, 1)
         }
         Else If FileExist(Option.1)
            Image := Option.1
         Else If (DllCall("Gdi32.dll\GetObjectType", "Ptr", Option.1, "UInt") = OBJ_BITMAP)
            Image := Option.1
         Else {
            BkgColor1 := Option.1
            BkgColor2 := Option.1
            Gradient := 0
         }
         If This.HTML.HasKey(BkgColor1)
            BkgColor1 := This.HTML[BkgColor1]
         If This.HTML.HasKey(BkgColor2)
            BkgColor2 := This.HTML[BkgColor2]
         TxtColor := Option.2
         If This.HTML.HasKey(TxtColor)
            TxtColor := This.HTML[TxtColor]
         ; -------------------------------------------------------------------------------------------------------------
         ; Create a GDI+ bitmap
         DllCall("Gdiplus.dll\GdipCreateBitmapFromScan0", "Int", BtnW, "Int", BtnH, "Int", 0
               , "UInt", 0x26200A, "Ptr", 0, "PtrP", PBITMAP)
         ; Get the pointer to it's graphics
         DllCall("Gdiplus.dll\GdipGetImageGraphicsContext", "Ptr", PBITMAP, "PtrP", PGRAPHICS)
         ; Set SmoothingMode to system default
         DllCall("Gdiplus.dll\GdipSetSmoothingMode", "Ptr", PGRAPHICS, "UInt", 0)
         If (Image = "") { ; Create a BitMap for the passed colors
            ; Start and target colors
            Color1 := 0xFF000000 | (BkgColor1 & 0x00FFFFFF)
            Color2 := 0xFF000000 | (BkgColor2 & 0x00FFFFFF)
            If (Color1 = Color2) { ; Create a solid brush
               DllCall("Gdiplus.dll\GdipCreateSolidFill", "UInt", Color1, "PtrP", PBRUSH)
            } Else { ; Create a PathGradientBrush
               VarSetCapacity(POINTS, 4 * 8, 0)
               NumPut(BtnW - 1, POINTS,  8, "UInt"), NumPut(BtnW - 1, POINTS, 16, "UInt")
               NumPut(BtnH - 1, POINTS, 20, "UInt"), NumPut(BtnH - 1, POINTS, 28, "UInt")
               DllCall("Gdiplus.dll\GdipCreatePathGradientI", "Ptr", &POINTS, "Int", 4, "Int", 0, "PtrP", PBRUSH)
               ; Set the PresetBlend
               VarSetCapacity(COLORS, 12, 0)
               NumPut(Color1, COLORS, 0, "UInt"), NumPut(Color2, COLORS, 4, "UInt")
               VarSetCapacity(RELINT, 12, 0)
               NumPut(0.00, RELINT, 0, "Float"), NumPut(1.00, RELINT, 4, "Float")
               DllCall("Gdiplus.dll\GdipSetPathGradientPresetBlend"
                     , "Ptr", PBRUSH, "Ptr", &COLORS, "Ptr", &RELINT, "Int", 2)
               ; Set the FocusScales
               DH := BtnH / 2
               XScale := (Gradient = 1 ? (BtnW - DH) / BtnW : Gradient = 2 ? 1 : 0)
               YScale := (Gradient = 1 ? (BtnH - DH) / BtnH : Gradient = 3 ? 1 : 0)
               DllCall("Gdiplus.dll\GdipSetPathGradientFocusScales", "Ptr", PBRUSH, "Float", XScale, "Float", YScale)
            }
            ; Fill the button's rectangle
            DllCall("Gdiplus.dll\GdipFillRectangleI", "Ptr", PGRAPHICS, "Ptr", PBRUSH, "Int", 0, "Int", 0
                  , "Int", BtnW, "Int", BtnH)
            ; Free the brush
            DllCall("Gdiplus.dll\GdipDeleteBrush", "Ptr", PBRUSH)
         } Else { ; Create a bitmap from HBITMAP or file
            If (Image + 0)
               DllCall("Gdiplus.dll\GdipCreateBitmapFromHBITMAP", "Ptr", Image, "Ptr", 0, "PtrP", PBM)
            Else
               DllCall("Gdiplus.dll\GdipCreateBitmapFromFile", "WStr", Image, "PtrP", PBM)
            ; Draw the bitmap
            DllCall("Gdiplus.dll\GdipDrawImageRectI", "Ptr", PGRAPHICS, "Ptr", PBM, "Int", 0, "Int", 0
                  , "Int", BtnW, "Int", BtnH)
            ; Free the bitmap
            DllCall("Gdiplus.dll\GdipDisposeImage", "Ptr", PBM)
         }
         ; -------------------------------------------------------------------------------------------------------------
         ; Draw the caption
         If (BtnCaption) {
            ; Create a StringFormat object
            DllCall("Gdiplus.dll\GdipCreateStringFormat", "Int", 0x5404, "UInt", 0, "PtrP", HFORMAT)
            ; Text color
            TxtColor := 0xFF000000 | (TxtColor & 0x00FFFFFF)
            DllCall("Gdiplus.dll\GdipCreateSolidFill", "UInt", TxtColor, "PtrP", PBRUSH)
            ; Horizontal alignment
            HALIGN := (BtnStyle & BS_CENTER) = BS_CENTER ? SA_CENTER
                    : (BtnStyle & BS_CENTER) = BS_RIGHT  ? SA_RIGHT
                    : (BtnStyle & BS_CENTER) = BS_Left   ? SA_LEFT
                    : SA_CENTER
            DllCall("Gdiplus.dll\GdipSetStringFormatAlign", "Ptr", HFORMAT, "Int", HALIGN)
            ; Vertical alignment
            VALIGN := (BtnStyle & BS_VCENTER) = BS_TOP ? 0
                    : (BtnStyle & BS_VCENTER) = BS_BOTTOM ? 2
                    : 1
            DllCall("Gdiplus.dll\GdipSetStringFormatLineAlign", "Ptr", HFORMAT, "Int", VALIGN)
            ; Set render quality to system default
            DllCall("Gdiplus.dll\GdipSetTextRenderingHint", "Ptr", PGRAPHICS, "Int", 0)
            ; Set the text's rectangle
            NumPut(0.0,  RECT,  0, "Float")
            NumPut(0.0,  RECT,  4, "Float")
            NumPut(BtnW, RECT,  8, "Float")
            NumPut(BtnH, RECT, 12, "Float")
            ; Draw the text
            DllCall("Gdiplus.dll\GdipDrawString", "Ptr", PGRAPHICS, "WStr", BtnCaption, "Int", -1
                  , "Ptr", GDIPFont, "Ptr", &RECT, "Ptr", HFORMAT, "Ptr", PBRUSH)
         }
         ; Create a HBITMAP handle from the bitmap
         DllCall("Gdiplus.dll\GdipCreateHBITMAPFromBitmap", "Ptr", PBITMAP, "PtrP", HBITMAP, "UInt", 0X00FFFFFF)
         ; Free resources
         DllCall("Gdiplus.dll\GdipDisposeImage", "Ptr", PBITMAP)
         DllCall("Gdiplus.dll\GdipDeleteBrush", "Ptr", PBRUSH)
         DllCall("Gdiplus.dll\GdipDeleteStringFormat", "Ptr", HFORMAT)
         DllCall("Gdiplus.dll\GdipDeleteGraphics", "Ptr", PGRAPHICS)
         This.BitMaps[Index] := HBITMAP
      }
      ; Now free the font object
      DllCall("Gdiplus.dll\GdipDeleteFont", "Ptr", GDIPFont)
      ; ----------------------------------------------------------------------------------------------------------------
      ; Create the ImageList
      HIL := DllCall("Comctl32.dll\ImageList_Create"
                   , "UInt", BtnW, "UInt", BtnH, "UInt", ILC_COLOR32, "Int", 6, "Int", 0, "Ptr")
      Loop, % (This.BitMaps.MaxIndex() > 1 ? 6 : 1) {
         HBITMAP := This.BitMaps.HasKey(A_Index) ? This.BitMaps[A_Index] : This.BitMaps.1
         DllCall("Comctl32.dll\ImageList_Add", "Ptr", HIL, "Ptr", HBITMAP, "Ptr", 0)
      }
      ; Create a BUTTON_IMAGELIST structure
      VarSetCapacity(BIL, 20 + A_PtrSize, 0)
      NumPut(HIL, BIL, 0, "Ptr")
      Numput(BUTTON_IMAGELIST_ALIGN_CENTER, BIL, A_PtrSize + 16, "UInt")
      ; Hide buttons's caption
      ControlSetText, , , ahk_id %HWND%
      Control, Style, +%BS_BITMAP%, , ahk_id %HWND%
      ; Assign the ImageList to the button
      SendMessage, %BCM_SETIMAGELIST%, 0, 0, , ahk_id %HWND%
      SendMessage, %BCM_SETIMAGELIST%, 0, % &BIL, , ahk_id %HWND%
      ; Free the bitmaps
      This.FreeBitmaps()
      ; ----------------------------------------------------------------------------------------------------------------
      ; All done successfully
      This.GdiplusShutdown()
      Return True
   }
}