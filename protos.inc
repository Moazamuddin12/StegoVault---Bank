; ==============================================================================
; protos.inc — StegoVault Bank Prototypes & External Declarations
; ==============================================================================

; --- Shared GUI Objects ---
EXTERNDEF usersLastErr  :DWORD
EXTERNDEF usersLastSize :DWORD
EXTERNDEF hFontHeader   :DWORD
EXTERNDEF hFontBody     :DWORD
EXTERNDEF hFontBold     :DWORD
EXTERNDEF hbrCanvas     :DWORD
EXTERNDEF hbrHeader     :DWORD
EXTERNDEF hbrInput      :DWORD
EXTERNDEF hbrSteel      :DWORD
EXTERNDEF hbrSteelDark  :DWORD
EXTERNDEF hbrBorder     :DWORD

EXTERNDEF hStatusScreen1:DWORD
EXTERNDEF hStatusScreen2:DWORD
EXTERNDEF hStatusScreen3:DWORD
EXTERNDEF hStatusScreen4:DWORD
EXTERNDEF statusErrScreen1:DWORD
EXTERNDEF statusErrScreen2:DWORD
EXTERNDEF statusErrScreen3:DWORD
EXTERNDEF statusErrScreen4:DWORD

EXTERNDEF hControlsScreen1:DWORD
EXTERNDEF hControlsScreen2:DWORD
EXTERNDEF hControlsScreen3:DWORD
EXTERNDEF hControlsScreen4:DWORD
EXTERNDEF nControlsScreen1:DWORD
EXTERNDEF nControlsScreen2:DWORD
EXTERNDEF nControlsScreen3:DWORD
EXTERNDEF nControlsScreen4:DWORD

EXTERNDEF hControlsScreen1Dep:DWORD
EXTERNDEF nControlsScreen1Dep:DWORD
EXTERNDEF hControlsScreen1Csh:DWORD
EXTERNDEF nControlsScreen1Csh:DWORD

EXTERNDEF hEditDepUser      :DWORD
EXTERNDEF hEditDepPass      :DWORD
EXTERNDEF hEditDepImg       :DWORD
EXTERNDEF hEditCshUser      :DWORD
EXTERNDEF hEditCshPass      :DWORD
EXTERNDEF hBtnTabDep        :DWORD
EXTERNDEF hBtnTabCsh        :DWORD
EXTERNDEF hBtnDepBrowse     :DWORD
EXTERNDEF hBtnDepLogin      :DWORD
EXTERNDEF hBtnDepRegister   :DWORD
EXTERNDEF hBtnCshLogin      :DWORD

EXTERNDEF hEditRegName      :DWORD
EXTERNDEF hEditRegUser      :DWORD
EXTERNDEF hEditRegPass      :DWORD
EXTERNDEF hEditRegConfirm   :DWORD
EXTERNDEF hEditRegCnic      :DWORD
EXTERNDEF hEditRegPhone     :DWORD
EXTERNDEF hEditRegDeposit   :DWORD
EXTERNDEF hEditRegCover     :DWORD
EXTERNDEF hBtnRegBrowse     :DWORD
EXTERNDEF hBtnRegSubmit     :DWORD
EXTERNDEF hBtnRegBack       :DWORD

EXTERNDEF hDepInfoAcc       :DWORD
EXTERNDEF hDepInfoName      :DWORD
EXTERNDEF hDepInfoCnic      :DWORD
EXTERNDEF hDepInfoPhone     :DWORD
EXTERNDEF hDepInfoBal       :DWORD
EXTERNDEF hDepRefreshBtn    :DWORD
EXTERNDEF hDepLogoutBtn     :DWORD

EXTERNDEF hDepTxnGrp        :DWORD
EXTERNDEF hDepTxnRadioDep   :DWORD
EXTERNDEF hDepTxnRadioWdr   :DWORD
EXTERNDEF hDepTxnAmtLbl     :DWORD
EXTERNDEF hDepTxnAmt        :DWORD
EXTERNDEF hDepTxnSubmitBtn  :DWORD

