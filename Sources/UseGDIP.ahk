UseGDIP(Params*) { ; Loads and initializes the Gdiplus.dll at load-time
   ; GET_MODULE_HANDLE_EX_FLAG_PIN = 0x00000001
   Static GdipObject := ""
        , GdipModule := ""
        , GdipToken  := ""
   Static OnLoad := UseGDIP()
   If (GdipModule = "") {
      If !DllCall("LoadLibrary", "Str", "Gdiplus.dll", "UPtr")
         UseGDIP_Error("The Gdiplus.dll could not be loaded!`n`nThe program will exit!")
      If !DllCall("GetModuleHandleEx", "UInt", 0x00000001, "Str", "Gdiplus.dll", "PtrP", GdipModule, "UInt")
         UseGDIP_Error("The Gdiplus.dll could not be loaded!`n`nThe program will exit!")
      VarSetCapacity(SI, 24, 0), NumPut(1, SI, 0, "UInt") ; size of 64-bit structure
      If DllCall("Gdiplus.dll\GdiplusStartup", "PtrP", GdipToken, "Ptr", &SI, "Ptr", 0)
         UseGDIP_Error("GDI+ could not be startet!`n`nThe program will exit!")
      GdipObject := {Base: {__Delete: Func("UseGDIP").Bind(GdipModule, GdipToken)}}
   }
   Else If (Params[1] = GdipModule) && (Params[2] = GdipToken)
      DllCall("Gdiplus.dll\GdiplusShutdown", "Ptr", GdipToken)
}
UseGDIP_Error(ErrorMsg) {
   MsgBox, 262160, UseGDIP, %ErrorMsg%
   ExitApp
}