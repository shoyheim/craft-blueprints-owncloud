; Copyright 2010 Patrick Spendrin <ps_ml@gmx.de>
; Copyright 2016 Kevin Funk <kfunk@kde.org>
; Copyright Hannah von Reth <vonreth@kde.org>
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions
; are met:
; 1. Redistributions of source code must retain the above copyright
;    notice, this list of conditions and the following disclaimer.
; 2. Redistributions in binary form must reproduce the above copyright
;    notice, this list of conditions and the following disclaimer in the
;    documentation and/or other materials provided with the distribution.
;
; THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
; ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
; ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
; OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
; HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
; LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
; OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
; SUCH DAMAGE.

; registry stuff
!define regkey "Software\@{company}\@{productname}"
!define uninstkey "Software\Microsoft\Windows\CurrentVersion\Uninstall\@{productname}"
!define runPath "Software\Microsoft\Windows\CurrentVersion\Run"

BrandingText "Published by Serit Fjordane IT"

;--------------------------------

XPStyle on
ManifestDPIAware true


Name "@{productname}"
Caption "@{productname}" ; @{version}"

OutFile "@{setupname}"

!define MULTIUSER_EXECUTIONLEVEL Highest
!define MULTIUSER_MUI
!define MULTIUSER_INSTALLMODE_COMMANDLINE
!define MULTIUSER_INSTALLMODE_DEFAULT_REGISTRY_KEY "${regkey}"
!define MULTIUSER_INSTALLMODE_DEFAULT_REGISTRY_VALUENAME "Install_Mode"
!define MULTIUSER_INSTALLMODE_INSTDIR "@{productname}"
!define MULTIUSER_INSTALLMODE_INSTDIR_REGISTRY_KEY "${regkey}"
!define MULTIUSER_INSTALLMODE_INSTDIR_REGISTRY_VALUENAME "Install_Dir"

;Start Menu Folder Page Configuration
Var StartMenuFolder
!define MUI_STARTMENUPAGE_REGISTRY_ROOT "SHCTX"
!define MUI_STARTMENUPAGE_REGISTRY_KEY "${regkey}"
!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "Start Menu Folder"

;!define MULTIUSER_USE_PROGRAMFILES64
@{multiuser_use_programfiles64}
;!define MULTIUSER_USE_PROGRAMFILES64

@{nsis_include_internal}
@{nsis_include}

!include "MultiUser.nsh"
!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "x64.nsh"
!include "process.nsh"


;!define MUI_ICON
@{installerIcon}
;!define MUI_ICON

!insertmacro MUI_PAGE_WELCOME
;!insertmacro MUI_PAGE_LICENSE
@{license}
;!insertmacro MUI_PAGE_LICENSE

;!insertmacro MUI_FINISHPAGE_SHOWREADME
@{readme}
;!insertmacro MUI_FINISHPAGE_SHOWREADME

!insertmacro MULTIUSER_PAGE_INSTALLMODE

!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_STARTMENU Application $StartMenuFolder

!define MUI_COMPONENTSPAGE_NODESC
;!insertmacro MUI_PAGE_COMPONENTS
@{sections_page}
;!insertmacro MUI_PAGE_COMPONENTS

!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT "Run @{productname}"
!define MUI_FINISHPAGE_RUN_FUNCTION "StartSkylagring"
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_LANGUAGE "English"

SetDateSave on
SetDatablockOptimize on
CRCCheck on
SilentInstall normal

Function .onInit
    !insertmacro MULTIUSER_INIT
    !if "@{architecture}" == "x64"
        ${IfNot} ${RunningX64}
            MessageBox MB_OK|MB_ICONEXCLAMATION "This installer can only be run on 64-bit Windows."
            Abort
        ${EndIf}
    !endif
	
;	ReadRegStr $0 HKLM "${uninstkey}" "InstallLocation"
;	${If} $0 == ""
;		ReadRegStr $0 HKLM "${uninstkey32}" "InstallLocation"
;  	${Endif}
;	${If} $0 == ""
;	  MessageBox MB_OK|MB_ICONEXCLAMATION "Found no previous installation location at ${uninstkey}, result: $0"
;	${Else}
;	  StrCpy $INSTDIR $0
;	  MessageBox MB_OK|MB_ICONEXCLAMATION "Found previous installation location $0 at ${uninstkey}"
;	${Endif}
FunctionEnd

Function .onInstSuccess
	${If} ${Silent}
		Call StartSkylagring
FunctionEnd
	
Function StartSkylagring
    	ExecShell "" "$INSTDIR\@{appname}.exe"
FunctionEnd

Function un.onInit
    !insertmacro MULTIUSER_UNINIT
FunctionEnd

;--------------------------------

AutoCloseWindow false

!macro UninstallExisting exitcode uninstcommand
Push `${uninstcommand}`
Call UninstallExisting
Pop ${exitcode}
!macroend
Function UninstallExisting
Exch $1 ; uninstcommand
Push $2 ; Uninstaller
Push $3 ; Len
StrCpy $3 ""
StrCpy $2 $1 1
StrCmp $2 '"' qloop sloop
sloop:
	StrCpy $2 $1 1 $3
	IntOp $3 $3 + 1
	StrCmp $2 "" +2
	;StrCmp $2 ' ' 0 sloop
	IntOp $3 $3 - 1
	Goto run