EXTERNDEF hCshAlertLbl        :DWORD
EXTERNDEF hCshReqListLbl      :DWORD
EXTERNDEF hCshReqList         :DWORD
EXTERNDEF hCshApproveBtn      :DWORD
EXTERNDEF hCshRejectBtn       :DWORD
EXTERNDEF hCshDepListLbl      :DWORD
EXTERNDEF hCshDepList         :DWORD
EXTERNDEF hCshOpenImgBtn      :DWORD
EXTERNDEF hCshDetailGrp       :DWORD
EXTERNDEF hCshDetailAcc       :DWORD
EXTERNDEF hCshDetailName      :DWORD
EXTERNDEF hCshDetailUser      :DWORD
EXTERNDEF hCshDetailCnic      :DWORD
EXTERNDEF hCshDetailPhone     :DWORD
EXTERNDEF hCshDetailBal       :DWORD
EXTERNDEF hCshManualGrp       :DWORD
EXTERNDEF hCshRadioDep        :DWORD
EXTERNDEF hCshRadioWdr        :DWORD
EXTERNDEF hCshManualAmt       :DWORD
EXTERNDEF hCshApplyBtn        :DWORD
EXTERNDEF hCshLogoutBtn       :DWORD

EXTERNDEF cshActiveRec        :ACCOUNT_RECORD
EXTERNDEF cshActiveNonce      :DWORD
EXTERNDEF cshActivePath       :BYTE
EXTERNDEF cshActiveUser       :BYTE

EXTERNDEF sessUser          :BYTE
EXTERNDEF sessSalt          :BYTE
EXTERNDEF sessDEK           :BYTE
EXTERNDEF sessRecord        :ACCOUNT_RECORD
EXTERNDEF sessNonce         :DWORD
EXTERNDEF sessImgPath       :BYTE

EXTERNDEF hMain         :DWORD
EXTERNDEF hInst         :DWORD
EXTERNDEF curScreen     :DWORD
EXTERNDEF curRole       :DWORD

SwitchLoginTab          PROTO :DWORD
BrowseLoginImage        PROTO :DWORD, :DWORD
BrowseCoverImage        PROTO :DWORD, :DWORD
DoRegister              PROTO :DWORD
DoDepositorLogin        PROTO :DWORD
DoRefreshBalance        PROTO
DoLogout                PROTO
DoSubmitRequest         PROTO :DWORD
DoCashierLogin          PROTO :DWORD
DoCashierLogout         PROTO
BrowseCashierImage      PROTO :DWORD
OnCashierDepListSelChange PROTO :DWORD
OnCashierReqListSelChange PROTO :DWORD
PopulateCashierRequests PROTO :DWORD
PopulateCashierDepositors PROTO
DoLoadDepositorImage    PROTO :DWORD, :DWORD
DoCashierApprove        PROTO :DWORD
DoCashierReject         PROTO :DWORD
DoCashierManualAdjust   PROTO :DWORD

