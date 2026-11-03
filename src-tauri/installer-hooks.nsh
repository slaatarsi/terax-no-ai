; "Open in Terax" shell verbs for folders, folder backgrounds, and drives.
; HKCU matches installer currentUser scope. %V = clicked path.
; NoWorkingDirectory keeps Explorer from overriding %V (System32 on Drive).

!macro TERAX_SHELL ACTION
  Push $0
  Push $1
  StrCpy $0 "$WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
  IfFileExists "$WINDIR\Sysnative\WindowsPowerShell\v1.0\powershell.exe" 0 +2
    StrCpy $0 "$WINDIR\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
  nsExec::ExecToLog '$\"$0$\" -NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File $\"$INSTDIR\shell-extension\install.ps1$\" -Action ${ACTION} -InstallDir $\"$INSTDIR$\"'
  Pop $1
  DetailPrint "Terax Explorer registration (${ACTION}): $1. See %LOCALAPPDATA%\Terax\shell-integration.log."
  !if "${ACTION}" == "Uninstall"
    ${If} $1 != "0"
      IfSilent +2
        MessageBox MB_OK|MB_ICONEXCLAMATION "Explorer integration could not be removed. Close Terax and try uninstalling again. See %LOCALAPPDATA%\Terax\shell-integration.log."
      Pop $1
      Pop $0
      SetErrorLevel 1
      Abort
    ${EndIf}
  !endif
  Pop $1
  Pop $0
!macroend

!macro TERAX_REMOVE_OWN_LEGACY KEY
  Push $0
  ReadRegStr $0 HKCU "Software\Classes\${KEY}\shell\OpenInTerax\command" ""
  ${If} $0 == '"$INSTDIR\terax.exe" --open-directory "%V"'
  ${OrIf} $0 == '"$INSTDIR\terax.exe" "%V"'
    DeleteRegKey HKCU "Software\Classes\${KEY}\shell\OpenInTerax"
  ${EndIf}
  Pop $0
!macroend

!macro NSIS_HOOK_POSTINSTALL
  WriteRegStr HKCU "Software\Classes\Directory\shell\OpenInTerax" "" "Open in Terax"
  WriteRegStr HKCU "Software\Classes\Directory\shell\OpenInTerax" "Icon" '"$INSTDIR\terax.exe",0'
  WriteRegStr HKCU "Software\Classes\Directory\shell\OpenInTerax" "NoWorkingDirectory" ""
  WriteRegStr HKCU "Software\Classes\Directory\shell\OpenInTerax\command" "" '"$INSTDIR\terax.exe" --open-directory "%V"'

  WriteRegStr HKCU "Software\Classes\Directory\Background\shell\OpenInTerax" "" "Open in Terax"
  WriteRegStr HKCU "Software\Classes\Directory\Background\shell\OpenInTerax" "Icon" '"$INSTDIR\terax.exe",0'
  WriteRegStr HKCU "Software\Classes\Directory\Background\shell\OpenInTerax" "NoWorkingDirectory" ""
  WriteRegStr HKCU "Software\Classes\Directory\Background\shell\OpenInTerax\command" "" '"$INSTDIR\terax.exe" --open-directory "%V"'

  WriteRegStr HKCU "Software\Classes\Drive\shell\OpenInTerax" "" "Open in Terax"
  WriteRegStr HKCU "Software\Classes\Drive\shell\OpenInTerax" "Icon" '"$INSTDIR\terax.exe",0'
  WriteRegStr HKCU "Software\Classes\Drive\shell\OpenInTerax" "NoWorkingDirectory" ""
  WriteRegStr HKCU "Software\Classes\Drive\shell\OpenInTerax\command" "" '"$INSTDIR\terax.exe" --open-directory "%V"'
  !insertmacro TERAX_SHELL Install
!macroend

!macro NSIS_HOOK_PREUNINSTALL
  ${If} $UpdateMode <> 1
    Push $0
    ReadRegStr $0 HKCU "Software\Crynta\Terax\Explorer" "InstallDir"
    ${If} $0 == "$INSTDIR"
      Pop $0
      ; Tauri's check runs after this hook; confirm closure before unregistering.
      !insertmacro CheckIfAppIsRunning "$INSTDIR\${MAINBINARYNAME}.exe" "${PRODUCTNAME}"
      !insertmacro TERAX_SHELL Uninstall
    ${Else}
      Pop $0
    ${EndIf}
  ${EndIf}
!macroend

!macro NSIS_HOOK_POSTUNINSTALL
  ${If} $UpdateMode <> 1
    !insertmacro TERAX_REMOVE_OWN_LEGACY "Directory"
    !insertmacro TERAX_REMOVE_OWN_LEGACY "Directory\Background"
    !insertmacro TERAX_REMOVE_OWN_LEGACY "Drive"
    RMDir /r /REBOOTOK "$INSTDIR\shell-extension"
  ${EndIf}
!macroend
