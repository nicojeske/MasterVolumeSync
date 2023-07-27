; setup.nsi
;
; Basic installer script for a .NET 6 application

!include "MUI2.nsh"
!include "FileFunc.nsh"

; The architecture is passed as a define from the GitHub Action
!ifndef ARCH
    !error "ARCH is not defined"
!endif


; Based on the architecture, we set the publish directory and the output file
!if ${ARCH} == "x64"
    !define PUBLISHDIR "publish/x64"
    !define OUTFILE "setup-x64.exe"
    !define APPDIR "$PROGRAMFILES64"
!else
    !define PUBLISHDIR "publish/x86"
    !define OUTFILE "setup-x86.exe"
    !define APPDIR "$PROGRAMFILES"
!endif

;--------------------------------
; Custom defines
!define APPNAME "MasterVolumeSync"
!define COMPANYNAME "Nico Jeske IT"
!define DESCRIPTION "Sync Volume to Soundblaster Cards"
!define APPEXE "MasterVolumeSync.exe"
!define DLL "MasterVolumeSync.dll"

# These will be displayed by the "Click here for support information" link in "Add/Remove Programs"
# It is possible to use "mailto:" links in here to open the email client
!define HELPURL "https://github.com/nicojeske/MasterVolumeSync" # "Support Information" link
!define UPDATEURL "https://github.com/nicojeske/MasterVolumeSync" # "Product Updates" link
!define ABOUTURL "https://github.com/nicojeske/MasterVolumeSync" # "Publisher" link

!getdllversion "${PUBLISHDIR}\${DLL}" Expv_


!verbose push
!verbose 4
!echo "${APPNAME} version is ${expv_1}.${expv_2}.${expv_3}.${expv_4}"
!verbose pop


# These three must be integers
!define VERSIONMAJOR ${Expv_1}
!define VERSIONMINOR ${Expv_2}
!define VERSIONBUILD ${Expv_3}
!define VERSIONSTRING "${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD}.0"




; Installer Configuration
; Use OUTFILE for the Outfile command
Outfile "${OUTFILE}"
InstallDir "${APPDIR}\${COMPANYNAME}\${APPNAME}"
RequestExecutionLevel admin
CRCCheck on

Name "${APPNAME} v${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD}"

!define MUI_ICON "icon.ico"



; Pages
!define MUI_ABORTWARNING
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "license.txt"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; Uninstaller pages
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; UI Language
!insertmacro MUI_LANGUAGE "English"

 
!macro VerifyUserIsAdmin
UserInfo::GetAccountType
pop $0
${If} $0 != "admin" ;Require admin rights on NT4+
        messageBox mb_iconstop "Administrator rights required!"
        setErrorLevel 740 ;ERROR_ELEVATION_REQUIRED
        quit
${EndIf}
!macroend
 
function .onInit
	!insertmacro VerifyUserIsAdmin

	; Check if old version is installed (64-bit application, all users)
    ReadRegStr $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\{A1258055-C309-48FC-9432-20CDAF7D8160}" "UninstallString"
    ${If} $0 != ""
        ExecWait 'MsiExec.exe /X{A1258055-C309-48FC-9432-20CDAF7D8160} /quiet'
    ${EndIf}

    ; Check if old version is installed (32-bit application on a 64-bit system, all users)
    ReadRegStr $0 HKLM "Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{A1258055-C309-48FC-9432-20CDAF7D8160}" "UninstallString"
    ${If} $0 != ""
        ExecWait 'MsiExec.exe /X{A1258055-C309-48FC-9432-20CDAF7D8160} /quiet'
    ${EndIf}

    ; Check if old version is installed (installed for current user)
    ReadRegStr $0 HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\{A1258055-C309-48FC-9432-20CDAF7D8160}" "UninstallString"
    ${If} $0 != ""
        ExecWait 'MsiExec.exe /X{A1258055-C309-48FC-9432-20CDAF7D8160} /quiet'
    ${EndIf}

	setShellVarContext all
functionEnd
 
section "install"
	# Files for the install directory - to build the installer, these should be in the same directory as the install script (this file)
	setOutPath $INSTDIR
	# Files added here should be removed by the uninstaller (see section "uninstall")
	File /r "${PUBLISHDIR}\*.*"
 
	# Uninstaller - See function un.onInit and section "uninstall" for configuration
	writeUninstaller "$INSTDIR\uninstall.exe"
 
	# Start Menu
	createShortCut "$SMPROGRAMS\${APPNAME}.lnk" "$INSTDIR\${APPEXE}" "" "$INSTDIR\icon.ico"

	; Calculate the size of your application's directory
    ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
 	IntFmt $0 "0x%08X" $0

    ; Write the size to the EstimatedSize registry value
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "EstimatedSize" $0
 
	# Registry information for add/remove programs
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayName" "${APPNAME}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "UninstallString" "$INSTDIR\uninstall.exe"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "QuietUninstallString" "$INSTDIR\uninstall.exe /S"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "InstallLocation" "$INSTDIR"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayIcon" "$INSTDIR\icon.ico"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "Publisher" "${COMPANYNAME}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "HelpLink" "${HELPURL}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "URLUpdateInfo" "${UPDATEURL}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "URLInfoAbout" "${ABOUTURL}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayVersion" "${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD}"
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "VersionMajor" "${VERSIONMAJOR}"
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "VersionMinor" "${VERSIONMINOR}"


	# There is no option for modifying or repairing the install
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "NoModify" 1
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "NoRepair" 1

sectionEnd
 
# Uninstaller
 
function un.onInit
	SetShellVarContext all
 
	#Verify the uninstaller - last chance to back out
	MessageBox MB_OKCANCEL "Permanantly remove ${APPNAME}?" IDOK next
		Abort
	next:
	!insertmacro VerifyUserIsAdmin
functionEnd
 
section "uninstall"
 
	# Remove Start Menu launcher
	delete "$SMPROGRAMS\${APPNAME}.lnk"
 
    ; Remove the installed files
    RMDir /r $INSTDIR
 
	# Remove uninstaller information from the registry
	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}"
sectionEnd

!echo "Generating version information... ${VERSIONSTRING}"


VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductName" "${APPNAME}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "CompanyName" "${COMPANYNAME}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalCopyright" "© 2023 ${COMPANYNAME}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileVersion" "${VERSIONSTRING}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileDescription" "${DESCRIPTION}"
VIProductVersion "${VERSIONSTRING}"
 