; --- Win32 Kernel32 Prototypes ---
ExitProcess             PROTO :DWORD
GetModuleHandleA        PROTO :DWORD
GetCommandLineA         PROTO
CreateFileA             PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
CloseHandle             PROTO :DWORD
ReadFile                PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
WriteFile               PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
SetFilePointer          PROTO :DWORD, :DWORD, :DWORD, :DWORD
GetFileSizeEx           PROTO :DWORD, :DWORD
GetFileSize             PROTO :DWORD, :DWORD
SetEndOfFile            PROTO :DWORD
GetModuleFileNameA      PROTO :DWORD, :DWORD, :DWORD
SetCurrentDirectoryA    PROTO :DWORD
CopyFileA               PROTO :DWORD, :DWORD, :DWORD
FlushFileBuffers        PROTO :DWORD
MoveFileExA             PROTO :DWORD, :DWORD, :DWORD
DeleteFileA             PROTO :DWORD
CreateDirectoryA        PROTO :DWORD, :DWORD
FindFirstFileA          PROTO :DWORD, :DWORD
FindNextFileA           PROTO :DWORD, :DWORD
FindClose               PROTO :DWORD
GetProcessHeap          PROTO
HeapAlloc               PROTO :DWORD, :DWORD, :DWORD
HeapFree                PROTO :DWORD, :DWORD, :DWORD
HeapValidate            PROTO :DWORD, :DWORD, :DWORD
GetCurrentProcess       PROTO
GetProcessHandleCount   PROTO :DWORD, :DWORD
lstrlenA                PROTO :DWORD
lstrcpyA                PROTO :DWORD, :DWORD
lstrcatA                PROTO :DWORD, :DWORD
lstrcmpiA               PROTO :DWORD, :DWORD
lstrcmpA                PROTO :DWORD, :DWORD
RtlZeroMemory           PROTO :DWORD, :DWORD
RtlMoveMemory           PROTO :DWORD, :DWORD, :DWORD
MultiByteToWideChar     PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
GetLastError            PROTO
OutputDebugStringA      PROTO :DWORD

; --- Win32 User32 Prototypes ---
RegisterClassExA        PROTO :DWORD
CreateWindowExA         PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
AdjustWindowRectEx      PROTO :DWORD, :DWORD, :DWORD, :DWORD
LoadCursorA             PROTO :DWORD, :DWORD
LoadIconA               PROTO :DWORD, :DWORD
ShowWindow              PROTO :DWORD, :DWORD
UpdateWindow            PROTO :DWORD
GetMessageA             PROTO :DWORD, :DWORD, :DWORD, :DWORD
TranslateMessage        PROTO :DWORD
DispatchMessageA        PROTO :DWORD
PostQuitMessage         PROTO :DWORD
DestroyWindow           PROTO :DWORD
DefWindowProcA          PROTO :DWORD, :DWORD, :DWORD, :DWORD
BeginPaint              PROTO :DWORD, :DWORD
EndPaint                PROTO :DWORD, :DWORD
GetClientRect           PROTO :DWORD, :DWORD
GetWindowRect           PROTO :DWORD, :DWORD
ScreenToClient          PROTO :DWORD, :DWORD
SetWindowPos            PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
EnumChildWindows        PROTO :DWORD, :DWORD, :DWORD
SendMessageA            PROTO :DWORD, :DWORD, :DWORD, :DWORD
SetWindowTextA          PROTO :DWORD, :DWORD
GetWindowTextA          PROTO :DWORD, :DWORD, :DWORD
GetWindowLongA          PROTO :DWORD, :DWORD
EnableWindow            PROTO :DWORD, :DWORD
SetFocus                PROTO :DWORD
InvalidateRect          PROTO :DWORD, :DWORD, :DWORD
IsWindowVisible         PROTO :DWORD
MessageBoxA             PROTO :DWORD, :DWORD, :DWORD, :DWORD
FillRect                PROTO :DWORD, :DWORD, :DWORD
FrameRect               PROTO :DWORD, :DWORD, :DWORD
DrawTextA               PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD

; --- Win32 GDI32 Prototypes ---
CreateFontA             PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
CreateSolidBrush        PROTO :DWORD
DeleteObject            PROTO :DWORD
SelectObject            PROTO :DWORD, :DWORD
SetTextColor            PROTO :DWORD, :DWORD
SetBkColor              PROTO :DWORD, :DWORD
SetBkMode               PROTO :DWORD, :DWORD

; --- Win32 ComDlg32 Prototypes ---
GetOpenFileNameA        PROTO :DWORD