qloop:
	StrCmp $3 "" 0 +2
	StrCpy $1 $1 "" 1 ; Remove initial quote
	IntOp $3 $3 + 1
	StrCpy $2 $1 1 $3
	StrCmp $2 "" +2
	StrCmp $2 '"' 0 qloop
run:
	StrCpy $2 $1 $3 ; Path to uninstaller
	StrCpy $1 161 ; ERROR_BAD_PATHNAME
	GetFullPathName $3 "$2\.." ; $InstDir
	IfFileExists "$2" 0 +4
	ExecWait '"$2" /S _?=$3' $1 ; This assumes the existing uninstaller is a NSIS uninstaller, other uninstallers don't support /S nor _?=
	IntCmp $1 0 "" +2 +2 ; Don't delete the installer if it was aborted
	Delete "$2" ; Delete the uninstaller
	RMDir "$3" ; Try to delete $InstDir
	RMDir "$3\.." ; (Optional) Try to delete the parent of $InstDir
Pop $3
Pop $2
Exch $1 ; exitcode
FunctionEnd


; beginning (invisible) section
Section
  !insertmacro EndProcessWithDialog
  
			
  ReadRegStr $0 HKLM "${uninstkey}" "UninstallString"
  !if "@{architecture}" == "x64"
  	${If} $0 == ""
		SetRegView 32
		ReadRegStr $0 HKLM "${uninstkey}" "UninstallString"
		SetRegView 64
  	${Endif}
  !endif
  ${If} $0 == ""
	StrCpy $0 "$INSTDIR\uninstall.exe"
  ${Endif}
  
  !insertmacro UninstallExisting $0 $0
	${IfNot} ${Silent} ${AndIf} $0 <> 0
		MessageBox MB_YESNO|MB_ICONSTOP "Failed to uninstall old version, continue anyway? Error: $0" /SD IDYES IDYES +2
			Abort
	${EndIf}
  ;ExecWait '"$MultiUser.InstDir\uninstall.exe" /S _?=$MultiUser.InstDir'
  ;ExecWait '"$MultiUser.InstDir\uninstall.exe"'
  @{preInstallHook}
  WriteRegStr SHCTX "${regkey}" "Install_Dir" "$INSTDIR"
  WriteRegStr SHCTX "${MULTIUSER_INSTALLMODE_INSTDIR_REGISTRY_KEY}" "${MULTIUSER_INSTALLMODE_DEFAULT_REGISTRY_VALUENAME}" "$MultiUser.InstallMode"
  ; write uninstall strings
  WriteRegStr SHCTX "${uninstkey}" "DisplayName" "@{productname}"
  WriteRegStr SHCTX "${uninstkey}" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegStr SHCTX "${uninstkey}" "DisplayIcon" "$INSTDIR\@{iconname}"
  WriteRegStr SHCTX "${uninstkey}" "URLInfoAbout" "@{website}"
  WriteRegStr SHCTX "${uninstkey}" "Publisher" "@{company}"
  WriteRegStr SHCTX "${uninstkey}" "DisplayVersion" "@{version}"
  WriteRegDWORD SHCTX "${uninstkey}" "EstimatedSize" "@{estimated_size}"
  
  WriteRegStr HKCU "${runPath}" "@{appname}" "$INSTDIR\@{appname}.exe"

  @{registry_hook}

  SetOutPath $INSTDIR


; package all files, recursively, preserving attributes
; assume files are in the correct places

File /a "@{dataPath}"
File /a "@{7za}"
File /a "@{icon}"
!if "@{architecture}" == "x64"
	nsExec::ExecToLog '"$INSTDIR\7za.exe" x -r -y "$INSTDIR\@{dataName}" -o"$INSTDIR"'
!else
	nsExec::ExecToLog '"$INSTDIR\7za_32.exe" x -r -y "$INSTDIR\@{dataName}" -o"$INSTDIR"'
!endif
Pop $0
Pop $1
${If} $0 == "error"	
	MessageBox MB_OK|MB_ICONEXCLAMATION "Unpacking failed using $INSTDIR. Installation failure. $1"
	Abort
${ElseIf} $0 == "timout"
	MessageBox MB_OK|MB_ICONEXCLAMATION "Unpacking timed out. Installation failure. $1"
	Abort
${Else}
	!if "@{architecture}" == "x64"
		Delete "$INSTDIR\7za.exe"
	!else
		Delete "$INSTDIR\7za_32.exe"
	!endif
	Delete "$INSTDIR\@{dataName}"
${Endif}

AddSize @{installSize}

WriteUninstaller "uninstall.exe"

SectionEnd

; create shortcuts
@{shortcuts}

;  allow to define additional sections
@{sections}


; Uninstaller
; All section names prefixed by "Un" will be in the uninstaller

UninstallText "This will uninstall @{productname}."

Section "Uninstall"
!insertmacro EndProcessWithDialog

DeleteRegKey SHCTX "${uninstkey}"
DeleteRegKey SHCTX "${regkey}"

!insertmacro MUI_STARTMENU_GETFOLDER Application $StartMenuFolder
RMDir /r "$SMPROGRAMS\$StartMenuFolder"

@{uninstallFiles}
@{uninstallDirs}

SectionEnd

;  allow to define additional Un.sections
@{un_sections}