; --- GDI+ Flat API Prototypes ---
GdiplusStartup          PROTO :DWORD, :DWORD, :DWORD
GdiplusShutdown         PROTO :DWORD
GdipCreateBitmapFromFile PROTO :DWORD, :DWORD
GdipDisposeImage        PROTO :DWORD
GdipGetImageWidth       PROTO :DWORD, :DWORD
GdipGetImageHeight      PROTO :DWORD, :DWORD
GdipBitmapLockBits      PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
GdipBitmapUnlockBits    PROTO :DWORD, :DWORD

; --- Module Procedures: main.asm ---
start                   PROTO C
WndProc                 PROTO :DWORD, :DWORD, :DWORD, :DWORD
ShowScreen              PROTO :DWORD

; --- Module Procedures: gui.asm ---
InitGuiResources        PROTO
FreeGuiResources        PROTO
BuildScreens            PROTO :DWORD
AddControlToScreen      PROTO :DWORD, :DWORD
DrawOwnerItem           PROTO :DWORD, :DWORD
SetStatus               PROTO :DWORD, :DWORD, :DWORD
ValidateUsername        PROTO :DWORD
ValidatePassword        PROTO :DWORD
ValidateFullName        PROTO :DWORD
ValidateCnic            PROTO :DWORD
ValidateContact         PROTO :DWORD
ValidateAmount          PROTO :DWORD
AtoiDec                 PROTO :DWORD
ItoaDec                 PROTO :DWORD, :DWORD

; --- Module Procedures: crypto.asm ---
SvHash256               PROTO :DWORD, :DWORD, :DWORD
SvDeriveKeys            PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
SvCipher                PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
SvWrapDek               PROTO :DWORD, :DWORD, :DWORD
SvUnwrapDek             PROTO :DWORD, :DWORD, :DWORD
SvRandom                PROTO :DWORD, :DWORD
SvFnv32                 PROTO :DWORD, :DWORD
SvWipe                  PROTO :DWORD, :DWORD

; --- Module Procedures: stego.asm ---
InitGdiplus             PROTO
ShutdownGdiplus         PROTO
DeriveCashierKek        PROTO :DWORD
LoadImageAsBmp          PROTO :DWORD, :DWORD
ParseBmp                PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
EmbedBytes              PROTO :DWORD, :DWORD, :DWORD
ExtractBytes            PROTO :DWORD, :DWORD, :DWORD
ReadVaultStream         PROTO :DWORD, :DWORD
WriteVaultStream        PROTO :DWORD, :DWORD
BuildVaultImage         PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
OpenVaultImage          PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD

; --- Module Procedures: fileio.asm ---
InitStorage             PROTO
ReadWholeFile           PROTO :DWORD, :DWORD
WriteWholeFile          PROTO :DWORD, :DWORD, :DWORD
AtomicWriteFile         PROTO :DWORD, :DWORD, :DWORD
UsersRepair             PROTO
LoadImageA              PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
CreateCompatibleDC      PROTO :DWORD
DeleteDC                PROTO :DWORD
StretchBlt              PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
SetStretchBltMode       PROTO :DWORD, :DWORD
SetBrushOrgEx           PROTO :DWORD, :DWORD, :DWORD, :DWORD
GetObjectA              PROTO :DWORD, :DWORD, :DWORD
Sleep                   PROTO :DWORD
SetCursor               PROTO :DWORD
GdipCreateBitmapFromScan0   PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
GdipGetImageGraphicsContext PROTO :DWORD, :DWORD
GdipSetInterpolationMode    PROTO :DWORD, :DWORD
GdipDrawImageRectI          PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
GdipDeleteGraphics          PROTO :DWORD
DrawPreviewItem         PROTO :DWORD
SetCashierPreview       PROTO :DWORD
SetCashierLocked        PROTO
ShowDecryptPopup        PROTO :DWORD
CloseDecryptPopup       PROTO :DWORD
SelectVaultForPreview   PROTO :DWORD, :DWORD
CashierExists           PROTO
CashierCreate           PROTO :DWORD, :DWORD
CashierVerify           PROTO :DWORD, :DWORD
DoCashierCreate         PROTO :DWORD
UsersCount              PROTO
UsersFind               PROTO :DWORD, :DWORD
UsersAppend             PROTO :DWORD
UsersSetNonce           PROTO :DWORD, :DWORD
ReqAppend               PROTO :DWORD
ReqCount                PROTO
ReqReadAll              PROTO :DWORD, :DWORD
ReqSetStatus            PROTO :DWORD, :DWORD
ReqCountPending         PROTO
ScanVault               PROTO :DWORD

; --- Theme / dialog additions ---
GetStockObject         PROTO :DWORD
SetDCBrushColor        PROTO :DWORD, :DWORD
SetDCPenColor          PROTO :DWORD, :DWORD
CreatePen              PROTO :DWORD, :DWORD, :DWORD
MoveToEx               PROTO :DWORD, :DWORD, :DWORD, :DWORD
LineTo                 PROTO :DWORD, :DWORD, :DWORD
IsDialogMessageA       PROTO :DWORD, :DWORD
PostMessageA           PROTO :DWORD, :DWORD, :DWORD, :DWORD
SetForegroundWindow    PROTO :DWORD
MessageBeep            PROTO :DWORD
FillRc                 PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
FrameRc                PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
LerpColor              PROTO :DWORD, :DWORD, :DWORD, :DWORD
DrawVaultWheel         PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
DrawCard               PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
DrawTile               PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
PaintHeader            PROTO :DWORD, :DWORD, :DWORD
PaintCards             PROTO :DWORD
GetCtlTextColor        PROTO :DWORD
DrawListItem           PROTO :DWORD
ThemedDialog           PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
ThemedMsgBox           PROTO :DWORD, :DWORD, :DWORD, :DWORD
DlgProc                PROTO :DWORD, :DWORD, :DWORD, :DWORD
SetCashierMode         PROTO :DWORD
ShowCashierChooser     PROTO :DWORD
AddCshDet              PROTO :DWORD
AddCshMan              PROTO :DWORD
EXTERNDEF curOffX      :DWORD
EXTERNDEF curOffY      :DWORD
PctOf                  PROTO :DWORD, :DWORD
DrawTxt                PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
GetFocus               PROTO
EXTERNDEF cshMode      :DWORD
RunSplash              PROTO
PaintFooter            PROTO :DWORD, :DWORD, :DWORD
SetTimer               PROTO :DWORD, :DWORD, :DWORD, :DWORD
KillTimer              PROTO :DWORD, :DWORD
GetSystemMetrics       PROTO :DWORD
CreateCompatibleBitmap PROTO :DWORD, :DWORD, :DWORD
BitBlt                 PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
Ellipse                PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
UiTick                 PROTO
PaintStrength          PROTO :DWORD
DrawBankCard           PROTO :DWORD, :DWORD, :DWORD
GetCursorPos           PROTO :DWORD
WindowFromPoint        PROTO :DWORD, :DWORD
GetParent              PROTO :DWORD
GetClassNameA          PROTO :DWORD, :DWORD, :DWORD
GetDC                  PROTO :DWORD
ReleaseDC              PROTO :DWORD, :DWORD
ApplyDarkTitle         PROTO :DWORD
LoadLibraryA           PROTO :DWORD
GetProcAddress         PROTO :DWORD, :DWORD
GetTickCount           PROTO
SetViewportOrgEx       PROTO :DWORD, :DWORD, :DWORD, :DWORD
ShowBalCur             PROTO
StartBalAnim           PROTO
EXTERNDEF subSlide     :DWORD
RedrawWindow           PROTO :DWORD, :DWORD, :DWORD, :DWORD
NotifyDepositor        PROTO :DWORD
FormatRegField         PROTO :DWORD, :DWORD
