; ==============================================================================
; gui.asm: GUI Construction, Owner Draw & Form Validation for StegoVault Bank
; ==============================================================================
.586
.model flat, stdcall
option casemap:none

include constants.inc
include structs.inc
include protos.inc

PUBLIC InitGuiResources
PUBLIC FreeGuiResources
PUBLIC BuildScreens
PUBLIC AddControlToScreen
PUBLIC DrawOwnerItem
PUBLIC SetStatus
PUBLIC ValidateUsername
PUBLIC ValidatePassword
PUBLIC ValidateFullName
PUBLIC ValidateCnic
PUBLIC ValidateContact
PUBLIC ValidateAmount
PUBLIC AtoiDec
PUBLIC ItoaDec

PUBLIC SwitchLoginTab
PUBLIC BrowseLoginImage
PUBLIC BrowseCoverImage
PUBLIC DoRegister
PUBLIC DoDepositorLogin
PUBLIC DoRefreshBalance
PUBLIC DoLogout
PUBLIC DoSubmitRequest
PUBLIC DoCashierLogin
PUBLIC DoCashierCreate
PUBLIC DoCashierLogout
PUBLIC BrowseCashierImage
PUBLIC OnCashierDepListSelChange
PUBLIC OnCashierReqListSelChange
PUBLIC PopulateCashierRequests
PUBLIC PopulateCashierDepositors
PUBLIC DoLoadDepositorImage
PUBLIC DoCashierApprove
PUBLIC DoCashierReject
PUBLIC DoCashierManualAdjust

PUBLIC hControlsScreen1Dep
PUBLIC nControlsScreen1Dep
PUBLIC hControlsScreen1Csh
PUBLIC nControlsScreen1Csh

PUBLIC hEditDepUser
PUBLIC hEditDepPass
PUBLIC hEditDepImg
PUBLIC hEditCshUser
PUBLIC hEditCshPass
PUBLIC hBtnTabDep
PUBLIC hBtnTabCsh
PUBLIC hBtnDepBrowse
PUBLIC hBtnDepLogin
PUBLIC hBtnDepRegister
PUBLIC hBtnCshLogin

PUBLIC hEditRegName
PUBLIC hEditRegUser
PUBLIC hEditRegPass
PUBLIC hEditRegConfirm
PUBLIC hEditRegCnic
PUBLIC hEditRegPhone
PUBLIC hEditRegDeposit
PUBLIC hEditRegCover
PUBLIC hBtnRegBrowse
PUBLIC hBtnRegSubmit
PUBLIC hBtnRegBack

PUBLIC hDepInfoAcc
PUBLIC hDepInfoName
PUBLIC hDepInfoCnic
PUBLIC hDepInfoPhone
PUBLIC hDepInfoBal
PUBLIC hDepRefreshBtn
PUBLIC hDepLogoutBtn

PUBLIC hDepTxnGrp
PUBLIC hDepTxnRadioDep
PUBLIC hDepTxnRadioWdr
PUBLIC hDepTxnAmtLbl
PUBLIC hDepTxnAmt
PUBLIC hDepTxnSubmitBtn

PUBLIC hCshAlertLbl
PUBLIC hCshReqListLbl
PUBLIC hCshReqList
PUBLIC hCshApproveBtn
PUBLIC hCshRejectBtn
PUBLIC hCshDepListLbl
PUBLIC hCshDepList
PUBLIC hCshOpenImgBtn
PUBLIC hCshDetailGrp
PUBLIC hCshDetailAcc
PUBLIC hCshDetailName
PUBLIC hCshDetailUser
PUBLIC hCshDetailCnic
PUBLIC hCshDetailPhone
PUBLIC hCshDetailBal
PUBLIC hCshManualGrp
PUBLIC hCshRadioDep
PUBLIC hCshRadioWdr
PUBLIC hCshManualAmt
PUBLIC hCshApplyBtn
PUBLIC hCshLogoutBtn

PUBLIC cshActiveRec
PUBLIC cshMode
PUBLIC PaintHeader
PUBLIC PaintCards
PUBLIC UiTick
PUBLIC FormatRegField
PUBLIC NotifyDepositor
PUBLIC subSlide
PUBLIC StartBalAnim
PUBLIC PaintStrength
PUBLIC GetCtlTextColor
PUBLIC SetCashierMode
PUBLIC ThemedMsgBox
PUBLIC ThemedDialog
PUBLIC cshActiveNonce
PUBLIC cshActivePath
PUBLIC cshActiveUser

PUBLIC sessUser
PUBLIC sessSalt
PUBLIC sessDEK
PUBLIC sessRecord
PUBLIC sessNonce
PUBLIC sessImgPath

PUBLIC hFontHeader
PUBLIC RunSplash
PUBLIC hFontBody
PUBLIC hFontBold
PUBLIC hbrCanvas
PUBLIC hbrHeader
PUBLIC hbrInput
PUBLIC hbrSteel
PUBLIC hbrSteelDark
PUBLIC hbrBorder

PUBLIC hStatusScreen1
PUBLIC hStatusScreen2
PUBLIC hStatusScreen3
PUBLIC hStatusScreen4
PUBLIC statusErrScreen1
PUBLIC statusErrScreen2
PUBLIC statusErrScreen3
PUBLIC statusErrScreen4

MAX_SCREEN_CONTROLS EQU 64

.data
szStaticClass       BYTE "STATIC", 0
szEditClass         BYTE "EDIT", 0
szButtonClass       BYTE "BUTTON", 0

szTabDepText        BYTE "Depositor Login", 0
szTabCshText        BYTE "Cashier Login", 0

szDepUserLbl        BYTE "Account Username:", 0
szDepPassLbl        BYTE "Password:", 0
szDepImgLbl         BYTE "Personal Vault Image (.bmp):", 0
szDepBrowseBtn      BYTE "Browse Vault Image...", 0
szDepSubmitBtn      BYTE "Login to Vault", 0
szDepRegBtn         BYTE "Register New Account", 0
szDepNoticeText     BYTE "StegoVault security: Your 148-byte banking record is encrypted and hidden in your personal BMP image. Both password and vault image are required.", 0

szCshUserLbl        BYTE "Cashier Username:", 0
szCshPassLbl        BYTE "Cashier Password:", 0
szCshSubmitBtn      BYTE "Login as Cashier", 0
szCshNoticeText     BYTE "New here? Enter a new cashier username and password above, then click Create Cashier Account. Afterwards log in with those credentials.", 0
szCshCreateBtn      BYTE "Create Cashier Account", 0
szErrCashierExists  BYTE "A cashier account already exists. Log in with its username and password.", 0
szErrCashierWrite   BYTE "Could not save the cashier account (disk write failed).", 0
szMsgCashierCreated BYTE "Cashier account created. You can now log in with it.", 0
szErrRepairCode     BYTE " (Windows error ", 0
szErrOpenUsers      BYTE "Cannot open users.dat", 0
szMsgRegWorking     BYTE "Converting and encrypting your image, please wait...", 0
szCloseParen        BYTE ")", 0

szBmpFilter         BYTE "Vault image (*.bmp)", 0, "*.bmp", 0, 0
szBrowseTitle       BYTE "Select Your StegoVault Personal Image", 0

szRegNameLbl        BYTE "Full Legal Name:", 0
szRegUserLbl        BYTE "Choose Username:", 0
szRegPassLbl        BYTE "Password (min 6 chars):", 0
szRegConfirmLbl     BYTE "Confirm Password:", 0
szRegCnicLbl        BYTE "CNIC (ddddd-ddddddd-d):", 0
szRegPhoneLbl       BYTE "Contact Phone Number:", 0
szRegDepositLbl     BYTE "Initial Deposit (PKR):", 0
szRegCoverLbl       BYTE "Cover Image (.bmp/.png/.jpg):", 0
szRegBrowseBtn      BYTE "Browse Image...", 0
szRegSubmitBtn      BYTE "Create Account & Encrypt Image", 0
szRegBackBtn        BYTE "Back to Login", 0
szRegNoticeText     BYTE "StegoVault security: The selected image is converted to 24-bit BMP and embedded with your encrypted record. The original cover image is never modified.", 0

szCoverFilter       BYTE "Image Files (*.bmp;*.png;*.jpg;*.jpeg)", 0, "*.bmp;*.png;*.jpg;*.jpeg", 0, "All Files (*.*)", 0, "*.*", 0, 0
szBrowseCoverTitle  BYTE "Select Cover Image for Your Vault", 0

szErrRegName        BYTE "Invalid full name: must be 1 to 63 characters.", 0
szErrRegUser        BYTE "Invalid username: must be 3 to 31 letters, digits or underscores, and not 'admin'.", 0
szErrRegPass        BYTE "Invalid password: must be 6 to 31 characters.", 0
szErrRegConfirm     BYTE "Passwords do not match.", 0
szErrRegCnic        BYTE "Invalid CNIC: format must be ddddd-ddddddd-d.", 0
szErrRegPhone       BYTE "Invalid contact: must be 10 to 15 digits.", 0
szErrRegDeposit     BYTE "Invalid deposit amount: must be 0 to 100,000,000.", 0
szErrRegCover       BYTE "Please select a cover image.", 0
szErrRegDuplicate   BYTE "Username already registered.", 0
szErrRegDecode      BYTE "Could not decode the cover image.", 0
szErrRegCapacity    BYTE "Image too small: need at least 64 x 64 pixels.", 0
szErrRegBuild       BYTE "Failed to embed vault stream into image.", 0
szErrRegWrite       BYTE "Disk write failed: could not save vault image.", 0
szErrRegAppend      BYTE "Failed to append user record to database.", 0
szErrUsersDamaged   BYTE "Registry file users.dat is damaged.", 0
szAskRepairUsers    BYTE "The registry file users.dat is damaged (its size is not a whole number of records).", 13, 10, 13, 10, "Repair it now? A backup copy is saved as users.dat.bak and only the incomplete trailing record is removed.", 0
szMsgUsersRepaired  BYTE "Registry repaired (backup saved as users.dat.bak). Click Create Account again.", 0
szErrUsersRepair    BYTE "Could not repair users.dat. Close other programs using it, or check that it is not read-only.", 0
szRegSuccess        BYTE "Account registered successfully! Vault image created.", 0
szVaultImagesDir    BYTE "Vault_Images\", 0
szRequestsFile      BYTE "requests.dat", 0
szEmptyStr          BYTE 0

szDepProfileGrp     BYTE "Account Profile && Vault Status", 0
szDepAccLbl         BYTE "Account Number:", 0
szDepHolderLbl      BYTE "Account Holder:", 0
szDepCnicLbl        BYTE "National ID (CNIC):", 0
szDepPhoneLbl       BYTE "Registered Phone:", 0
szDepBalLbl         BYTE "Current Balance:", 0
szDepRefreshBtnText BYTE "Refresh Balance", 0
szDepLogoutBtnText  BYTE "Logout", 0

szDepTxnGrpTitle    BYTE "Submit Transaction Request", 0
szDepRadioDepText   BYTE "Deposit Funds", 0
szDepRadioWdrText   BYTE "Withdraw Funds", 0
szDepTxnAmtLblText  BYTE "Transaction Amount (PKR):", 0
szDepTxnSubmitText  BYTE "Submit Request to Cashier", 0
szDepTxnNoticeText  BYTE "Your request is sent to the bank cashier for approval. Your balance changes only after the cashier approves it. Use Refresh Balance to see the latest amount.", 0

szCurrencyPrefix    BYTE "PKR ", 0

szErrLoginInputs    BYTE "Enter username, password and select your vault image.", 0
szErrLoginAuth      BYTE "Invalid username or password.", 0
szErrLoginNotStego  BYTE "This file is not a StegoVault image.", 0
szErrLoginNotOwner  BYTE "Unauthorized Image: This vault image does not belong to your account", 0
szErrLoginDamage    BYTE "Vault image is damaged or has been tampered with.", 0
szErrLoginStale     BYTE "Stale vault image: an older copy of your image was supplied.", 0
szErrLoginFile      BYTE "Could not open vault image file.", 0

szStatusDepLoginOk  BYTE "Vault unlocked. Account record verified.", 0
szStatusBalRefreshed BYTE "Balance updated from vault image.", 0
szErrBalRefresh     BYTE "Could not refresh balance: image checksum error.", 0
szStatusLoggedOut   BYTE "Logged out successfully.", 0

szBankTitle         BYTE "StegoVault Bank", 0
szFontGeorgia       BYTE "Georgia", 0
szFontSegoe         BYTE "Segoe UI", 0
wheelPhase          DWORD 0
szStrWeak           BYTE "Weak", 0
szStrFair           BYTE "Fair", 0
szStrGood           BYTE "Good", 0
szStrStrong         BYTE "Strong", 0
szStrEmpty          BYTE 0
szNtfTitle          BYTE "Request update", 0
szNtfAmtTitle       BYTE "Transaction amount", 0
szNtfA              BYTE "Your ", 0
szWordDeposit       BYTE "deposit", 0
szWordWithdraw      BYTE "withdrawal", 0
szNtfB              BYTE " request #", 0
szNtfApprEnd        BYTE " has been APPROVED by the cashier.", 0
szNtfDeclEnd        BYTE " has been DECLINED by the cashier.", 0
szNtfDepEnd         BYTE " has been deposited into your account.", 0
szNtfWdrEnd         BYTE " has been withdrawn from your account.", 0
lastLenCnic         DWORD 0
lastLenPhone        DWORD 0
szDwmDll            BYTE "dwmapi.dll", 0
szDwmFn             BYTE "DwmSetWindowAttribute", 0
szCardBrand         BYTE "STEGOVAULT  PRIVATE CARD", 0
szBrandText         BYTE "StegoVault Bank", 0
szHdrTag            BYTE "ENCRYPTED STEGANOGRAPHIC VAULT", 0
szDlgClass          BYTE "StegoVaultDlg", 0
szDlgErrTitle       BYTE "Please check", 0
szBtnOk             BYTE "OK", 0
szBtnYes            BYTE "Yes", 0
szBtnNo             BYTE "No", 0
szBtnViewDet        BYTE "View details", 0
szBtnUpdBal         BYTE "Update balance", 0
szBtnClose          BYTE "Close", 0
szChooseTitle       BYTE "Vault unlocked", 0
szChoosePart1       BYTE "The vault of '", 0
szChoosePart2       BYTE "' is open. What would you like to do with this account?", 0
szSideTitle         BYTE "Vault-grade privacy", 0
szSideText          BYTE "Every account lives", 13, 10, "inside a picture.", 13, 10, 13, 10, "No balance database.", 13, 10, 13, 10, "Password + image", 13, 10, "unlock your vault.", 0
szWfTitle           BYTE "How it works", 0
szWf1               BYTE "1.  Select a depositor or a request.", 0
szWf2               BYTE "2.  Insert that depositor's vault image.", 0
szWf3               BYTE "3.  Choose: view details or update balance.", 0
szLockTitle         BYTE "Vault locked", 0
szLockL1            BYTE "Select a depositor, then insert", 0
szLockL2            BYTE "their vault image to unlock it.", 0
szUpdTitle          BYTE "Balance update", 0
szUpdUser           BYTE "Account: ", 0
szUpdBalLbl         BYTE "Current balance", 0
szTileA1            BYTE "Dual-key vault", 0
szTileA2            BYTE "Opens with the depositor's key or the cashier's master key.", 0
szTileB1            BYTE "Hidden in plain sight", 0
szTileB2            BYTE "Your record is tucked into the pixel bits of a picture.", 0
szTileC1            BYTE "Tamper detection", 0
szTileC2            BYTE "A checksum seals each vault. Altered images are refused.", 0
szTileD1            BYTE "Vault sealed", 0
szTileD2            BYTE "Your balance is read from your image, never from a database.", 0
szTileE1            BYTE "Cashier approval", 0
szTileE2            BYTE "Deposits and withdrawals apply only after cashier review.", 0
szTileF1            BYTE "Safe session", 0
szTileF2            BYTE "Log out when finished to close your vault session.", 0
szSealed            BYTE "VAULT SEALED", 0
wheelCos            SDWORD 100, 87, 50, 0, -50, -87, -100, -87, -50, 0, 50, 87
wheelSin            SDWORD 0, 50, 87, 100, 87, 50, 0, -50, -87, -100, -87, -50
szErrReqType        BYTE "Please select a transaction type (Deposit or Withdraw).", 0
szErrReqEmptyAmt    BYTE "Please enter a transaction amount.", 0
szErrReqInvalidAmt  BYTE "Invalid amount. Enter digits only (1 to 100,000,000).", 0
szErrOverdrawMsg    BYTE "Insufficient funds: withdrawal amount exceeds current balance.", 0
szErrDepositOverflow BYTE "Transaction rejected: amount exceeds balance limit.", 0
szErrReqAppendFail  BYTE "Failed to append transaction request to requests.dat.", 0
szReqSubmittedPrefix BYTE "Request #", 0
szReqSubmittedSuffix BYTE " submitted.", 0

szScreen1Tag        BYTE "SCREEN 1: LOGIN PORTAL (Press '2' or F2 for Register)", 0
szScreen2Tag        BYTE "SCREEN 2: ACCOUNT REGISTRATION (Press '3' or F3 for Depositor)", 0
szScreen3Tag        BYTE "SCREEN 3: DEPOSITOR DASHBOARD (Press '4' or F4 for Cashier)", 0
szScreen4Tag        BYTE "SCREEN 4: CASHIER CONTROL PANEL (Press '1' or F1 for Login)", 0

szStatusReady       BYTE "System ready. All security subsystems verified.", 0
szReservedAdmin     BYTE "admin", 0

szAdminPass         BYTE "admin123", 0
szErrCashierCreds   BYTE "Invalid cashier credentials.", 0
szNoPendingAlert    BYTE "No pending transaction requests.", 0
szPendingAlertSuffix BYTE " pending request(s) waiting.", 0
szStatusCashierReady BYTE "Cashier authenticated. Master Key active.", 0
szVaultBmpPattern   BYTE "Vault_Images\*.bmp", 0
szBrowseCashierTitle BYTE "Select Depositor Vault Image", 0
szErrCashierOpenImage BYTE "Could not open vault image or checksum mismatch.", 0
szErrOpenIo         BYTE "Cannot read the selected image file. Choose a .bmp from the Vault_Images folder.", 0
szErrOpenBmp        BYTE "Wrong file: pick the vault .bmp saved in the Vault_Images folder, not the original JPG/PNG photo.", 0
szErrOpenMagic      BYTE "This .bmp holds no vault data (not made by StegoVault, or it was edited, re-saved or converted).", 0
szErrOpenCheck      BYTE "Vault image failed verification: the data is damaged or was altered.", 0
szErrOpenCode       BYTE " (code ", 0
szStatusVaultLoaded BYTE "Vault loaded and verified via Master Key.", 0
szListBoxClass      BYTE "LISTBOX", 0
szTwoSpaces         BYTE "  ", 0
szTypeDeposit       BYTE "Deposit", 0
szTypeWithdraw      BYTE "Withdraw", 0
szStatusPendingStr  BYTE "Pending", 0
szStatusApprovedStr BYTE "Approved", 0
szStatusRejectedStr BYTE "Rejected", 0
szCshReqListTitle   BYTE "Pending && Past Transaction Requests:", 0
szCshApproveBtnText BYTE "Approve Selected Request", 0
szCshRejectBtnText  BYTE "Reject Request", 0
szCshDepListTitle   BYTE "Registered Vaults (Vault_Images\):", 0
szCshOpenImgBtnText BYTE "Open Vault Image...", 0
szCshDetailGrpTitle BYTE "Active Depositor Vault Information", 0
szCshDetailAccLbl   BYTE "Account Number:", 0
szCshDetailNameLbl  BYTE "Account Holder:", 0
szCshDetailUserLbl  BYTE "Vault Username:", 0
szCshDetailCnicLbl  BYTE "National ID (CNIC):", 0
szCshDetailPhoneLbl BYTE "Contact Phone:", 0
szCshDetailBalLbl   BYTE "Current Balance:", 0
szCshManualGrpTitle BYTE "Manual Balance Adjustment", 0
szCshRadioDepText   BYTE "Deposit Funds", 0
szCshRadioWdrText   BYTE "Withdraw Funds", 0
szCshManualAmtLbl   BYTE "Adjustment Amount (PKR):", 0
szCshApplyBtnText   BYTE "Apply Adjustment", 0
szCshLogoutBtnText  BYTE "Logout", 0
szCshSecNoticeText  BYTE "Every approved change re-encrypts the vault image.", 0
szLockedValue       BYTE "(locked)", 0
szDecryptingText    BYTE "Decrypting the data...", 0
szNoPreviewText     BYTE "No vault selected", 0
szHintPart1         BYTE "Vault of '", 0
szHintPart2         BYTE "' selected. Click Open Vault Image and insert its file to decrypt it.", 0
szNeedPart1         BYTE "Insert the vault image of '", 0
szNeedPart2         BYTE "' first (Open Vault Image), then approve this request.", 0
szBmpExt            BYTE ".bmp", 0
szErrCashierStale   BYTE "Stale vault image: an older copy of this depositor's image was inserted.", 0
szErrNoCashierYet   BYTE "No cashier account exists yet. Click Create Cashier Account first.", 0

szErrNoReqSelected      BYTE "Please select a transaction request from the list.", 0
szErrReqAlreadyDone     BYTE "Selected request has already been processed.", 0
szErrApproveFunds       BYTE "Insufficient funds: request cannot be approved", 0
szErrApproveOverflow    BYTE "Approval rejected: deposit amount exceeds maximum balance.", 0
szErrApproveWrite       BYTE "Atomic write failed: could not update vault image.", 0
szErrNoVaultLoaded      BYTE "No depositor vault is currently loaded for manual adjustment.", 0
szStatusApprovedOk      BYTE "Request approved. Apply the amount manually below.", 0
szApprTitle             BYTE "Request approved", 0
szApprPart1             BYTE "The request of '", 0
szApprPart2             BYTE "' is approved. No money has moved yet. Choose how to apply it; you will then enter the amount yourself.", 0
szBtnDeposit            BYTE "Deposit", 0
szBtnWithdraw           BYTE "Withdraw", 0
szStatusRejectedOk      BYTE "Transaction request marked as rejected.", 0
szStatusManualOk        BYTE "Manual adjustment applied. Vault image and ledger updated.", 0

.data?
hFontHeader         DWORD ?
hFontBody           DWORD ?
hFontBold           DWORD ?

hbrCanvas           DWORD ?
hbrHeader           DWORD ?
hbrInput            DWORD ?
hbrSteel            DWORD ?
hbrSteelDark        DWORD ?
hbrBorder           DWORD ?

hControlsScreen1    DWORD MAX_SCREEN_CONTROLS DUP (?)
nControlsScreen1    DWORD ?
hControlsScreen1Dep DWORD MAX_SCREEN_CONTROLS DUP (?)
nControlsScreen1Dep DWORD ?
hControlsScreen1Csh DWORD MAX_SCREEN_CONTROLS DUP (?)
nControlsScreen1Csh DWORD ?

hEditDepUser        DWORD ?
hEditDepPass        DWORD ?
hEditDepImg         DWORD ?
hEditCshUser        DWORD ?
hEditCshPass        DWORD ?
hBtnTabDep          DWORD ?
hBtnTabCsh          DWORD ?
hBtnDepBrowse       DWORD ?
hBtnDepLogin        DWORD ?
hBtnDepRegister     DWORD ?
hBtnCshLogin        DWORD ?
hBtnCshCreate       DWORD ?

hEditRegName        DWORD ?
hEditRegUser        DWORD ?
hEditRegPass        DWORD ?
hEditRegConfirm     DWORD ?
hEditRegCnic        DWORD ?
hEditRegPhone       DWORD ?
hEditRegDeposit     DWORD ?
hEditRegCover       DWORD ?
hBtnRegBrowse       DWORD ?
hBtnRegSubmit       DWORD ?
hBtnRegBack         DWORD ?

hDepInfoAcc         DWORD ?
hDepInfoName        DWORD ?
hDepInfoCnic        DWORD ?
hDepInfoPhone       DWORD ?
hDepInfoBal         DWORD ?
hDepRefreshBtn      DWORD ?
hDepLogoutBtn       DWORD ?

hDepTxnGrp          DWORD ?
hDepTxnRadioDep     DWORD ?
hDepTxnRadioWdr     DWORD ?
hDepTxnAmtLbl       DWORD ?
hDepTxnAmt          DWORD ?
hDepTxnSubmitBtn    DWORD ?

sessUser            BYTE 32 DUP (?)
sessSalt            BYTE 16 DUP (?)
sessDEK             BYTE 32 DUP (?)
sessRecord          ACCOUNT_RECORD <>
sessNonce           DWORD ?
sessImgPath         BYTE MAX_PATH DUP (?)

hCshAlertLbl        DWORD ?
hCshReqListLbl      DWORD ?
hCshReqList         DWORD ?
hCshApproveBtn      DWORD ?
hCshRejectBtn       DWORD ?
hCshDepListLbl      DWORD ?
hCshDepList         DWORD ?
hCshOpenImgBtn      DWORD ?
hCshPreview         DWORD ?
hPreviewBmp         DWORD ?
hCshDetailGrp       DWORD ?
hCshDetailAcc       DWORD ?
hCshDetailName      DWORD ?
hCshDetailUser      DWORD ?
hCshDetailCnic      DWORD ?
hCshDetailPhone     DWORD ?
hCshDetailBal       DWORD ?
hCshManualGrp       DWORD ?
hCshRadioDep        DWORD ?
hCshRadioWdr        DWORD ?
hCshManualAmt       DWORD ?
hCshApplyBtn        DWORD ?
hCshLogoutBtn       DWORD ?
hFontBrand          DWORD ?
hDepProfileGrp      DWORD ?
cshMode             DWORD ?
hCshDetCtls         DWORD 24 DUP (?)
nCshDet             DWORD ?
hCshManCtls         DWORD 12 DUP (?)
nCshMan             DWORD ?
dlgTitle            DWORD ?
dlgMsg              DWORD ?
dlgB1               DWORD ?
dlgB2               DWORD ?
dlgB3               DWORD ?
dlgKind             DWORD ?
dlgResult           DWORD ?
dlgDone             DWORD ?
hDlgWnd             DWORD ?
hDlgBtn1            DWORD ?
hDlgBtn2            DWORD ?
hDlgBtn3            DWORD ?
dlgClassReg         DWORD ?

cshActiveRec        ACCOUNT_RECORD <>
cshActiveNonce      DWORD ?
cshActivePath       BYTE MAX_PATH DUP (?)
cshActiveUser       BYTE 32 DUP (?)

hControlsScreen2    DWORD MAX_SCREEN_CONTROLS DUP (?)
nControlsScreen2    DWORD ?
hControlsScreen3    DWORD MAX_SCREEN_CONTROLS DUP (?)
nControlsScreen3    DWORD ?
hControlsScreen4    DWORD MAX_SCREEN_CONTROLS DUP (?)
nControlsScreen4    DWORD ?

hStatusScreen1      DWORD ?
hStatusScreen2      DWORD ?
hStatusScreen3      DWORD ?
hStatusScreen4      DWORD ?
hHoverCtl           DWORD ?
splashStart         DWORD ?
hSpMem              DWORD ?
hSpBmp              DWORD ?
hSpOld              DWORD ?
splashInit          DWORD ?
balTarget           DWORD ?
balCur              DWORD ?
balAnim             DWORD ?
subSlide            DWORD ?
tickCnt             DWORD ?
blinkOn             DWORD ?

statusErrScreen1    DWORD ?
statusErrScreen2    DWORD ?
statusErrScreen3    DWORD ?
statusErrScreen4    DWORD ?

.code

; ------------------------------------------------------------------------------
; AddControlToScreen: Appends a control handle to the specified screen's group
; Inputs:  screenId (DWORD 1..4), hCtl (DWORD)
; Outputs: EAX = SV_OK
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
AddControlToScreen PROC USES ebx esi edi screenId:DWORD, hCtl:DWORD
    mov eax, screenId
    mov edx, hCtl
    .IF eax == 1
        mov ecx, nControlsScreen1
        .IF ecx < MAX_SCREEN_CONTROLS
            mov hControlsScreen1[ecx*4], edx
            inc nControlsScreen1
        .ENDIF
    .ELSEIF eax == 2
        mov ecx, nControlsScreen2
        .IF ecx < MAX_SCREEN_CONTROLS
            mov hControlsScreen2[ecx*4], edx
            inc nControlsScreen2
        .ENDIF
    .ELSEIF eax == 3
        mov ecx, nControlsScreen3
        .IF ecx < MAX_SCREEN_CONTROLS
            mov hControlsScreen3[ecx*4], edx
            inc nControlsScreen3
        .ENDIF
    .ELSEIF eax == 4
        mov ecx, nControlsScreen4
        .IF ecx < MAX_SCREEN_CONTROLS
            mov hControlsScreen4[ecx*4], edx
            inc nControlsScreen4
        .ENDIF
    .ENDIF
    mov eax, SV_OK
    ret
AddControlToScreen ENDP

AddControlToScreen1Dep PROC USES ecx edx hCtl:DWORD
    mov ecx, nControlsScreen1Dep
    .IF ecx < MAX_SCREEN_CONTROLS
        mov edx, hCtl
        mov hControlsScreen1Dep[ecx*4], edx
        inc nControlsScreen1Dep
    .ENDIF
    ret
AddControlToScreen1Dep ENDP

AddControlToScreen1Csh PROC USES ecx edx hCtl:DWORD
    mov ecx, nControlsScreen1Csh
    .IF ecx < MAX_SCREEN_CONTROLS
        mov edx, hCtl
        mov hControlsScreen1Csh[ecx*4], edx
        inc nControlsScreen1Csh
    .ENDIF
    ret
AddControlToScreen1Csh ENDP

; ------------------------------------------------------------------------------
; BuildScreens: Creates child controls for all 4 screens
; Inputs:  hParent (DWORD)
; Outputs: EAX = SV_OK
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
BuildScreens PROC USES ebx esi edi hParent:DWORD
    mov nControlsScreen1, 0
    mov nControlsScreen2, 0
    mov nControlsScreen3, 0
    mov nControlsScreen4, 0

    ; === SCREEN 1 COMMON CONTROLS ===
    ; Tab 1: Depositor Tab Button
    invoke CreateWindowExA, 0, offset szButtonClass, offset szTabDepText,
           WS_CHILD or WS_VISIBLE or BS_OWNERDRAW,
           32, 88, 160, 34, hParent, IDC_LOGIN_TAB_DEP, hInst, 0
    mov hBtnTabDep, eax
    invoke AddControlToScreen, 1, hBtnTabDep

    ; Tab 2: Cashier Tab Button
    invoke CreateWindowExA, 0, offset szButtonClass, offset szTabCshText,
           WS_CHILD or WS_VISIBLE or BS_OWNERDRAW,
           200, 88, 160, 34, hParent, IDC_LOGIN_TAB_CSH, hInst, 0
    mov hBtnTabCsh, eax
    invoke AddControlToScreen, 1, hBtnTabCsh

    ; Screen 1 Status Line
    invoke CreateWindowExA, 0, offset szStaticClass, offset szStatusReady,
           WS_CHILD or WS_VISIBLE or SS_LEFT,
           32, 590, 896, 22, hParent, IDC_LOGIN_STATUS, hInst, 0
    mov hStatusScreen1, eax
    invoke SendMessageA, eax, WM_SETFONT, hFontBody, 1
    invoke AddControlToScreen, 1, hStatusScreen1

    ; === SCREEN 1 DEPOSITOR CONTROLS ===
    mov nControlsScreen1Dep, 0

    ; Dep Username Label
    invoke CreateWindowExA, 0, offset szStaticClass, offset szDepUserLbl,
           WS_CHILD or WS_VISIBLE or SS_LEFT,
           32, 136, 250, 20, hParent, IDC_LOGIN_DEP_USER_LBL, hInst, 0
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddControlToScreen1Dep, ebx

    ; Dep Username Edit
    invoke CreateWindowExA, 0, offset szEditClass, 0,
           WS_CHILD or WS_VISIBLE or WS_BORDER or ES_AUTOHSCROLL,
           32, 158, 380, 26, hParent, IDC_LOGIN_DEP_USER_TXT, hInst, 0
    mov hEditDepUser, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBody, 1
    invoke AddControlToScreen1Dep, ebx

    ; Dep Password Label
    invoke CreateWindowExA, 0, offset szStaticClass, offset szDepPassLbl,
           WS_CHILD or WS_VISIBLE or SS_LEFT,
           32, 196, 250, 20, hParent, IDC_LOGIN_DEP_PASS_LBL, hInst, 0
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddControlToScreen1Dep, ebx

    ; Dep Password Edit (ES_PASSWORD)
    invoke CreateWindowExA, 0, offset szEditClass, 0,
           WS_CHILD or WS_VISIBLE or WS_BORDER or ES_PASSWORD or ES_AUTOHSCROLL,
           32, 218, 380, 26, hParent, IDC_LOGIN_DEP_PASS_TXT, hInst, 0
    mov hEditDepPass, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBody, 1
    invoke AddControlToScreen1Dep, ebx

    ; Dep Image Label
    invoke CreateWindowExA, 0, offset szStaticClass, offset szDepImgLbl,
           WS_CHILD or WS_VISIBLE or SS_LEFT,
           32, 256, 300, 20, hParent, IDC_LOGIN_DEP_IMG_LBL, hInst, 0
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddControlToScreen1Dep, ebx

    ; Dep Image Path Edit (ES_READONLY)
    invoke CreateWindowExA, 0, offset szEditClass, 0,
           WS_CHILD or WS_VISIBLE or WS_BORDER or ES_READONLY or ES_AUTOHSCROLL,
           32, 278, 440, 26, hParent, IDC_LOGIN_DEP_IMG_TXT, hInst, 0
    mov hEditDepImg, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBody, 1
    invoke AddControlToScreen1Dep, ebx

    ; Dep Browse Button
    invoke CreateWindowExA, 0, offset szButtonClass, offset szDepBrowseBtn,
           WS_CHILD or WS_VISIBLE or BS_OWNERDRAW,
           480, 277, 190, 28, hParent, IDC_LOGIN_DEP_BROWSE, hInst, 0
    mov hBtnDepBrowse, eax
    invoke AddControlToScreen1Dep, eax

    ; Dep Login Button
    invoke CreateWindowExA, 0, offset szButtonClass, offset szDepSubmitBtn,
           WS_CHILD or WS_VISIBLE or BS_OWNERDRAW,
           32, 324, 180, 38, hParent, IDC_LOGIN_DEP_SUBMIT, hInst, 0
    mov hBtnDepLogin, eax
    invoke AddControlToScreen1Dep, eax

    ; Dep Register Button
    invoke CreateWindowExA, 0, offset szButtonClass, offset szDepRegBtn,
           WS_CHILD or WS_VISIBLE or BS_OWNERDRAW,
           224, 324, 220, 38, hParent, IDC_LOGIN_DEP_GOTO_REG, hInst, 0
    mov hBtnDepRegister, eax
    invoke AddControlToScreen1Dep, eax

    ; Dep Notice Static
    invoke CreateWindowExA, 0, offset szStaticClass, offset szDepNoticeText,
           WS_CHILD or WS_VISIBLE or SS_LEFT,
           32, 380, 640, 42, hParent, 0, hInst, 0
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBody, 1
    invoke AddControlToScreen1Dep, ebx

    ; === SCREEN 1 CASHIER CONTROLS ===
    mov nControlsScreen1Csh, 0

    ; Csh Username Label
    invoke CreateWindowExA, 0, offset szStaticClass, offset szCshUserLbl,
           WS_CHILD or SS_LEFT,
           32, 136, 250, 20, hParent, IDC_LOGIN_CSH_USER_LBL, hInst, 0
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddControlToScreen1Csh, ebx

    ; Csh Username Edit
    invoke CreateWindowExA, 0, offset szEditClass, 0,
           WS_CHILD or WS_BORDER or ES_AUTOHSCROLL,
           32, 158, 380, 26, hParent, IDC_LOGIN_CSH_USER_TXT, hInst, 0
    mov hEditCshUser, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBody, 1
    invoke AddControlToScreen1Csh, ebx

    ; Csh Password Label
    invoke CreateWindowExA, 0, offset szStaticClass, offset szCshPassLbl,
           WS_CHILD or SS_LEFT,
           32, 196, 250, 20, hParent, IDC_LOGIN_CSH_PASS_LBL, hInst, 0
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddControlToScreen1Csh, ebx

    ; Csh Password Edit (ES_PASSWORD)
    invoke CreateWindowExA, 0, offset szEditClass, 0,
           WS_CHILD or WS_BORDER or ES_PASSWORD or ES_AUTOHSCROLL,
           32, 218, 380, 26, hParent, IDC_LOGIN_CSH_PASS_TXT, hInst, 0
    mov hEditCshPass, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBody, 1
    invoke AddControlToScreen1Csh, ebx

    ; Csh Login Button
    invoke CreateWindowExA, 0, offset szButtonClass, offset szCshSubmitBtn,
           WS_CHILD or BS_OWNERDRAW,
           32, 264, 180, 38, hParent, IDC_LOGIN_CSH_SUBMIT, hInst, 0
    mov hBtnCshLogin, eax
    invoke AddControlToScreen1Csh, eax

    ; Csh Create Account Button (first-time cashier setup)
    invoke CreateWindowExA, 0, offset szButtonClass, offset szCshCreateBtn,
           WS_CHILD or BS_OWNERDRAW,
           224, 264, 230, 38, hParent, IDC_LOGIN_CSH_CREATE, hInst, 0
    mov hBtnCshCreate, eax
    invoke AddControlToScreen1Csh, eax

    ; Csh Notice Static
    invoke CreateWindowExA, 0, offset szStaticClass, offset szCshNoticeText,
           WS_CHILD or SS_LEFT,
           32, 320, 700, 60, hParent, 0, hInst, 0
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBody, 1
    invoke AddControlToScreen1Csh, ebx

    ; === SCREEN 2 CONTROLS (Registration) ===
    mov nControlsScreen2, 0

    ; 1. Full Name Label & Edit
    invoke CreateWindowExA, 0, offset szStaticClass, offset szRegNameLbl,
           WS_CHILD or SS_LEFT, 40, 88, 250, 18, hParent, IDC_REG_NAME_LBL, hInst, 0
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddControlToScreen, 2, ebx

    invoke CreateWindowExA, 0, offset szEditClass, 0,
           WS_CHILD or WS_BORDER or ES_AUTOHSCROLL,
           40, 108, 380, 26, hParent, IDC_REG_NAME_TXT, hInst, 0
    mov hEditRegName, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBody, 1
    invoke AddControlToScreen, 2, ebx

    ; 2. Username Label & Edit
    invoke CreateWindowExA, 0, offset szStaticClass, offset szRegUserLbl,
           WS_CHILD or SS_LEFT, 40, 142, 250, 18, hParent, IDC_REG_USER_LBL, hInst, 0
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddControlToScreen, 2, ebx

    invoke CreateWindowExA, 0, offset szEditClass, 0,
           WS_CHILD or WS_BORDER or ES_AUTOHSCROLL,
           40, 162, 380, 26, hParent, IDC_REG_USER_TXT, hInst, 0
    mov hEditRegUser, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBody, 1
    invoke AddControlToScreen, 2, ebx

    ; 3. Password Label & Edit
    invoke CreateWindowExA, 0, offset szStaticClass, offset szRegPassLbl,
           WS_CHILD or SS_LEFT, 40, 196, 250, 18, hParent, IDC_REG_PASS_LBL, hInst, 0
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddControlToScreen, 2, ebx

    invoke CreateWindowExA, 0, offset szEditClass, 0,
           WS_CHILD or WS_BORDER or ES_PASSWORD or ES_AUTOHSCROLL,
           40, 216, 380, 26, hParent, IDC_REG_PASS_TXT, hInst, 0
    mov hEditRegPass, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBody, 1
    invoke AddControlToScreen, 2, ebx

    ; 4. Confirm Password Label & Edit
    invoke CreateWindowExA, 0, offset szStaticClass, offset szRegConfirmLbl,
           WS_CHILD or SS_LEFT, 40, 250, 250, 18, hParent, IDC_REG_CONFIRM_LBL, hInst, 0
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddControlToScreen, 2, ebx

    invoke CreateWindowExA, 0, offset szEditClass, 0,
           WS_CHILD or WS_BORDER or ES_PASSWORD or ES_AUTOHSCROLL,
           40, 270, 380, 26, hParent, IDC_REG_CONFIRM_TXT, hInst, 0
    mov hEditRegConfirm, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBody, 1
    invoke AddControlToScreen, 2, ebx

    ; 5. CNIC Label & Edit
    invoke CreateWindowExA, 0, offset szStaticClass, offset szRegCnicLbl,
           WS_CHILD or SS_LEFT, 480, 88, 250, 18, hParent, IDC_REG_CNIC_LBL, hInst, 0
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddControlToScreen, 2, ebx

    invoke CreateWindowExA, 0, offset szEditClass, 0,
           WS_CHILD or WS_BORDER or ES_AUTOHSCROLL,
           480, 108, 380, 26, hParent, IDC_REG_CNIC_TXT, hInst, 0
    mov hEditRegCnic, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBody, 1
    invoke AddControlToScreen, 2, ebx

    ; 6. Phone Label & Edit
    invoke CreateWindowExA, 0, offset szStaticClass, offset szRegPhoneLbl,
           WS_CHILD or SS_LEFT, 480, 142, 250, 18, hParent, IDC_REG_PHONE_LBL, hInst, 0
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddControlToScreen, 2, ebx

    invoke CreateWindowExA, 0, offset szEditClass, 0,
           WS_CHILD or WS_BORDER or ES_AUTOHSCROLL,
           480, 162, 380, 26, hParent, IDC_REG_PHONE_TXT, hInst, 0
    mov hEditRegPhone, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBody, 1
    invoke AddControlToScreen, 2, ebx

    ; 7. Initial Deposit Label & Edit
    invoke CreateWindowExA, 0, offset szStaticClass, offset szRegDepositLbl,
           WS_CHILD or SS_LEFT, 480, 196, 250, 18, hParent, IDC_REG_DEPOSIT_LBL, hInst, 0
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddControlToScreen, 2, ebx

    invoke CreateWindowExA, 0, offset szEditClass, 0,
           WS_CHILD or WS_BORDER or ES_AUTOHSCROLL,
           480, 216, 380, 26, hParent, IDC_REG_DEPOSIT_TXT, hInst, 0
    mov hEditRegDeposit, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBody, 1
    invoke AddControlToScreen, 2, ebx

    ; 8. Cover Image Label, ReadOnly Edit & Browse Button
    invoke CreateWindowExA, 0, offset szStaticClass, offset szRegCoverLbl,
           WS_CHILD or SS_LEFT, 480, 250, 250, 18, hParent, IDC_REG_COVER_LBL, hInst, 0
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddControlToScreen, 2, ebx

    invoke CreateWindowExA, 0, offset szEditClass, 0,
           WS_CHILD or WS_BORDER or ES_READONLY or ES_AUTOHSCROLL,
           480, 270, 240, 26, hParent, IDC_REG_COVER_TXT, hInst, 0
    mov hEditRegCover, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBody, 1
    invoke AddControlToScreen, 2, ebx

    invoke CreateWindowExA, 0, offset szButtonClass, offset szRegBrowseBtn,
           WS_CHILD or BS_OWNERDRAW,
           730, 269, 130, 28, hParent, IDC_REG_BROWSE, hInst, 0
    mov hBtnRegBrowse, eax
    invoke AddControlToScreen, 2, eax

    ; 9. Submit Button
    invoke CreateWindowExA, 0, offset szButtonClass, offset szRegSubmitBtn,
           WS_CHILD or BS_OWNERDRAW,
           40, 324, 280, 38, hParent, IDC_REG_SUBMIT, hInst, 0
    mov hBtnRegSubmit, eax
    invoke AddControlToScreen, 2, eax

    ; 10. Back Button
    invoke CreateWindowExA, 0, offset szButtonClass, offset szRegBackBtn,
           WS_CHILD or BS_OWNERDRAW,
           330, 324, 160, 38, hParent, IDC_REG_BACK, hInst, 0
    mov hBtnRegBack, eax
    invoke AddControlToScreen, 2, eax

    ; 11. Notice Static
    invoke CreateWindowExA, 0, offset szStaticClass, offset szRegNoticeText,
           WS_CHILD or SS_LEFT,
           40, 380, 820, 38, hParent, 0, hInst, 0
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBody, 1
    invoke AddControlToScreen, 2, ebx

    ; 12. Status Static
    invoke CreateWindowExA, 0, offset szStaticClass, offset szStatusReady,
           WS_CHILD or SS_LEFT,
           32, 590, 896, 22, hParent, IDC_REG_STATUS, hInst, 0
    mov hStatusScreen2, eax
    invoke SendMessageA, eax, WM_SETFONT, hFontBody, 1
    invoke AddControlToScreen, 2, hStatusScreen2

    ; === SCREEN 3 CONTROLS (Depositor Dashboard) ===
    mov nControlsScreen3, 0

    ; Group 1: Profile & Vault Information
    invoke CreateWindowExA, 0, offset szStaticClass, offset szDepProfileGrp,
           WS_CHILD or SS_LEFT,
           50, 97, 400, 22, hParent, 0, hInst, 0
    mov hDepProfileGrp, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddControlToScreen, 3, ebx

    ; Account Number Label & Display
    invoke CreateWindowExA, 0, offset szStaticClass, offset szDepAccLbl,
           WS_CHILD or SS_LEFT, 52, 122, 130, 20, hParent, 0, hInst, 0
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddControlToScreen, 3, ebx

    invoke CreateWindowExA, 0, offset szStaticClass, offset szEmptyStr,
           WS_CHILD or SS_LEFT, 190, 122, 250, 20, hParent, IDC_DEP_INFO_ACC_LBL, hInst, 0
    mov hDepInfoAcc, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBody, 1
    invoke AddControlToScreen, 3, ebx

    ; Account Holder Label & Display
    invoke CreateWindowExA, 0, offset szStaticClass, offset szDepHolderLbl,
           WS_CHILD or SS_LEFT, 52, 160, 130, 20, hParent, 0, hInst, 0
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddControlToScreen, 3, ebx

    invoke CreateWindowExA, 0, offset szStaticClass, offset szEmptyStr,
           WS_CHILD or SS_LEFT, 190, 160, 250, 20, hParent, IDC_DEP_INFO_NAME_LBL, hInst, 0
    mov hDepInfoName, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBody, 1
    invoke AddControlToScreen, 3, ebx

    ; CNIC Label & Display
    invoke CreateWindowExA, 0, offset szStaticClass, offset szDepCnicLbl,
           WS_CHILD or SS_LEFT, 52, 198, 130, 20, hParent, 0, hInst, 0
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddControlToScreen, 3, ebx

    invoke CreateWindowExA, 0, offset szStaticClass, offset szEmptyStr,
           WS_CHILD or SS_LEFT, 190, 198, 250, 20, hParent, IDC_DEP_INFO_CNIC_LBL, hInst, 0
    mov hDepInfoCnic, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBody, 1
    invoke AddControlToScreen, 3, ebx

    ; Phone Label & Display
    invoke CreateWindowExA, 0, offset szStaticClass, offset szDepPhoneLbl,
           WS_CHILD or SS_LEFT, 52, 236, 130, 20, hParent, 0, hInst, 0
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddControlToScreen, 3, ebx

    invoke CreateWindowExA, 0, offset szStaticClass, offset szEmptyStr,
           WS_CHILD or SS_LEFT, 190, 236, 250, 20, hParent, IDC_DEP_INFO_PHONE_LBL, hInst, 0
    mov hDepInfoPhone, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBody, 1
    invoke AddControlToScreen, 3, ebx

    ; Current Balance Label & Display
    invoke CreateWindowExA, 0, offset szStaticClass, offset szDepBalLbl,
           WS_CHILD or SS_LEFT, 52, 280, 130, 24, hParent, 0, hInst, 0
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddControlToScreen, 3, ebx

    invoke CreateWindowExA, 0, offset szStaticClass, offset szEmptyStr,
           WS_CHILD or SS_LEFT, 190, 276, 250, 28, hParent, IDC_DEP_INFO_BAL_LBL, hInst, 0
    mov hDepInfoBal, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontHeader, 1
    invoke AddControlToScreen, 3, ebx

    ; Refresh Balance Button
    invoke CreateWindowExA, 0, offset szButtonClass, offset szDepRefreshBtnText,
           WS_CHILD or BS_OWNERDRAW,
           52, 360, 170, 38, hParent, IDC_DEP_REFRESH_BTN, hInst, 0
    mov hDepRefreshBtn, eax
    invoke AddControlToScreen, 3, eax

    ; Logout Button
    invoke CreateWindowExA, 0, offset szButtonClass, offset szDepLogoutBtnText,
           WS_CHILD or BS_OWNERDRAW,
           240, 360, 140, 38, hParent, IDC_DEP_LOGOUT_BTN, hInst, 0
    mov hDepLogoutBtn, eax
    invoke AddControlToScreen, 3, eax

    ; Group 2: Transaction Dispatch Panel
    invoke CreateWindowExA, 0, offset szStaticClass, offset szDepTxnGrpTitle,
           WS_CHILD or SS_LEFT,
           508, 97, 400, 22, hParent, IDC_DEP_TXN_GRP, hInst, 0
    mov hDepTxnGrp, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddControlToScreen, 3, ebx

    ; Radio 1: Deposit
    invoke CreateWindowExA, 0, offset szButtonClass, offset szDepRadioDepText,
           WS_CHILD or BS_AUTORADIOBUTTON or WS_GROUP,
           520, 130, 160, 24, hParent, IDC_DEP_TXN_RADIO_DEP, hInst, 0
    mov hDepTxnRadioDep, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddControlToScreen, 3, ebx

    ; Radio 2: Withdraw
    invoke CreateWindowExA, 0, offset szButtonClass, offset szDepRadioWdrText,
           WS_CHILD or BS_AUTORADIOBUTTON,
           700, 130, 160, 24, hParent, IDC_DEP_TXN_RADIO_WDR, hInst, 0
    mov hDepTxnRadioWdr, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddControlToScreen, 3, ebx

    ; Transaction Amount Label & Edit
    invoke CreateWindowExA, 0, offset szStaticClass, offset szDepTxnAmtLblText,
           WS_CHILD or SS_LEFT, 520, 180, 250, 18, hParent, IDC_DEP_TXN_AMT_LBL, hInst, 0
    mov hDepTxnAmtLbl, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddControlToScreen, 3, ebx

    invoke CreateWindowExA, 0, offset szEditClass, 0,
           WS_CHILD or WS_BORDER or ES_AUTOHSCROLL,
           520, 204, 370, 28, hParent, IDC_DEP_TXN_AMT_TXT, hInst, 0
    mov hDepTxnAmt, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBody, 1
    invoke AddControlToScreen, 3, ebx

    ; Submit Transaction Request Button
    invoke CreateWindowExA, 0, offset szButtonClass, offset szDepTxnSubmitText,
           WS_CHILD or BS_OWNERDRAW,
           520, 254, 270, 40, hParent, IDC_DEP_TXN_SUBMIT_BTN, hInst, 0
    mov hDepTxnSubmitBtn, eax
    invoke AddControlToScreen, 3, eax

    ; Transaction Notice
    invoke CreateWindowExA, 0, offset szStaticClass, offset szDepTxnNoticeText,
           WS_CHILD or SS_LEFT,
           520, 314, 390, 90, hParent, 0, hInst, 0
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBody, 1
    invoke AddControlToScreen, 3, ebx

    ; Screen 3 Status Line
    invoke CreateWindowExA, 0, offset szStaticClass, offset szStatusReady,
           WS_CHILD or SS_LEFT,
           32, 590, 896, 22, hParent, IDC_DEP_STATUS, hInst, 0
    mov hStatusScreen3, eax
    invoke SendMessageA, eax, WM_SETFONT, hFontBody, 1
    invoke AddControlToScreen, 3, hStatusScreen3

    ; === SCREEN 4 CONTROLS (CASHIER CONTROL PANEL) ===
    ; 1. Alert Banner
    invoke CreateWindowExA, 0, offset szStaticClass, offset szNoPendingAlert,
           WS_CHILD or SS_LEFT, 32, 82, 750, 22, hParent, IDC_CSH_ALERT_LBL, hInst, 0
    mov hCshAlertLbl, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddControlToScreen, 4, ebx

    ; 2. Logout Button
    invoke CreateWindowExA, 0, offset szButtonClass, offset szCshLogoutBtnText,
           WS_CHILD or BS_OWNERDRAW,
           800, 78, 125, 30, hParent, IDC_CSH_LOGOUT_BTN, hInst, 0
    mov hCshLogoutBtn, eax
    invoke AddControlToScreen, 4, eax

    ; 3. Requests List Label
    invoke CreateWindowExA, 0, offset szStaticClass, offset szCshReqListTitle,
           WS_CHILD or SS_LEFT, 32, 118, 450, 20, hParent, IDC_CSH_REQ_LIST_LBL, hInst, 0
    mov hCshReqListLbl, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddControlToScreen, 4, ebx

    ; 4. Requests List Box
    invoke CreateWindowExA, 0, offset szListBoxClass, 0,
           WS_CHILD or WS_BORDER or WS_VSCROLL or LBS_NOTIFY or LBS_NOINTEGRALHEIGHT or LBS_OWNERDRAWFIXED or LBS_HASSTRINGS,
           32, 140, 450, 196, hParent, IDC_CSH_REQ_LIST, hInst, 0
    mov hCshReqList, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBody, 1
    invoke AddControlToScreen, 4, ebx

    ; 5. Approve Button
    invoke CreateWindowExA, 0, offset szButtonClass, offset szCshApproveBtnText,
           WS_CHILD or BS_OWNERDRAW,
           32, 346, 220, 36, hParent, IDC_CSH_APPROVE_BTN, hInst, 0
    mov hCshApproveBtn, eax
    invoke AddControlToScreen, 4, eax

    ; 6. Reject Button
    invoke CreateWindowExA, 0, offset szButtonClass, offset szCshRejectBtnText,
           WS_CHILD or BS_OWNERDRAW,
           262, 346, 220, 36, hParent, IDC_CSH_REJECT_BTN, hInst, 0
    mov hCshRejectBtn, eax
    invoke AddControlToScreen, 4, eax

    ; 7. Manual Adjustment Group Box
    invoke CreateWindowExA, 0, offset szStaticClass, offset szCshManualGrpTitle,
           WS_CHILD or SS_LEFT,
           40, 410, 400, 22, hParent, IDC_CSH_MANUAL_FRAME, hInst, 0
    mov hCshManualGrp, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddCshMan, ebx

    ; 8. Radio: Deposit
    invoke CreateWindowExA, 0, offset szButtonClass, offset szCshRadioDepText,
           WS_CHILD or BS_AUTORADIOBUTTON or WS_GROUP,
           52, 440, 150, 24, hParent, IDC_CSH_RADIO_DEP, hInst, 0
    mov hCshRadioDep, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddCshMan, ebx

    ; 9. Radio: Withdraw
    invoke CreateWindowExA, 0, offset szButtonClass, offset szCshRadioWdrText,
           WS_CHILD or BS_AUTORADIOBUTTON,
           220, 440, 150, 24, hParent, IDC_CSH_RADIO_WITH, hInst, 0
    mov hCshRadioWdr, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddCshMan, ebx

    ; 10. Manual Amount Label
    invoke CreateWindowExA, 0, offset szStaticClass, offset szCshManualAmtLbl,
           WS_CHILD or SS_LEFT, 52, 470, 200, 18, hParent, 0, hInst, 0
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddCshMan, ebx

    ; 11. Manual Amount Edit
    invoke CreateWindowExA, 0, offset szEditClass, 0,
           WS_CHILD or WS_BORDER or ES_AUTOHSCROLL,
           52, 492, 190, 28, hParent, IDC_CSH_MANUAL_AMT, hInst, 0
    mov hCshManualAmt, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBody, 1
    invoke AddCshMan, ebx

    ; 12. Apply Adjustment Button
    invoke CreateWindowExA, 0, offset szButtonClass, offset szCshApplyBtnText,
           WS_CHILD or BS_OWNERDRAW,
           252, 488, 215, 34, hParent, IDC_CSH_APPLY_BTN, hInst, 0
    mov hCshApplyBtn, eax
    invoke AddCshMan, eax

    ; 13. Registered Depositors Label
    invoke CreateWindowExA, 0, offset szStaticClass, offset szCshDepListTitle,
           WS_CHILD or SS_LEFT, 510, 118, 230, 20, hParent, IDC_CSH_DEP_LIST_LBL, hInst, 0
    mov hCshDepListLbl, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddControlToScreen, 4, ebx

    ; 14. Open Vault Image Button
    invoke CreateWindowExA, 0, offset szButtonClass, offset szCshOpenImgBtnText,
           WS_CHILD or BS_OWNERDRAW,
           745, 114, 180, 26, hParent, IDC_CSH_OPEN_IMG_BTN, hInst, 0
    mov hCshOpenImgBtn, eax
    invoke AddControlToScreen, 4, eax

    ; 15. Depositors List Box
    invoke CreateWindowExA, 0, offset szListBoxClass, 0,
           WS_CHILD or WS_BORDER or WS_VSCROLL or LBS_NOTIFY or LBS_NOINTEGRALHEIGHT or LBS_OWNERDRAWFIXED or LBS_HASSTRINGS,
           510, 142, 190, 172, hParent, IDC_CSH_DEP_LIST, hInst, 0
    mov hCshDepList, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBody, 1
    invoke AddControlToScreen, 4, ebx

    ; Vault image preview (owner-drawn): shows the stego image without revealing data
    invoke CreateWindowExA, 0, offset szStaticClass, 0,
           WS_CHILD or SS_OWNERDRAW,
           712, 142, 213, 172, hParent, IDC_CSH_PREVIEW, hInst, 0
    mov hCshPreview, eax
    invoke AddControlToScreen, 4, eax

    ; 16. Details Group Box
    invoke CreateWindowExA, 0, offset szStaticClass, offset szCshDetailGrpTitle,
           WS_CHILD or SS_LEFT,
           518, 338, 400, 22, hParent, 0, hInst, 0
    mov hCshDetailGrp, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddCshDet, ebx

    ; 17. Detail: Account Number
    invoke CreateWindowExA, 0, offset szStaticClass, offset szCshDetailAccLbl,
           WS_CHILD or SS_LEFT, 525, 366, 120, 18, hParent, 0, hInst, 0
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddCshDet, ebx

    invoke CreateWindowExA, 0, offset szStaticClass, offset szEmptyStr,
           WS_CHILD or SS_LEFT, 655, 366, 255, 18, hParent, IDC_CSH_DETAIL_ACC, hInst, 0
    mov hCshDetailAcc, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBody, 1
    invoke AddCshDet, ebx

    ; 18. Detail: Full Name
    invoke CreateWindowExA, 0, offset szStaticClass, offset szCshDetailNameLbl,
           WS_CHILD or SS_LEFT, 525, 394, 120, 18, hParent, 0, hInst, 0
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddCshDet, ebx

    invoke CreateWindowExA, 0, offset szStaticClass, offset szEmptyStr,
           WS_CHILD or SS_LEFT, 655, 394, 255, 18, hParent, IDC_CSH_DETAIL_NAME, hInst, 0
    mov hCshDetailName, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBody, 1
    invoke AddCshDet, ebx

    ; 19. Detail: Username
    invoke CreateWindowExA, 0, offset szStaticClass, offset szCshDetailUserLbl,
           WS_CHILD or SS_LEFT, 525, 422, 120, 18, hParent, 0, hInst, 0
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddCshDet, ebx

    invoke CreateWindowExA, 0, offset szStaticClass, offset szEmptyStr,
           WS_CHILD or SS_LEFT, 655, 422, 255, 18, hParent, IDC_CSH_DETAIL_USER, hInst, 0
    mov hCshDetailUser, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBody, 1
    invoke AddCshDet, ebx

    ; 20. Detail: CNIC
    invoke CreateWindowExA, 0, offset szStaticClass, offset szCshDetailCnicLbl,
           WS_CHILD or SS_LEFT, 525, 450, 120, 18, hParent, 0, hInst, 0
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddCshDet, ebx

    invoke CreateWindowExA, 0, offset szStaticClass, offset szEmptyStr,
           WS_CHILD or SS_LEFT, 655, 450, 255, 18, hParent, IDC_CSH_DETAIL_CNIC, hInst, 0
    mov hCshDetailCnic, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBody, 1
    invoke AddCshDet, ebx

    ; 21. Detail: Phone
    invoke CreateWindowExA, 0, offset szStaticClass, offset szCshDetailPhoneLbl,
           WS_CHILD or SS_LEFT, 525, 478, 120, 18, hParent, 0, hInst, 0
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddCshDet, ebx

    invoke CreateWindowExA, 0, offset szStaticClass, offset szEmptyStr,
           WS_CHILD or SS_LEFT, 655, 478, 255, 18, hParent, IDC_CSH_DETAIL_PHONE, hInst, 0
    mov hCshDetailPhone, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBody, 1
    invoke AddCshDet, ebx

    ; 22. Detail: Balance
    invoke CreateWindowExA, 0, offset szStaticClass, offset szCshDetailBalLbl,
           WS_CHILD or SS_LEFT, 525, 508, 120, 22, hParent, 0, hInst, 0
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke AddCshDet, ebx

    invoke CreateWindowExA, 0, offset szStaticClass, offset szEmptyStr,
           WS_CHILD or SS_LEFT, 655, 500, 255, 32, hParent, IDC_CSH_DETAIL_BAL, hInst, 0
    mov hCshDetailBal, eax
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontHeader, 1
    invoke AddCshDet, ebx

    ; 23. Security Notice
    invoke CreateWindowExA, 0, offset szStaticClass, offset szCshSecNoticeText,
           WS_CHILD or SS_LEFT, 525, 542, 385, 36, hParent, 0, hInst, 0
    mov ebx, eax
    invoke SendMessageA, ebx, WM_SETFONT, hFontBody, 1
    invoke AddCshDet, ebx

    ; 24. Screen 4 Status Line
    invoke CreateWindowExA, 0, offset szStaticClass, offset szStatusReady,
           WS_CHILD or SS_LEFT, 32, 590, 896, 22, hParent, IDC_CSH_STATUS, hInst, 0
    mov hStatusScreen4, eax
    invoke SendMessageA, eax, WM_SETFONT, hFontBody, 1
    invoke AddControlToScreen, 4, hStatusScreen4

    ; Input length limits so text can never be silently truncated by the
    ; fixed-size buffers in the login / registration pipelines (limit = max chars)
    invoke SendMessageA, hEditDepUser, EM_SETLIMITTEXT, 31, 0
    invoke SendMessageA, hEditDepPass, EM_SETLIMITTEXT, 31, 0
    invoke SendMessageA, hEditCshUser, EM_SETLIMITTEXT, 31, 0
    invoke SendMessageA, hEditCshPass, EM_SETLIMITTEXT, 31, 0
    invoke SendMessageA, hEditRegName, EM_SETLIMITTEXT, 63, 0
    invoke SendMessageA, hEditRegUser, EM_SETLIMITTEXT, 31, 0
    invoke SendMessageA, hEditRegPass, EM_SETLIMITTEXT, 31, 0
    invoke SendMessageA, hEditRegConfirm, EM_SETLIMITTEXT, 31, 0
    invoke SendMessageA, hEditRegCnic, EM_SETLIMITTEXT, 15, 0
    invoke SendMessageA, hEditRegPhone, EM_SETLIMITTEXT, 15, 0
    invoke SendMessageA, hEditRegDeposit, EM_SETLIMITTEXT, 9, 0

    mov eax, SV_OK
    ret
BuildScreens ENDP

; ------------------------------------------------------------------------------
; InitGuiResources: Creates application fonts and solid brushes
; Outputs: EAX = SV_OK
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
InitGuiResources PROC USES ebx esi edi
    ; Header font: Segoe UI, -22, Bold
    invoke CreateFontA, -22, 0, 0, 0, FW_BOLD, 0, 0, 0,
           DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
           CLEARTYPE_QUALITY, DEFAULT_PITCH or FF_DONTCARE, offset szFontSegoe
    mov hFontHeader, eax

    ; Body font: Segoe UI, -14, Normal
    invoke CreateFontA, -14, 0, 0, 0, FW_NORMAL, 0, 0, 0,
           DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
           CLEARTYPE_QUALITY, DEFAULT_PITCH or FF_DONTCARE, offset szFontSegoe
    mov hFontBody, eax

    ; Bold body font: Segoe UI, -14, Bold
    invoke CreateFontA, -14, 0, 0, 0, FW_BOLD, 0, 0, 0,
           DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
           CLEARTYPE_QUALITY, DEFAULT_PITCH or FF_DONTCARE, offset szFontSegoe
    mov hFontBold, eax

    ; Brand font: Georgia, -26, Bold (header wordmark)
    invoke CreateFontA, -26, 0, 0, 0, FW_BOLD, 0, 0, 0,
           DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
           CLEARTYPE_QUALITY, DEFAULT_PITCH or FF_DONTCARE, offset szFontGeorgia
    mov hFontBrand, eax

    ; Brushes
    invoke CreateSolidBrush, COLOR_CANVAS
    mov hbrCanvas, eax

    invoke CreateSolidBrush, COLOR_HEADER
    mov hbrHeader, eax

    invoke CreateSolidBrush, COLOR_INPUT
    mov hbrInput, eax

    invoke CreateSolidBrush, COLOR_STEEL
    mov hbrSteel, eax

    invoke CreateSolidBrush, COLOR_BTN_PRESS
    mov hbrSteelDark, eax

    invoke CreateSolidBrush, COLOR_BORDER
    mov hbrBorder, eax

    mov eax, SV_OK
    ret
InitGuiResources ENDP

; ------------------------------------------------------------------------------
; FreeGuiResources: Deletes application fonts and solid brushes
; Outputs: EAX = SV_OK
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
FreeGuiResources PROC USES ebx esi edi
    cmp hPreviewBmp, 0
    je noPreviewToFree
    invoke DeleteObject, hPreviewBmp
    mov hPreviewBmp, 0
noPreviewToFree:
    .IF hFontHeader != 0
        invoke DeleteObject, hFontHeader
        mov hFontHeader, 0
    .ENDIF
    .IF hFontBody != 0
        invoke DeleteObject, hFontBody
        mov hFontBody, 0
    .ENDIF
    .IF hFontBold != 0
        invoke DeleteObject, hFontBold
        mov hFontBold, 0
    .ENDIF
    .IF hFontBrand != 0
        invoke DeleteObject, hFontBrand
        mov hFontBrand, 0
    .ENDIF

    .IF hbrCanvas != 0
        invoke DeleteObject, hbrCanvas
        mov hbrCanvas, 0
    .ENDIF
    .IF hbrHeader != 0
        invoke DeleteObject, hbrHeader
        mov hbrHeader, 0
    .ENDIF
    .IF hbrInput != 0
        invoke DeleteObject, hbrInput
        mov hbrInput, 0
    .ENDIF
    .IF hbrSteel != 0
        invoke DeleteObject, hbrSteel
        mov hbrSteel, 0
    .ENDIF
    .IF hbrSteelDark != 0
        invoke DeleteObject, hbrSteelDark
        mov hbrSteelDark, 0
    .ENDIF
    .IF hbrBorder != 0
        invoke DeleteObject, hbrBorder
        mov hbrBorder, 0
    .ENDIF

    mov eax, SV_OK
    ret
FreeGuiResources ENDP



; ------------------------------------------------------------------------------
; DrawOwnerItem: Custom button rendering (steel background, white text, pressed state)
; Inputs:  hParentWnd (DWORD), pDrawItem (DWORD ptr to DRAWITEMSTRUCT)
; Outputs: EAX = 1 (handled)
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
DrawOwnerItem PROC USES ebx esi edi hParentWnd:DWORD, pDrawItem:DWORD
    LOCAL szBtnText[128]:BYTE
    LOCAL rcText:RECT
    LOCAL clrFill:DWORD
    LOCAL clrText:DWORD
    LOCAL isPrimary:DWORD
    LOCAL isTab:DWORD
    LOCAL isActive:DWORD
    LOCAL isHover:DWORD

    mov eax, hParentWnd
    mov esi, pDrawItem
    cmp DWORD PTR [esi], ODT_STATIC     ; DRAWITEMSTRUCT.CtlType
    jne notStaticItem
    invoke DrawPreviewItem, esi
    mov eax, 1
    ret
notStaticItem:
    cmp DWORD PTR [esi], ODT_LISTBOX
    jne notListItem
    invoke DrawListItem, esi
    mov eax, 1
    ret
notListItem:
    assume esi:PTR DRAWITEMSTRUCT

    mov clrFill, COLOR_STEEL
    mov clrText, COLOR_WHITE
    mov isPrimary, 0
    mov isTab, 0
    mov isActive, 0
    mov isHover, 0
    mov eax, [esi].hwndItem
    .IF eax != 0 && eax == hHoverCtl
        mov isHover, 1
    .ENDIF

    mov edx, [esi].CtlID
    .IF edx == IDC_LOGIN_TAB_DEP
        mov isTab, 1
        .IF curRole == ROLE_DEPOSITOR
            mov isActive, 1
        .ENDIF
    .ELSEIF edx == IDC_LOGIN_TAB_CSH
        mov isTab, 1
        .IF curRole == ROLE_CASHIER
            mov isActive, 1
        .ENDIF
    .ELSEIF edx == IDC_LOGIN_DEP_SUBMIT || edx == IDC_LOGIN_CSH_SUBMIT || edx == IDC_REG_SUBMIT || edx == IDC_DEP_TXN_SUBMIT_BTN || edx == IDC_CSH_APPROVE_BTN || edx == IDC_CSH_APPLY_BTN || edx == IDC_DLG_BTN1
        mov isPrimary, 1
    .ENDIF

    .IF isTab == 1
        .IF isActive == 1
            mov clrFill, COLOR_HEADER
        .ELSE
            mov clrFill, COLOR_TAB_OFF
            mov clrText, COLOR_SLATE
            .IF isHover == 1
                mov clrFill, COLOR_WHITE
                mov clrText, COLOR_TEXT
            .ENDIF
        .ENDIF
    .ELSEIF isPrimary == 1
        mov clrFill, COLOR_BRASS
        mov clrText, COLOR_INK
        .IF isHover == 1
            mov clrFill, COLOR_BRASS_LT
        .ENDIF
        test [esi].itemState, ODS_SELECTED
        jz primaryNotPressed
        mov clrFill, COLOR_BRASS_DK
        mov clrText, COLOR_WHITE
primaryNotPressed:
    .ELSE
        .IF isHover == 1
            mov clrFill, COLOR_BTN_HOVER
        .ENDIF
        test [esi].itemState, ODS_SELECTED
        jz plainNotPressed
        mov clrFill, COLOR_BTN_PRESS
plainNotPressed:
    .ENDIF

    invoke FillRc, [esi].hDC, [esi].rcItem.left, [esi].rcItem.top, [esi].rcItem.right, [esi].rcItem.bottom, clrFill

    ; Hover accent: brass underline on every non-tab button, soft top highlight
    .IF isHover == 1 && isTab == 0
        mov eax, [esi].rcItem.bottom
        sub eax, 3
        .IF isPrimary == 1
            invoke FillRc, [esi].hDC, [esi].rcItem.left, eax, [esi].rcItem.right, [esi].rcItem.bottom, COLOR_BRASS_DK
        .ELSE
            invoke FillRc, [esi].hDC, [esi].rcItem.left, eax, [esi].rcItem.right, [esi].rcItem.bottom, COLOR_BRASS
        .ENDIF
    .ENDIF

    ; Inactive tab gets a hairline border; the active tab a brass underline
    .IF isTab == 1
        .IF isActive == 1
            mov eax, [esi].rcItem.bottom
            sub eax, 3
            invoke FillRc, [esi].hDC, [esi].rcItem.left, eax, [esi].rcItem.right, [esi].rcItem.bottom, COLOR_BRASS
        .ELSE
            invoke FrameRc, [esi].hDC, [esi].rcItem.left, [esi].rcItem.top, [esi].rcItem.right, [esi].rcItem.bottom, COLOR_BORDER
        .ENDIF
    .ENDIF

    invoke GetWindowTextA, [esi].hwndItem, addr szBtnText, sizeof szBtnText

    mov eax, [esi].rcItem.left
    mov rcText.left, eax
    mov eax, [esi].rcItem.top
    mov rcText.top, eax
    mov eax, [esi].rcItem.right
    mov rcText.right, eax
    mov eax, [esi].rcItem.bottom
    mov rcText.bottom, eax

    test [esi].itemState, ODS_SELECTED
    jz drawLabel
    inc rcText.left
    inc rcText.top
    inc rcText.right
    inc rcText.bottom

drawLabel:
    invoke SetBkMode, [esi].hDC, TRANSPARENT
    invoke SetTextColor, [esi].hDC, clrText
    invoke SelectObject, [esi].hDC, hFontBold
    invoke DrawTextA, [esi].hDC, addr szBtnText, -1, addr rcText,
           DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX

    assume esi:NOTHING
    mov eax, 1
    ret
DrawOwnerItem ENDP

; ------------------------------------------------------------------------------
; SetStatus: Sets status text and color for the specified screen
; Inputs:  screenId (DWORD), pText (DWORD ptr), isError (DWORD)
; Outputs: EAX = SV_OK
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
SetStatus PROC USES ebx esi edi screenId:DWORD, pText:DWORD, isError:DWORD
    mov eax, screenId
    mov edx, isError

    .IF eax == 1
        mov statusErrScreen1, edx
        invoke SetWindowTextA, hStatusScreen1, pText
        invoke InvalidateRect, hStatusScreen1, 0, 1
    .ELSEIF eax == 2
        mov statusErrScreen2, edx
        invoke SetWindowTextA, hStatusScreen2, pText
        invoke InvalidateRect, hStatusScreen2, 0, 1
    .ELSEIF eax == 3
        mov statusErrScreen3, edx
        invoke SetWindowTextA, hStatusScreen3, pText
        invoke InvalidateRect, hStatusScreen3, 0, 1
    .ELSEIF eax == 4
        mov statusErrScreen4, edx
        invoke SetWindowTextA, hStatusScreen4, pText
        invoke InvalidateRect, hStatusScreen4, 0, 1
        invoke InvalidateRect, hMain, 0, 0
    .ENDIF

    ; Errors are also shown as a themed popup in the centre of the window
    .IF isError == 1
        invoke ThemedMsgBox, hMain, pText, offset szDlgErrTitle, MB_ICONERROR or MB_OK
    .ENDIF

    mov eax, SV_OK
    ret
SetStatus ENDP

; ------------------------------------------------------------------------------
; SwitchLoginTab: Switches visible controls between Depositor and Cashier login
; Inputs:  role (DWORD, ROLE_DEPOSITOR or ROLE_CASHIER)
; Outputs: EAX = SV_OK
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
SwitchLoginTab PROC USES ebx esi edi role:DWORD
    mov eax, role
    mov curRole, eax

    .IF eax == ROLE_CASHIER
        ; Hide Depositor controls
        xor ecx, ecx
hideDepLoop:
        cmp ecx, nControlsScreen1Dep
        jge doneHideDep
        push ecx
        mov edx, [hControlsScreen1Dep + ecx*4]
        invoke ShowWindow, edx, SW_HIDE
        pop ecx
        inc ecx
        jmp hideDepLoop
doneHideDep:
        ; Show Cashier controls
        xor ecx, ecx
showCshLoop:
        cmp ecx, nControlsScreen1Csh
        jge doneShowCsh
        push ecx
        mov edx, [hControlsScreen1Csh + ecx*4]
        invoke ShowWindow, edx, SW_SHOW
        pop ecx
        inc ecx
        jmp showCshLoop
doneShowCsh:
    .ELSE
        ; ROLE_DEPOSITOR
        ; Hide Cashier controls
        xor ecx, ecx
hideCshLoop:
        cmp ecx, nControlsScreen1Csh
        jge doneHideCsh
        push ecx
        mov edx, [hControlsScreen1Csh + ecx*4]
        invoke ShowWindow, edx, SW_HIDE
        pop ecx
        inc ecx
        jmp hideCshLoop
doneHideCsh:
        ; Show Depositor controls
        xor ecx, ecx
showDepLoop:
        cmp ecx, nControlsScreen1Dep
        jge doneShowDep
        push ecx
        mov edx, [hControlsScreen1Dep + ecx*4]
        invoke ShowWindow, edx, SW_SHOW
        pop ecx
        inc ecx
        jmp showDepLoop
doneShowDep:
    .ENDIF

    ; Invalidate tab buttons so active state updates
    invoke InvalidateRect, hBtnTabDep, 0, 1
    invoke InvalidateRect, hBtnTabCsh, 0, 1
    invoke RedrawWindow, hMain, 0, 0, RDW_FULL_REPAINT
    mov eax, SV_OK
    ret
SwitchLoginTab ENDP

; ------------------------------------------------------------------------------
; BrowseLoginImage: Opens OpenFileName dialog and puts selected path in edit control
; Inputs:  hwndParent (DWORD), hEditPath (DWORD)
; Outputs: EAX = 1 if file chosen, 0 if cancelled
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
BrowseLoginImage PROC USES ebx esi edi hwndParent:DWORD, hEditPath:DWORD
    LOCAL ofn:OPENFILENAMEA
    LOCAL szFile[MAX_PATH]:BYTE

    cld
    invoke SvWipe, addr ofn, sizeof OPENFILENAMEA
    invoke SvWipe, addr szFile, MAX_PATH

    mov ofn.lStructSize, sizeof OPENFILENAMEA
    mov eax, hwndParent
    mov ofn.hwndOwner, eax
    mov ofn.lpstrFilter, offset szBmpFilter
    lea eax, szFile
    mov ofn.lpstrFile, eax
    mov ofn.nMaxFile, MAX_PATH
    mov ofn.Flags, OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or OFN_NOCHANGEDIR
    mov ofn.lpstrTitle, offset szBrowseTitle

    invoke GetOpenFileNameA, addr ofn
    test eax, eax
    jz browseCanceled

    invoke SetWindowTextA, hEditPath, addr szFile
    mov eax, 1
    ret

browseCanceled:
    xor eax, eax
    ret
BrowseLoginImage ENDP

; ------------------------------------------------------------------------------
; BrowseCoverImage: Opens OpenFileName dialog for cover images (.bmp, .png, .jpg)
; Inputs:  hwndParent (DWORD), hEditPath (DWORD)
; Outputs: EAX = 1 if file chosen, 0 if cancelled
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
BrowseCoverImage PROC USES ebx esi edi hwndParent:DWORD, hEditPath:DWORD
    LOCAL ofn:OPENFILENAMEA
    LOCAL szFile[MAX_PATH]:BYTE

    cld
    invoke SvWipe, addr ofn, sizeof OPENFILENAMEA
    invoke SvWipe, addr szFile, MAX_PATH

    mov ofn.lStructSize, sizeof OPENFILENAMEA
    mov eax, hwndParent
    mov ofn.hwndOwner, eax
    mov ofn.lpstrFilter, offset szCoverFilter
    lea eax, szFile
    mov ofn.lpstrFile, eax
    mov ofn.nMaxFile, MAX_PATH
    mov ofn.Flags, OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or OFN_NOCHANGEDIR
    mov ofn.lpstrTitle, offset szBrowseCoverTitle

    invoke GetOpenFileNameA, addr ofn
    test eax, eax
    jz coverCanceled

    invoke SetWindowTextA, hEditPath, addr szFile
    mov eax, 1
    ret

coverCanceled:
    xor eax, eax
    ret
BrowseCoverImage ENDP

; ------------------------------------------------------------------------------
; DoRegister: Executes complete registration pipeline for Screen 2
; Inputs:  hwndParent (DWORD)
; Outputs: EAX = SV_OK or error
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
DoRegister PROC USES ebx esi edi hwndParent:DWORD
    LOCAL szName[64]:BYTE
    LOCAL szUser[32]:BYTE
    LOCAL szPass[32]:BYTE
    LOCAL szConfirm[32]:BYTE
    LOCAL szCnic[16]:BYTE
    LOCAL szPhone[16]:BYTE
    LOCAL szDeposit[16]:BYTE
    LOCAL szCoverPath[MAX_PATH]:BYTE
    LOCAL lowerUser[32]:BYTE
    LOCAL szOutPath[MAX_PATH]:BYTE
    LOCAL accNum[16]:BYTE
    LOCAL szDigits[16]:BYTE
    LOCAL szRegMsg[200]:BYTE

    LOCAL tempUserRec:USER_RECORD
    LOCAL userRec:USER_RECORD
    LOCAL accRec:ACCOUNT_RECORD

    LOCAL salt[16]:BYTE
    LOCAL dek[32]:BYTE
    LOCAL verifier[32]:BYTE
    LOCAL kekUser[32]:BYTE

    LOCAL pCoverBmp:DWORD
    LOCAL coverSize:DWORD
    LOCAL imgW:DWORD
    LOCAL imgH:DWORD
    LOCAL dwDeposit:DWORD
    LOCAL passLen:DWORD

    cld
    mov eax, hwndParent
    ; 1. Get texts from edit controls
    invoke GetWindowTextA, hEditRegName, addr szName, sizeof szName
    invoke GetWindowTextA, hEditRegUser, addr szUser, sizeof szUser
    invoke GetWindowTextA, hEditRegPass, addr szPass, sizeof szPass
    invoke GetWindowTextA, hEditRegConfirm, addr szConfirm, sizeof szConfirm
    invoke GetWindowTextA, hEditRegCnic, addr szCnic, sizeof szCnic
    invoke GetWindowTextA, hEditRegPhone, addr szPhone, sizeof szPhone
    invoke GetWindowTextA, hEditRegDeposit, addr szDeposit, sizeof szDeposit
    invoke GetWindowTextA, hEditRegCover, addr szCoverPath, sizeof szCoverPath

    ; 2. Validate Full Name (1..63 chars)
    invoke ValidateFullName, addr szName
    test eax, eax
    jnz nameOk
    invoke SetStatus, 2, offset szErrRegName, 1
    jmp regCleanupExit
nameOk:

    ; 3. Validate Username (3..31 chars, [A-Za-z0-9_], != "admin")
    invoke ValidateUsername, addr szUser
    test eax, eax
    jnz userOk
    invoke SetStatus, 2, offset szErrRegUser, 1
    jmp regCleanupExit
userOk:

    ; 4. Validate Password (6..31 chars)
    invoke ValidatePassword, addr szPass
    test eax, eax
    jnz passOk
    invoke SetStatus, 2, offset szErrRegPass, 1
    jmp regCleanupExit
passOk:

    ; 5. Confirm Password must match Password
    invoke lstrcmpA, addr szPass, addr szConfirm
    test eax, eax
    jz confirmOk
    invoke SetStatus, 2, offset szErrRegConfirm, 1
    jmp regCleanupExit
confirmOk:

    ; 6. Validate CNIC (ddddd-ddddddd-d)
    invoke ValidateCnic, addr szCnic
    test eax, eax
    jnz cnicOk
    invoke SetStatus, 2, offset szErrRegCnic, 1
    jmp regCleanupExit
cnicOk:

    ; 7. Validate Contact (10..15 digits, optional +)
    invoke ValidateContact, addr szPhone
    test eax, eax
    jnz phoneOk
    invoke SetStatus, 2, offset szErrRegPhone, 1
    jmp regCleanupExit
phoneOk:

    ; 8. Validate Initial Deposit (0..100,000,000, optional)
    cmp szDeposit[0], 0
    jne hasDeposit
    mov dwDeposit, 0
    jmp depositOk
hasDeposit:
    invoke AtoiDec, addr szDeposit
    test edx, edx
    jnz badDeposit
    cmp eax, MAX_TXN_AMOUNT
    ja badDeposit
    mov dwDeposit, eax
    jmp depositOk
badDeposit:
    invoke SetStatus, 2, offset szErrRegDeposit, 1
    jmp regCleanupExit
depositOk:

    ; 9. Validate Cover Image Selected
    cmp szCoverPath[0], 0
    jne coverSelected
    invoke SetStatus, 2, offset szErrRegCover, 1
    jmp regCleanupExit
coverSelected:

    ; 10. Check duplicate username in users.dat
    invoke UsersFind, addr szUser, addr tempUserRec
    test eax, eax
    jnz userNotFound
    ; Duplicate username found!
    invoke SetStatus, 2, offset szErrRegDuplicate, 1
    jmp regCleanupExit
userNotFound:

    ; 11. Generate Account Number: 1000 + count + 1 = 1001 + count
    invoke UsersCount
    cmp eax, -1
    jne countOk
    ; users.dat unusable. If Windows refused to open it, report the exact error.
    cmp usersLastErr, 0
    je usersSizeProblem
    invoke lstrcpyA, addr szRegMsg, offset szErrOpenUsers
    invoke lstrcatA, addr szRegMsg, offset szErrRepairCode
    invoke ItoaDec, usersLastErr, addr szDigits
    invoke lstrcatA, addr szRegMsg, addr szDigits
    invoke lstrcatA, addr szRegMsg, offset szCloseParen
    invoke SetStatus, 2, addr szRegMsg, 1
    jmp regCleanupExit
usersSizeProblem:
    ; Size is not a whole number of 96-byte records: offer an in-app repair
    invoke ThemedMsgBox, hwndParent, offset szAskRepairUsers, offset szBankTitle, MB_YESNO or MB_ICONQUESTION
    cmp eax, IDYES
    jne repairDeclined
    invoke UsersRepair
    cmp eax, SV_OK
    jne repairFailed
    invoke SetStatus, 2, offset szMsgUsersRepaired, 0
    jmp regCleanupExit
repairFailed:
    invoke lstrcpyA, addr szRegMsg, offset szErrUsersRepair
    invoke lstrcatA, addr szRegMsg, offset szErrRepairCode
    invoke ItoaDec, usersLastErr, addr szDigits
    invoke lstrcatA, addr szRegMsg, addr szDigits
    invoke lstrcatA, addr szRegMsg, offset szCloseParen
    invoke SetStatus, 2, addr szRegMsg, 1
    jmp regCleanupExit
repairDeclined:
    invoke SetStatus, 2, offset szErrUsersDamaged, 1
    jmp regCleanupExit
countOk:
    add eax, 1001
    mov ecx, eax
    invoke ItoaDec, ecx, addr szDigits
    lea edi, accNum
    mov BYTE PTR [edi], 'A'
    mov BYTE PTR [edi + 1], 'C'
    mov BYTE PTR [edi + 2], 'C'
    mov BYTE PTR [edi + 3], '-'
    lea edi, [accNum + 4]
    lea esi, szDigits
    invoke lstrcpyA, edi, esi

    ; 12. Convert cover image with GDI+ (large photos are scaled down first)
    invoke SetStatus, 2, offset szMsgRegWorking, 0
    invoke UpdateWindow, hStatusScreen2
    invoke LoadImageAsBmp, addr szCoverPath, addr coverSize
    test eax, eax
    jnz imgLoaded
    invoke SetStatus, 2, offset szErrRegDecode, 1
    jmp regCleanupExit
imgLoaded:
    mov pCoverBmp, eax

    ; Parse BMP and enforce min dimensions (64x64) and capacity
    invoke ParseBmp, pCoverBmp, coverSize, addr imgW, addr imgH, NULL, NULL
    .IF eax != SV_OK
        invoke GetProcessHeap
        invoke HeapFree, eax, 0, pCoverBmp
        invoke SetStatus, 2, offset szErrRegCapacity, 1
        jmp regCleanupExit
    .ENDIF

    .IF imgW < MIN_IMG_DIM || imgH < MIN_IMG_DIM
        invoke GetProcessHeap
        invoke HeapFree, eax, 0, pCoverBmp
        invoke SetStatus, 2, offset szErrRegCapacity, 1
        jmp regCleanupExit
    .ENDIF

    ; 13. Assemble Account Record (148 bytes)
    invoke SvWipe, addr accRec, ACC_REC_SIZE
    invoke lstrcpyA, addr accRec.AccountNumber, addr accNum
    invoke lstrcpyA, addr accRec.FullName, addr szName
    invoke lstrcpyA, addr accRec.Username, addr szUser
    invoke lstrcpyA, addr accRec.CNIC, addr szCnic
    invoke lstrcpyA, addr accRec.Contact, addr szPhone
    mov eax, dwDeposit
    mov accRec.Balance, eax

    ; 14. Lowercase username for filename and hashing
    lea esi, szUser
    lea edi, lowerUser
    xor ecx, ecx
regLowerLoop:
    cmp ecx, 32
    jae regLowerDone
    mov al, [esi + ecx]
    test al, al
    jz regLowerDone
    cmp al, 'A'
    jb regNotUp
    cmp al, 'Z'
    ja regNotUp
    add al, 32
regNotUp:
    mov [edi + ecx], al
    inc ecx
    jmp regLowerLoop
regLowerDone:
    mov BYTE PTR [edi + ecx], 0

    ; 15. Generate cryptographic keys
    invoke SvRandom, addr salt, 16
    invoke SvRandom, addr dek, 32
    invoke lstrlenA, addr szPass
    mov passLen, eax
    invoke SvDeriveKeys, addr salt, addr szPass, passLen, addr verifier, addr kekUser

    ; 16. Build and embed vault stream into BMP
    invoke BuildVaultImage, pCoverBmp, coverSize, addr accRec, addr dek, 1, addr kekUser, 0
    .IF eax != SV_OK
        invoke GetProcessHeap
        invoke HeapFree, eax, 0, pCoverBmp
        invoke SetStatus, 2, offset szErrRegBuild, 1
        jmp regCleanupExit
    .ENDIF

    ; 17. Atomic write to Vault_Images\<username lowercase>.bmp
    lea edi, szOutPath
    mov esi, offset szVaultImagesDir
    invoke lstrcpyA, edi, esi
    invoke lstrlenA, addr szOutPath
    lea edi, szOutPath
    add edi, eax
    lea esi, lowerUser
    invoke lstrcpyA, edi, esi
    invoke lstrlenA, addr szOutPath
    lea edi, szOutPath
    add edi, eax
    mov DWORD PTR [edi], 706D622Eh   ; ".bmp"
    mov BYTE PTR [edi + 4], 0

    invoke AtomicWriteFile, addr szOutPath, pCoverBmp, coverSize
    push eax
    ; Free in-memory BMP buffer
    invoke GetProcessHeap
    invoke HeapFree, eax, 0, pCoverBmp
    pop eax
    .IF eax != SV_OK
        invoke SetStatus, 2, offset szErrRegWrite, 1
        jmp regCleanupExit
    .ENDIF

    ; 18. Append to users.dat (96 bytes)
    invoke SvWipe, addr userRec, USER_REC_SIZE
    invoke lstrcpyA, addr userRec.Username, addr lowerUser
    lea esi, salt
    lea edi, userRec.Salt
    mov ecx, 16
    rep movsb
    lea esi, verifier
    lea edi, userRec.Verifier
    mov ecx, 32
    rep movsb
    mov userRec.LastNonce, 1

    invoke UsersAppend, addr userRec
    .IF eax != SV_OK
        ; Rollback: delete created BMP file
        invoke DeleteFileA, addr szOutPath
        invoke SetStatus, 2, offset szErrRegAppend, 1
        jmp regCleanupExit
    .ENDIF

    ; 19. Registration SUCCESS!
    ; Pre-populate Login screen with new account's username and image path
    invoke SetWindowTextA, hEditDepUser, addr szUser
    invoke SetWindowTextA, hEditDepImg, addr szOutPath
    invoke SetWindowTextA, hEditDepPass, offset szEmptyStr

    ; Clear registration form fields
    invoke SetWindowTextA, hEditRegName, offset szEmptyStr
    invoke SetWindowTextA, hEditRegUser, offset szEmptyStr
    invoke SetWindowTextA, hEditRegPass, offset szEmptyStr
    invoke SetWindowTextA, hEditRegConfirm, offset szEmptyStr
    invoke SetWindowTextA, hEditRegCnic, offset szEmptyStr
    invoke SetWindowTextA, hEditRegPhone, offset szEmptyStr
    invoke SetWindowTextA, hEditRegDeposit, offset szEmptyStr
    invoke SetWindowTextA, hEditRegCover, offset szEmptyStr

    ; Set success status on Login Screen
    invoke SetStatus, 1, offset szRegSuccess, 0

    ; Switch to Screen 1 (Login)
    invoke ShowScreen, SCREEN_LOGIN

regCleanupExit:
    ; Wipe sensitive data from stack
    invoke SvWipe, addr szPass, 32
    invoke SvWipe, addr szConfirm, 32
    invoke SvWipe, addr dek, 32
    invoke SvWipe, addr kekUser, 32
    invoke SvWipe, addr accRec, ACC_REC_SIZE
    invoke SvWipe, addr userRec, USER_REC_SIZE
    ret
DoRegister ENDP

; ------------------------------------------------------------------------------
; DoDepositorLogin: Executes 8-step authentication pipeline for Depositor
; Inputs:  hwndParent (DWORD)
; Outputs: EAX = SV_OK or error
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
DoDepositorLogin PROC USES ebx esi edi hwndParent:DWORD
    LOCAL szUser[32]:BYTE
    LOCAL szPass[32]:BYTE
    LOCAL szPath[MAX_PATH]:BYTE
    LOCAL uRec:USER_RECORD
    LOCAL verifierPrime[32]:BYTE
    LOCAL kekUser[32]:BYTE
    LOCAL outRec:ACCOUNT_RECORD
    LOCAL nonceOut:DWORD
    LOCAL passLen:DWORD
    LOCAL pBmp:DWORD
    LOCAL fileSize:DWORD
    LOCAL stream[256]:BYTE
    LOCAL szBalBuf[32]:BYTE
    LOCAL szBalFull[48]:BYTE

    cld
    mov eax, hwndParent
    ; 1. Get input texts
    invoke GetWindowTextA, hEditDepUser, addr szUser, sizeof szUser
    invoke GetWindowTextA, hEditDepPass, addr szPass, sizeof szPass
    invoke GetWindowTextA, hEditDepImg, addr szPath, sizeof szPath

    ; Pipeline Step 1: All three inputs present
    cmp szUser[0], 0
    je loginMissingInputs
    cmp szPass[0], 0
    je loginMissingInputs
    cmp szPath[0], 0
    je loginMissingInputs
    jmp loginInputsOk

loginMissingInputs:
    invoke SetStatus, 1, offset szErrLoginInputs, 1
    jmp loginCleanupExit

loginInputsOk:
    ; Pipeline Step 2: Find username in users.dat (case-insensitive)
    invoke UsersFind, addr szUser, addr uRec
    .IF eax != SV_OK
        invoke SetStatus, 1, offset szErrLoginAuth, 1
        jmp loginCleanupExit
    .ENDIF

    ; Compute Verifier' = SvHash256("AUTH" || Salt || Password)
    invoke lstrlenA, addr szPass
    mov passLen, eax
    invoke SvDeriveKeys, addr uRec.Salt, addr szPass, passLen, addr verifierPrime, addr kekUser

    ; Compare Verifier' with stored Verifier (32 bytes)
    lea esi, verifierPrime
    lea edi, uRec.Verifier
    mov ecx, 32
    repe cmpsb
    .IF !ZERO?
        invoke SetStatus, 1, offset szErrLoginAuth, 1
        jmp loginCleanupExit
    .ENDIF

    ; Pipeline Steps 3..6: Open vault image with OpenVaultImage
    mov nonceOut, 0
    invoke OpenVaultImage, addr szPath, addr outRec, addr kekUser, addr szUser, addr nonceOut, 0
    .IF eax == SV_ERR_IO
        invoke SetStatus, 1, offset szErrLoginFile, 1
        jmp loginCleanupExit
    .ELSEIF eax == SV_ERR_BMP || eax == SV_ERR_MAGIC
        invoke SetStatus, 1, offset szErrLoginNotStego, 1
        jmp loginCleanupExit
    .ELSEIF eax == SV_ERR_NOT_OWNER
        invoke SetStatus, 1, offset szErrLoginNotOwner, 1
        jmp loginCleanupExit
    .ELSEIF eax == SV_ERR_CHECKSUM
        invoke SetStatus, 1, offset szErrLoginDamage, 1
        jmp loginCleanupExit
    .ELSEIF eax != SV_OK
        invoke SetStatus, 1, offset szErrLoginDamage, 1
        jmp loginCleanupExit
    .ENDIF

    ; Pipeline Step 7: Rollback guard (header Nonce >= uRec.LastNonce)
    mov eax, nonceOut
    cmp eax, uRec.LastNonce
    jae nonceGuardPassed
    invoke SetStatus, 1, offset szErrLoginStale, 1
    jmp loginCleanupExit

nonceGuardPassed:
    ; Pipeline Step 8: Open Depositor Dashboard!
    ; 8.1 Initialize Session State
    invoke lstrcpyA, addr sessUser, addr szUser
    lea esi, uRec.Salt
    lea edi, sessSalt
    mov ecx, 16
    rep movsb

    mov eax, nonceOut
    mov sessNonce, eax
    invoke lstrcpyA, addr sessImgPath, addr szPath

    lea esi, outRec
    lea edi, sessRecord
    mov ecx, ACC_REC_SIZE
    rep movsb

    ; Extract and store sessDEK from image
    invoke ReadWholeFile, addr szPath, addr fileSize
    .IF eax != 0
        mov pBmp, eax
        invoke ReadVaultStream, pBmp, addr stream
        invoke SvUnwrapDek, addr stream[4], addr kekUser, addr sessDEK
        invoke SvWipe, addr stream, 256
        invoke GetProcessHeap
        invoke HeapFree, eax, 0, pBmp
    .ENDIF

    ; 8.2 Populate Screen 3 UI Controls
    invoke SetWindowTextA, hDepInfoAcc, addr sessRecord.AccountNumber
    invoke SetWindowTextA, hDepInfoName, addr sessRecord.FullName
    invoke SetWindowTextA, hDepInfoCnic, addr sessRecord.CNIC
    invoke SetWindowTextA, hDepInfoPhone, addr sessRecord.Contact

    ; Format Balance
    invoke ItoaDec, sessRecord.Balance, addr szBalBuf
    lea edi, szBalFull
    mov esi, offset szCurrencyPrefix
    invoke lstrcpyA, edi, esi
    invoke lstrcatA, addr szBalFull, addr szBalBuf
    invoke SetWindowTextA, hDepInfoBal, addr szBalFull
    invoke StartBalAnim

    ; Reset Transaction Panel
    invoke SendMessageA, hDepTxnRadioDep, BM_SETCHECK, BST_CHECKED, 0
    invoke SendMessageA, hDepTxnRadioWdr, BM_SETCHECK, BST_UNCHECKED, 0
    invoke SetWindowTextA, hDepTxnAmt, offset szEmptyStr

    ; Clear password box on Screen 1
    invoke SetWindowTextA, hEditDepPass, offset szEmptyStr

    ; Set status on Screen 3
    invoke SetStatus, 3, offset szStatusDepLoginOk, 0

    ; Transition to Screen 3
    invoke ShowScreen, SCREEN_DEPOSITOR
    invoke UpdateWindow, hMain
    invoke NotifyDepositor, hwndParent

loginCleanupExit:
    invoke SvWipe, addr szPass, 32
    invoke SvWipe, addr verifierPrime, 32
    invoke SvWipe, addr kekUser, 32
    invoke SvWipe, addr outRec, ACC_REC_SIZE
    invoke SvWipe, addr uRec, USER_REC_SIZE
    ret
DoDepositorLogin ENDP

; ------------------------------------------------------------------------------
; DoRefreshBalance: Re-reads vault BMP using active sessDEK and updates balance
; Outputs: EAX = SV_OK or error
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
DoRefreshBalance PROC USES ebx esi edi
    LOCAL pBmp:DWORD
    LOCAL fileSize:DWORD
    LOCAL stream[256]:BYTE
    LOCAL decRecord[148]:BYTE
    LOCAL nonce:DWORD
    LOCAL szBalBuf[32]:BYTE
    LOCAL szBalFull[48]:BYTE

    cld
    cmp sessUser[0], 0
    jz refExit
    cmp sessImgPath[0], 0
    jz refExit

    invoke ReadWholeFile, addr sessImgPath, addr fileSize
    test eax, eax
    jz refReadErr
    mov pBmp, eax

    invoke ReadVaultStream, pBmp, addr stream
    .IF eax != SV_OK
        invoke GetProcessHeap
        invoke HeapFree, eax, 0, pBmp
        invoke SetStatus, 3, offset szErrBalRefresh, 1
        ret
    .ENDIF

    ; Free BMP image buffer
    invoke GetProcessHeap
    invoke HeapFree, eax, 0, pBmp

    ; Check Magic
    cmp DWORD PTR [stream], SVLT_MAGIC
    jne refChkErr

    ; Extract Nonce
    mov eax, DWORD PTR [stream + 68h]
    mov nonce, eax

    ; Copy encrypted record
    lea esi, stream[6Ch]
    lea edi, decRecord
    mov ecx, ACC_REC_SIZE
    rep movsb

    ; Decrypt record in-place with sessDEK
    invoke SvCipher, addr decRecord, ACC_REC_SIZE, addr sessDEK, nonce, 0

    ; Verify Checksum
    invoke SvFnv32, addr decRecord, ACC_REC_SIZE
    mov edx, DWORD PTR [sessDEK]
    xor eax, edx
    cmp eax, DWORD PTR [stream + 44h]
    jne refChkErr

    ; Checksum verified! Update session record and nonce
    lea esi, decRecord
    lea edi, sessRecord
    mov ecx, ACC_REC_SIZE
    rep movsb
    mov eax, nonce
    mov sessNonce, eax

    ; Update Balance Display on Screen 3
    invoke ItoaDec, sessRecord.Balance, addr szBalBuf
    lea edi, szBalFull
    mov esi, offset szCurrencyPrefix
    invoke lstrcpyA, edi, esi
    invoke lstrcatA, addr szBalFull, addr szBalBuf
    invoke SetWindowTextA, hDepInfoBal, addr szBalFull
    invoke StartBalAnim

    invoke SetStatus, 3, offset szStatusBalRefreshed, 0
    invoke SvWipe, addr decRecord, 148
    invoke SvWipe, addr stream, 256
    mov eax, SV_OK
    ret

refChkErr:
    invoke SvWipe, addr decRecord, 148
    invoke SvWipe, addr stream, 256
    invoke SetStatus, 3, offset szErrBalRefresh, 1
    mov eax, SV_ERR_CHECKSUM
    ret

refReadErr:
    invoke SetStatus, 3, offset szErrLoginFile, 1
    mov eax, SV_ERR_IO
    ret

refExit:
    mov eax, SV_OK
    ret
DoRefreshBalance ENDP

; ------------------------------------------------------------------------------
; DoLogout: Wipes session keys and records, clears form fields, and returns to login
; Outputs: EAX = SV_OK
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
DoLogout PROC USES ebx esi edi
    cld
    ; 1. Wipe sensitive session state
    invoke SvWipe, addr sessUser, 32
    invoke SvWipe, addr sessSalt, 16
    invoke SvWipe, addr sessDEK, 32
    invoke SvWipe, addr sessRecord, sizeof ACCOUNT_RECORD
    mov sessNonce, 0
    invoke SvWipe, addr sessImgPath, MAX_PATH

    ; 2. Clear Screen 3 labels
    invoke SetWindowTextA, hDepInfoAcc, offset szEmptyStr
    invoke SetWindowTextA, hDepInfoName, offset szEmptyStr
    invoke SetWindowTextA, hDepInfoCnic, offset szEmptyStr
    invoke SetWindowTextA, hDepInfoPhone, offset szEmptyStr
    invoke SetWindowTextA, hDepInfoBal, offset szEmptyStr
    invoke SetWindowTextA, hDepTxnAmt, offset szEmptyStr

    ; 3. Clear Screen 1 password field
    invoke SetWindowTextA, hEditDepPass, offset szEmptyStr

    ; 4. Update status on Screen 1
    invoke SetStatus, 1, offset szStatusLoggedOut, 0

    ; 5. Switch to Screen 1 (Login)
    invoke ShowScreen, SCREEN_LOGIN
    mov eax, SV_OK
    ret
DoLogout ENDP

; ------------------------------------------------------------------------------
; DoSubmitRequest: Submits a deposit or withdrawal request for logged-in depositor
; Inputs:  hwndParent (DWORD)
; Outputs: EAX = SV_OK or error
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
DoSubmitRequest PROC USES ebx esi edi hwndParent:DWORD
    LOCAL szAmtText[32]:BYTE
    LOCAL dwAmount:DWORD
    LOCAL reqType:DWORD
    LOCAL req:REQUEST_RECORD
    LOCAL reqId:DWORD
    LOCAL szDigits[16]:BYTE
    LOCAL szMsgBuf[64]:BYTE

    mov eax, hwndParent
    cld
    cmp sessUser[0], 0
    jz submitReqExit

    ; 1. Check transaction radio selection
    invoke SendMessageA, hDepTxnRadioDep, BM_GETCHECK, 0, 0
    .IF eax == BST_CHECKED
        mov reqType, REQ_TYPE_DEPOSIT
    .ELSE
        invoke SendMessageA, hDepTxnRadioWdr, BM_GETCHECK, 0, 0
        .IF eax == BST_CHECKED
            mov reqType, REQ_TYPE_WITHDRAW
        .ELSE
            invoke SetStatus, 3, offset szErrReqType, 1
            mov eax, SV_ERR_INPUT
            ret
        .ENDIF
    .ENDIF

    ; 2. Read amount edit box
    invoke GetWindowTextA, hDepTxnAmt, addr szAmtText, sizeof szAmtText
    .IF eax == 0
        invoke SetStatus, 3, offset szErrReqEmptyAmt, 1
        mov eax, SV_ERR_INPUT
        ret
    .ENDIF

    ; Convert decimal string to DWORD
    invoke AtoiDec, addr szAmtText
    .IF edx != 0
        invoke SetStatus, 3, offset szErrReqInvalidAmt, 1
        mov eax, SV_ERR_INPUT
        ret
    .ENDIF
    mov dwAmount, eax

    ; Validate amount (1..100,000,000)
    invoke ValidateAmount, dwAmount
    .IF eax == 0
        invoke SetStatus, 3, offset szErrReqInvalidAmt, 1
        mov eax, SV_ERR_INPUT
        ret
    .ENDIF

    ; 3. Check business rules
    .IF reqType == REQ_TYPE_WITHDRAW
        ; Withdrawal cannot exceed current balance
        mov eax, dwAmount
        cmp eax, sessRecord.Balance
        jbe withdrawBalOk
        ; Overdraw! Show message box and status
            invoke SetStatus, 3, offset szErrOverdrawMsg, 1
        mov eax, SV_ERR_FUNDS
        ret
    withdrawBalOk:
    .ELSEIF reqType == REQ_TYPE_DEPOSIT
        ; Deposit cannot cause DWORD overflow
        mov eax, sessRecord.Balance
        add eax, dwAmount
        jnc depositOk
            invoke SetStatus, 3, offset szErrDepositOverflow, 1
        mov eax, SV_ERR_INPUT
        ret
    depositOk:
    .ENDIF

    ; 4. Prepare REQUEST_RECORD (64 bytes)
    invoke SvWipe, addr req, sizeof REQUEST_RECORD

    ; Copy lowercase username
    lea esi, sessUser
    lea edi, req.Username
lowerUserLoop:
    mov al, [esi]
    cmp al, 'A'
    jb storeChar
    cmp al, 'Z'
    ja storeChar
    add al, 32
storeChar:
    mov [edi], al
    inc esi
    inc edi
    test al, al
    jnz lowerUserLoop

    ; Account Number
    invoke lstrcpyA, addr req.AccountNumber, addr sessRecord.AccountNumber

    ; RequestType
    mov eax, reqType
    mov req.RequestType, eax

    ; Amount
    mov eax, dwAmount
    mov req.Amount, eax

    ; Status = 0 (Pending)
    mov req.Status, REQ_STATUS_PENDING

    ; Reserved = 0
    mov req.Reserved, 0

    ; 5. Append to requests.dat
    invoke ReqAppend, addr req
    .IF eax != SV_OK
        invoke SetStatus, 3, offset szErrReqAppendFail, 1
        ret
    .ENDIF

    ; 6. Calculate new request ID = ReqCount()
    invoke ReqCount
    mov reqId, eax

    ; Format: "Request #<reqId> submitted."
    mov ecx, reqId
    invoke ItoaDec, ecx, addr szDigits
    lea edi, szMsgBuf
    mov esi, offset szReqSubmittedPrefix
    invoke lstrcpyA, edi, esi
    invoke lstrcatA, addr szMsgBuf, addr szDigits
    invoke lstrcatA, addr szMsgBuf, offset szReqSubmittedSuffix

    ; Display on Screen 3 status line
    invoke SetStatus, 3, addr szMsgBuf, 0

    ; Clear amount edit box
    invoke SetWindowTextA, hDepTxnAmt, offset szEmptyStr

    mov eax, SV_OK
    ret

submitReqExit:
    mov eax, SV_ERR_AUTH
    ret
DoSubmitRequest ENDP

; ------------------------------------------------------------------------------
; DoCashierCreate: First-time cashier account setup from the Cashier login tab
; Inputs:  hwndParent (DWORD)
; Outputs: EAX = SV_OK or error
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
DoCashierCreate PROC USES ebx esi edi hwndParent:DWORD
    LOCAL szUser[32]:BYTE
    LOCAL szPass[32]:BYTE

    cld
    mov eax, hwndParent
    invoke GetWindowTextA, hEditCshUser, addr szUser, sizeof szUser
    invoke GetWindowTextA, hEditCshPass, addr szPass, sizeof szPass

    invoke CashierExists
    test eax, eax
    jz ccNotYet
    invoke SetStatus, 1, offset szErrCashierExists, 1
    mov eax, SV_ERR_EXISTS
    jmp ccExit
ccNotYet:
    ; Username: 3..31 of [A-Za-z0-9_]  ("admin" itself is allowed for the cashier)
    invoke lstrcmpiA, addr szUser, offset szReservedAdmin
    test eax, eax
    jz ccUserOk
    invoke ValidateUsername, addr szUser
    test eax, eax
    jnz ccUserOk
    invoke SetStatus, 1, offset szErrRegUser, 1
    mov eax, SV_ERR_INPUT
    jmp ccExit
ccUserOk:
    invoke ValidatePassword, addr szPass
    test eax, eax
    jnz ccPassOk
    invoke SetStatus, 1, offset szErrRegPass, 1
    mov eax, SV_ERR_INPUT
    jmp ccExit
ccPassOk:
    invoke CashierCreate, addr szUser, addr szPass
    test eax, eax
    jz ccSaved
    invoke SetStatus, 1, offset szErrCashierWrite, 1
    mov eax, SV_ERR_IO
    jmp ccExit
ccSaved:
    invoke SetWindowTextA, hEditCshPass, offset szEmptyStr
    invoke SetStatus, 1, offset szMsgCashierCreated, 0
    mov eax, SV_OK
ccExit:
    push eax
    invoke SvWipe, addr szPass, 32
    pop eax
    ret
DoCashierCreate ENDP

; ------------------------------------------------------------------------------
; DoCashierLogin: Authenticates cashier, populates Screen 4, and alerts pending
; Inputs:  hwndParent (DWORD)
; Outputs: EAX = SV_OK or error
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
DoCashierLogin PROC USES ebx esi edi hwndParent:DWORD
    LOCAL szUser[32]:BYTE
    LOCAL szPass[32]:BYTE
    LOCAL numPending:DWORD
    LOCAL szAlertMsg[64]:BYTE
    LOCAL szDigits[16]:BYTE

    cld
    invoke GetWindowTextA, hEditCshUser, addr szUser, sizeof szUser
    invoke GetWindowTextA, hEditCshPass, addr szPass, sizeof szPass

    ; Only a cashier account created through the app (cashier.dat) can log in;
    ; there is no built-in default account.
    invoke CashierExists
    test eax, eax
    jnz cashierAccountExists
    invoke SetWindowTextA, hEditCshPass, offset szEmptyStr
    invoke SvWipe, addr szPass, 32
    invoke SetStatus, 1, offset szErrNoCashierYet, 1
    mov eax, SV_ERR_AUTH
    ret
cashierAccountExists:
    invoke CashierVerify, addr szUser, addr szPass
    test eax, eax
    jnz loginCashierFailed

    ; Clear password field and wipe
    invoke SetWindowTextA, hEditCshPass, offset szEmptyStr
    invoke SvWipe, addr szPass, 32

    mov curRole, ROLE_CASHIER

    ; Populate Screen 4 controls
    invoke PopulateCashierRequests, hwndParent
    invoke PopulateCashierDepositors

    ; Depositor data stays locked until a vault image is inserted
    invoke SetCashierLocked
    invoke SetCashierPreview, 0
    invoke SetWindowTextA, hCshManualAmt, offset szEmptyStr
    invoke SendMessageA, hCshRadioDep, BM_SETCHECK, BST_CHECKED, 0
    invoke SendMessageA, hCshRadioWdr, BM_SETCHECK, BST_UNCHECKED, 0

    ; Switch to Screen 4
    invoke ShowScreen, SCREEN_CASHIER

    ; Check pending requests
    invoke ReqCountPending
    mov numPending, eax
    .IF eax > 0
        ; Format alert: "N pending request(s) waiting."
        mov ecx, numPending
        invoke ItoaDec, ecx, addr szDigits
        lea edi, szAlertMsg
        invoke lstrcpyA, edi, addr szDigits
        invoke lstrcatA, addr szAlertMsg, offset szPendingAlertSuffix
        invoke SetWindowTextA, hCshAlertLbl, addr szAlertMsg
        .IF hwndParent != 0
            invoke ThemedMsgBox, hwndParent, addr szAlertMsg, offset szBankTitle, MB_ICONINFORMATION or MB_OK
        .ENDIF
        invoke SetStatus, 4, addr szAlertMsg, 0
    .ELSE
        invoke SetWindowTextA, hCshAlertLbl, offset szNoPendingAlert
        invoke SetStatus, 4, offset szStatusCashierReady, 0
    .ENDIF

    mov eax, SV_OK
    ret

loginCashierFailed:
    invoke SetWindowTextA, hEditCshPass, offset szEmptyStr
    invoke SvWipe, addr szPass, 32
    invoke SetStatus, 1, offset szErrCashierCreds, 1
    mov eax, SV_ERR_AUTH
    ret
DoCashierLogin ENDP

; ------------------------------------------------------------------------------
; DoCashierLogout: Wipes cashier buffers, clears fields, and returns to login
; Outputs: EAX = SV_OK
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
DoCashierLogout PROC USES ebx esi edi
    cld
    ; Wipe cashier session state
    invoke SvWipe, addr cshActiveRec, sizeof ACCOUNT_RECORD
    mov cshActiveNonce, 0
    invoke SvWipe, addr cshActivePath, MAX_PATH
    invoke SvWipe, addr cshActiveUser, 32

    ; Clear Screen 4 controls
    invoke SetCashierLocked
    invoke SetCashierPreview, 0
    invoke SetWindowTextA, hCshManualAmt, offset szEmptyStr
    invoke SendMessageA, hCshReqList, LB_RESETCONTENT, 0, 0
    invoke SendMessageA, hCshDepList, LB_RESETCONTENT, 0, 0

    ; Reset role and return to Screen 1
    mov curRole, ROLE_DEPOSITOR
    invoke SetStatus, 1, offset szStatusLoggedOut, 0
    invoke ShowScreen, SCREEN_LOGIN
    mov eax, SV_OK
    ret
DoCashierLogout ENDP

; ------------------------------------------------------------------------------
; PopulateCashierRequests: Reads all requests from requests.dat and fills list box
; Inputs:  hwndParent (DWORD)
; Outputs: None
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
PopulateCashierRequests PROC USES ebx esi edi hwndParent:DWORD
    LOCAL count:DWORD
    LOCAL pBuf:DWORD
    LOCAL cbAlloc:DWORD
    LOCAL i:DWORD
    LOCAL pReq:DWORD
    LOCAL lineBuf[128]:BYTE
    LOCAL digitsBuf[16]:BYTE
    LOCAL amtBuf[16]:BYTE
    LOCAL reqId:DWORD
    LOCAL firstPendingIdx:DWORD

    cld
    mov eax, hwndParent
    invoke SendMessageA, hCshReqList, LB_RESETCONTENT, 0, 0
    mov firstPendingIdx, -1

    invoke ReqCount
    .IF eax <= 0
        ret
    .ENDIF
    mov count, eax

    mov ecx, REQ_REC_SIZE
    mul ecx
    mov cbAlloc, eax

    invoke GetProcessHeap
    invoke HeapAlloc, eax, HEAP_ZERO_MEMORY, cbAlloc
    .IF eax == 0
        ret
    .ENDIF
    mov pBuf, eax

    invoke ReqReadAll, pBuf, addr count
    .IF eax != SV_OK
        invoke GetProcessHeap
        invoke HeapFree, eax, 0, pBuf
        ret
    .ENDIF

    xor ebx, ebx
reqLoop:
    cmp ebx, count
    jae doneReqLoop
    mov i, ebx

    ; pReq = pBuf + i * 64
    mov eax, i
    mov ecx, REQ_REC_SIZE
    mul ecx
    add eax, pBuf
    mov pReq, eax

    ; reqId = i + 1
    mov eax, i
    inc eax
    mov reqId, eax

    ; Build line in lineBuf: "#"
    mov lineBuf[0], '#'
    mov lineBuf[1], 0

    ; "<id>"
    mov ecx, reqId
    invoke ItoaDec, ecx, addr digitsBuf
    invoke lstrcatA, addr lineBuf, addr digitsBuf

    ; "  "
    invoke lstrcatA, addr lineBuf, offset szTwoSpaces

    ; "<username>"
    mov edx, pReq
    invoke lstrcatA, addr lineBuf, edx

    ; "  "
    invoke lstrcatA, addr lineBuf, offset szTwoSpaces

    ; "<Deposit|Withdraw>"
    mov edx, pReq
    mov eax, (REQUEST_RECORD PTR [edx]).RequestType
    .IF eax == REQ_TYPE_DEPOSIT
        invoke lstrcatA, addr lineBuf, offset szTypeDeposit
    .ELSE
        invoke lstrcatA, addr lineBuf, offset szTypeWithdraw
    .ENDIF

    ; "  "
    invoke lstrcatA, addr lineBuf, offset szTwoSpaces

    ; "<amount>"
    mov edx, pReq
    mov ecx, (REQUEST_RECORD PTR [edx]).Amount
    invoke ItoaDec, ecx, addr amtBuf
    invoke lstrcatA, addr lineBuf, addr amtBuf

    ; "  "
    invoke lstrcatA, addr lineBuf, offset szTwoSpaces

    ; "<Pending|Approved|Rejected>"
    mov edx, pReq
    mov eax, (REQUEST_RECORD PTR [edx]).Status
    .IF eax == REQ_STATUS_PENDING
        invoke lstrcatA, addr lineBuf, offset szStatusPendingStr
        .IF firstPendingIdx == -1
            mov eax, i
            mov firstPendingIdx, eax
        .ENDIF
    .ELSEIF eax == REQ_STATUS_APPROVED
        invoke lstrcatA, addr lineBuf, offset szStatusApprovedStr
    .ELSE
        invoke lstrcatA, addr lineBuf, offset szStatusRejectedStr
    .ENDIF

    ; Add to list box
    invoke SendMessageA, hCshReqList, LB_ADDSTRING, 0, addr lineBuf
    invoke SendMessageA, hCshReqList, LB_SETITEMDATA, eax, i

    mov ebx, i
    inc ebx
    jmp reqLoop

doneReqLoop:
    invoke GetProcessHeap
    invoke HeapFree, eax, 0, pBuf

    .IF firstPendingIdx != -1
        invoke SendMessageA, hCshReqList, LB_SETCURSEL, firstPendingIdx, 0
    .ENDIF
    ret
PopulateCashierRequests ENDP

; ------------------------------------------------------------------------------
; PopulateCashierDepositors: Fills depositors list box from Vault_Images\*.bmp
; Outputs: None
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
PopulateCashierDepositors PROC USES ebx esi edi
    LOCAL wfd:WIN32_FIND_DATAA
    LOCAL hFind:DWORD

    cld
    invoke SendMessageA, hCshDepList, LB_RESETCONTENT, 0, 0

    invoke FindFirstFileA, offset szVaultBmpPattern, addr wfd
    .IF eax == INVALID_HANDLE_VALUE
        ret
    .ENDIF
    mov hFind, eax

findDepLoop:
    invoke SendMessageA, hCshDepList, LB_ADDSTRING, 0, addr wfd.cFileName
    invoke FindNextFileA, hFind, addr wfd
    test eax, eax
    jnz findDepLoop

    invoke FindClose, hFind
    ret
PopulateCashierDepositors ENDP

; ------------------------------------------------------------------------------
; DrawPreviewItem: Paints the owner-drawn vault image preview (aspect-fit, halftone)
; Inputs:  pDrawItem (DWORD ptr to DRAWITEMSTRUCT)
; Outputs: EAX = 1
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
DrawPreviewItem PROC USES ebx esi edi pDrawItem:DWORD
    LOCAL bmpInfo[24]:BYTE
    LOCAL hMemDC:DWORD
    LOCAL hOldBmp:DWORD
    LOCAL srcW:DWORD
    LOCAL srcH:DWORD
    LOCAL availW:DWORD
    LOCAL availH:DWORD
    LOCAL dstW:DWORD
    LOCAL dstH:DWORD
    LOCAL dstX:DWORD
    LOCAL dstY:DWORD
    LOCAL rcText:RECT

    mov esi, pDrawItem
    assume esi:PTR DRAWITEMSTRUCT
    invoke FillRect, [esi].hDC, addr [esi].rcItem, hbrInput
    invoke FrameRect, [esi].hDC, addr [esi].rcItem, hbrBorder

    cmp hPreviewBmp, 0
    jne previewHasBmp

    mov eax, [esi].rcItem.left
    mov rcText.left, eax
    mov eax, [esi].rcItem.top
    mov rcText.top, eax
    mov eax, [esi].rcItem.right
    mov rcText.right, eax
    mov eax, [esi].rcItem.bottom
    mov rcText.bottom, eax
    invoke SetBkMode, [esi].hDC, TRANSPARENT
    invoke SetTextColor, [esi].hDC, COLOR_SLATE
    invoke SelectObject, [esi].hDC, hFontBody
    invoke DrawTextA, [esi].hDC, offset szNoPreviewText, -1, addr rcText,
           DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX
    jmp previewDone

previewHasBmp:
    invoke GetObjectA, hPreviewBmp, 24, addr bmpInfo
    mov eax, DWORD PTR [bmpInfo + BITMAP_WIDTH_OFF]
    mov srcW, eax
    mov eax, DWORD PTR [bmpInfo + BITMAP_HEIGHT_OFF]
    mov srcH, eax
    cmp srcW, 0
    je previewDone
    cmp srcH, 0
    je previewDone

    mov eax, [esi].rcItem.right
    sub eax, [esi].rcItem.left
    sub eax, 4
    mov availW, eax
    mov eax, [esi].rcItem.bottom
    sub eax, [esi].rcItem.top
    sub eax, 4
    mov availH, eax

    ; Fit: if srcW*availH >= srcH*availW the width is the limiting side
    mov eax, srcW
    mul availH
    mov ebx, eax
    mov eax, srcH
    mul availW
    cmp ebx, eax
    jb fitByHeight
    mov eax, availW
    mov dstW, eax
    mov eax, srcH
    mul availW
    xor edx, edx
    div srcW
    mov dstH, eax
    jmp fitDone
fitByHeight:
    mov eax, availH
    mov dstH, eax
    mov eax, srcW
    mul availH
    xor edx, edx
    div srcH
    mov dstW, eax
fitDone:
    cmp dstW, 1
    jge wOk
    mov dstW, 1
wOk:
    cmp dstH, 1
    jge hOk
    mov dstH, 1
hOk:
    mov eax, availW
    sub eax, dstW
    shr eax, 1
    add eax, [esi].rcItem.left
    add eax, 2
    mov dstX, eax
    mov eax, availH
    sub eax, dstH
    shr eax, 1
    add eax, [esi].rcItem.top
    add eax, 2
    mov dstY, eax

    invoke CreateCompatibleDC, [esi].hDC
    test eax, eax
    jz previewDone
    mov hMemDC, eax
    invoke SelectObject, hMemDC, hPreviewBmp
    mov hOldBmp, eax
    invoke SetStretchBltMode, [esi].hDC, HALFTONE
    invoke SetBrushOrgEx, [esi].hDC, 0, 0, 0
    invoke StretchBlt, [esi].hDC, dstX, dstY, dstW, dstH, hMemDC, 0, 0, srcW, srcH, SRCCOPY
    invoke SelectObject, hMemDC, hOldBmp
    invoke DeleteDC, hMemDC

previewDone:
    assume esi:NOTHING
    mov eax, 1
    ret
DrawPreviewItem ENDP

; ------------------------------------------------------------------------------
; SetCashierPreview: Loads a BMP file as the preview image (0 = clear preview)
; Inputs:  pPath (DWORD ptr or 0)
; Outputs: EAX = SV_OK
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
SetCashierPreview PROC USES ebx esi edi pPath:DWORD
    cmp hPreviewBmp, 0
    je previewNoOld
    invoke DeleteObject, hPreviewBmp
    mov hPreviewBmp, 0
previewNoOld:
    cmp pPath, 0
    je previewRefresh
    invoke LoadImageA, 0, pPath, IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE
    mov hPreviewBmp, eax
previewRefresh:
    invoke InvalidateRect, hCshPreview, 0, 1
    mov eax, SV_OK
    ret
SetCashierPreview ENDP

; ------------------------------------------------------------------------------
; SetCashierLocked: Wipes the decrypted depositor session and shows "(locked)"
; Outputs: EAX = SV_OK
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
SetCashierLocked PROC USES ebx esi edi
    invoke SvWipe, addr cshActiveRec, sizeof ACCOUNT_RECORD
    mov cshActiveNonce, 0
    invoke SvWipe, addr cshActivePath, MAX_PATH
    invoke SvWipe, addr cshActiveUser, 32
    invoke SetWindowTextA, hCshDetailAcc, offset szLockedValue
    invoke SetWindowTextA, hCshDetailName, offset szLockedValue
    invoke SetWindowTextA, hCshDetailUser, offset szLockedValue
    invoke SetWindowTextA, hCshDetailCnic, offset szLockedValue
    invoke SetWindowTextA, hCshDetailPhone, offset szLockedValue
    invoke SetWindowTextA, hCshDetailBal, offset szLockedValue
    invoke SetCashierMode, CSH_MODE_NONE
    mov eax, SV_OK
    ret
SetCashierLocked ENDP

; ------------------------------------------------------------------------------
; ShowDecryptPopup: Small centred popup "Decrypting the data..."
; Inputs:  hwndParent (DWORD)
; Outputs: EAX = popup window handle (0 on failure)
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
ShowDecryptPopup PROC USES ebx esi edi hwndParent:DWORD
    LOCAL rcParent:RECT

    invoke GetWindowRect, hwndParent, addr rcParent
    mov esi, rcParent.right
    sub esi, rcParent.left
    sub esi, 300
    sar esi, 1
    add esi, rcParent.left
    mov edi, rcParent.bottom
    sub edi, rcParent.top
    sub edi, 70
    sar edi, 1
    add edi, rcParent.top
    invoke CreateWindowExA, WS_EX_TOPMOST or WS_EX_TOOLWINDOW, offset szStaticClass, offset szDecryptingText,
           WS_POPUP or WS_VISIBLE or WS_BORDER or SS_CENTER or SS_CENTERIMAGE or SS_NOPREFIX,
           esi, edi, 300, 70, hwndParent, 0, hInst, 0
    mov ebx, eax
    test ebx, ebx
    jz popupFail
    invoke SendMessageA, ebx, WM_SETFONT, hFontBold, 1
    invoke ShowWindow, ebx, SW_SHOW
    invoke UpdateWindow, ebx
    mov eax, ebx
    ret
popupFail:
    xor eax, eax
    ret
ShowDecryptPopup ENDP

; ------------------------------------------------------------------------------
; CloseDecryptPopup: Keeps the popup visible for DECRYPT_POPUP_MS, then destroys it
; Inputs:  hPopup (DWORD, may be 0)
; Outputs: EAX = SV_OK
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
CloseDecryptPopup PROC USES ebx esi edi hPopup:DWORD
    invoke Sleep, DECRYPT_POPUP_MS
    cmp hPopup, 0
    je popupClosed
    invoke DestroyWindow, hPopup
popupClosed:
    mov eax, SV_OK
    ret
CloseDecryptPopup ENDP

; ------------------------------------------------------------------------------
; SelectVaultForPreview: Shows the encrypted image of a depositor WITHOUT decrypting.
;   If that depositor's vault is already unlocked it stays unlocked; otherwise the
;   data panel is locked and the cashier is told to insert the image.
; Inputs:  hwndParent (DWORD), pUsername (DWORD ptr, e.g. "alice")
; Outputs: EAX = SV_OK
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
SelectVaultForPreview PROC USES ebx esi edi hwndParent:DWORD, pUsername:DWORD
    LOCAL szPreviewPath[MAX_PATH]:BYTE
    LOCAL szMsg[200]:BYTE

    mov eax, hwndParent
    invoke lstrcpyA, addr szPreviewPath, offset szVaultImagesDir
    invoke lstrcatA, addr szPreviewPath, pUsername
    invoke lstrcatA, addr szPreviewPath, offset szBmpExt
    invoke SetCashierPreview, addr szPreviewPath

    cmp BYTE PTR cshActiveUser, 0
    je previewLockIt
    invoke lstrcmpiA, pUsername, addr cshActiveUser
    test eax, eax
    jz previewKeepOpen
previewLockIt:
    invoke SetCashierLocked
    invoke lstrcpyA, addr szMsg, offset szHintPart1
    invoke lstrcatA, addr szMsg, pUsername
    invoke lstrcatA, addr szMsg, offset szHintPart2
    invoke SetStatus, 4, addr szMsg, 0
    mov eax, SV_OK
    ret
previewKeepOpen:
    ; Same depositor is already unlocked: offer the two actions again
    invoke ShowCashierChooser, hwndParent
    mov eax, SV_OK
    ret
SelectVaultForPreview ENDP

; ------------------------------------------------------------------------------
; DoLoadDepositorImage: Opens and decrypts depositor vault BMP using Master Key
; Inputs:  hwndParent (DWORD), pPath (DWORD ptr)
; Outputs: EAX = SV_OK or error
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
DoLoadDepositorImage PROC USES ebx esi edi hwndParent:DWORD, pPath:DWORD
    LOCAL szBalDigits[16]:BYTE
    LOCAL szBalFull[48]:BYTE
    LOCAL hPopup:DWORD
    LOCAL openResult:DWORD
    LOCAL szOpenMsg[200]:BYTE
    LOCAL checkUserRec:USER_RECORD

    cld
    mov esi, pPath
    test esi, esi
    jz loadImgFail

    ; Any previous session is locked first; data appears only after a good decrypt
    invoke SetCashierLocked
    invoke SetCashierPreview, pPath

    invoke ShowDecryptPopup, hwndParent
    mov hPopup, eax

    ; OpenVaultImage with isCashier = 1 (Master Key path)
    invoke OpenVaultImage, pPath, addr cshActiveRec, 0, 0, addr cshActiveNonce, 1
    mov openResult, eax

    invoke CloseDecryptPopup, hPopup

    .IF openResult != SV_OK
        invoke SetCashierLocked
        mov eax, openResult
        mov edx, offset szErrCashierOpenImage
        .IF eax == SV_ERR_IO
            mov edx, offset szErrOpenIo
        .ELSEIF eax == SV_ERR_BMP || eax == SV_ERR_CAPACITY
            mov edx, offset szErrOpenBmp
        .ELSEIF eax == SV_ERR_MAGIC
            mov edx, offset szErrOpenMagic
        .ELSEIF eax == SV_ERR_CHECKSUM
            mov edx, offset szErrOpenCheck
        .ENDIF
        invoke lstrcpyA, addr szOpenMsg, edx
        invoke lstrcatA, addr szOpenMsg, offset szErrOpenCode
        invoke ItoaDec, openResult, addr szBalDigits
        invoke lstrcatA, addr szOpenMsg, addr szBalDigits
        invoke lstrcatA, addr szOpenMsg, offset szCloseParen
        invoke SetStatus, 4, addr szOpenMsg, 1
        mov eax, openResult
        ret
    .ENDIF

    ; Rollback guard: an older copy of the image must not be accepted
    invoke UsersFind, addr cshActiveRec.Username, addr checkUserRec
    .IF eax == SV_OK
        mov eax, cshActiveNonce
        .IF eax < checkUserRec.LastNonce
            invoke SetCashierLocked
            invoke SetStatus, 4, offset szErrCashierStale, 1
            mov eax, SV_ERR_STALE
            ret
        .ENDIF
    .ENDIF

    ; Store path and username
    invoke lstrcpyA, addr cshActivePath, pPath
    invoke lstrcpyA, addr cshActiveUser, addr cshActiveRec.Username

    ; Display fields on Screen 4
    invoke SetWindowTextA, hCshDetailAcc, addr cshActiveRec.AccountNumber
    invoke SetWindowTextA, hCshDetailName, addr cshActiveRec.FullName
    invoke SetWindowTextA, hCshDetailUser, addr cshActiveRec.Username
    invoke SetWindowTextA, hCshDetailCnic, addr cshActiveRec.CNIC
    invoke SetWindowTextA, hCshDetailPhone, addr cshActiveRec.Contact

    mov ecx, cshActiveRec.Balance
    invoke ItoaDec, ecx, addr szBalDigits
    lea edi, szBalFull
    invoke lstrcpyA, edi, offset szCurrencyPrefix
    invoke lstrcatA, addr szBalFull, addr szBalDigits
    invoke SetWindowTextA, hCshDetailBal, addr szBalFull

    invoke SetStatus, 4, offset szStatusVaultLoaded, 0
    invoke ShowCashierChooser, hwndParent
    mov eax, SV_OK
    ret

loadImgFail:
    mov eax, SV_ERR_IO
    ret
DoLoadDepositorImage ENDP

; ------------------------------------------------------------------------------
; BrowseCashierImage: Prompts file dialog to open depositor vault BMP
; Inputs:  hwndParent (DWORD)
; Outputs: None
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
BrowseCashierImage PROC USES ebx esi edi hwndParent:DWORD
    LOCAL ofn:OPENFILENAMEA
    LOCAL szFile[MAX_PATH]:BYTE

    cld
    invoke SvWipe, addr ofn, sizeof OPENFILENAMEA
    invoke SvWipe, addr szFile, MAX_PATH

    mov ofn.lStructSize, sizeof OPENFILENAMEA
    mov eax, hwndParent
    mov ofn.hwndOwner, eax
    mov ofn.lpstrFilter, offset szBmpFilter
    lea eax, szFile
    mov ofn.lpstrFile, eax
    mov ofn.nMaxFile, MAX_PATH
    mov ofn.lpstrInitialDir, offset szVaultImagesDir
    mov ofn.lpstrTitle, offset szBrowseCashierTitle
    mov ofn.Flags, OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or OFN_NOCHANGEDIR

    invoke GetOpenFileNameA, addr ofn
    test eax, eax
    jz browseCashierCancel

    invoke DoLoadDepositorImage, hwndParent, addr szFile
browseCashierCancel:
    ret
BrowseCashierImage ENDP

; ------------------------------------------------------------------------------
; OnCashierDepListSelChange: Handles depositor list box selection change
; Inputs:  hwndParent (DWORD)
; Outputs: None
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
OnCashierDepListSelChange PROC USES ebx esi edi hwndParent:DWORD
    LOCAL curSel:DWORD
    LOCAL szFilename[MAX_PATH]:BYTE

    cld
    invoke SendMessageA, hCshDepList, LB_GETCURSEL, 0, 0
    .IF eax == LB_ERR
        ret
    .ENDIF
    mov curSel, eax

    invoke SendMessageA, hCshDepList, LB_GETTEXT, curSel, addr szFilename
    .IF eax == LB_ERR
        ret
    .ENDIF

    ; "alice.bmp" -> "alice": strip the 4-char extension
    invoke lstrlenA, addr szFilename
    .IF eax > 4
        sub eax, 4
        mov BYTE PTR [szFilename + eax], 0
    .ENDIF

    invoke SelectVaultForPreview, hwndParent, addr szFilename
    ret
OnCashierDepListSelChange ENDP

; ------------------------------------------------------------------------------
; OnCashierReqListSelChange: Handles requests list box selection change
; Inputs:  hwndParent (DWORD)
; Outputs: None
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
OnCashierReqListSelChange PROC USES ebx esi edi hwndParent:DWORD
    LOCAL curSel:DWORD
    LOCAL reqIdx:DWORD
    LOCAL hFile:DWORD
    LOCAL bytesRead:DWORD
    LOCAL req:REQUEST_RECORD

    cld
    invoke SendMessageA, hCshReqList, LB_GETCURSEL, 0, 0
    .IF eax == LB_ERR
        ret
    .ENDIF
    mov curSel, eax

    invoke SendMessageA, hCshReqList, LB_GETITEMDATA, curSel, 0
    .IF eax == LB_ERR
        ret
    .ENDIF
    mov reqIdx, eax

    ; Read record from requests.dat
    invoke CreateFileA, offset szRequestsFile, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
    .IF eax == INVALID_HANDLE_VALUE
        ret
    .ENDIF
    mov hFile, eax

    ; Seek to reqIdx * 64
    mov eax, reqIdx
    mov ecx, REQ_REC_SIZE
    mul ecx
    invoke SetFilePointer, hFile, eax, 0, FILE_BEGIN
    invoke ReadFile, hFile, addr req, REQ_REC_SIZE, addr bytesRead, 0
    invoke CloseHandle, hFile

    .IF bytesRead != REQ_REC_SIZE
        ret
    .ENDIF

    ; Show (do not decrypt) the encrypted image of the requesting depositor
    invoke SelectVaultForPreview, hwndParent, addr req.Username
    ret
OnCashierReqListSelChange ENDP

; ------------------------------------------------------------------------------
; DoCashierApprove: Processes and applies selected pending transaction request
; Inputs:  hwndParent (DWORD)
; Outputs: EAX = SV_OK or error
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
DoCashierApprove PROC USES ebx esi edi hwndParent:DWORD
    LOCAL curSel:DWORD
    LOCAL reqIdx:DWORD
    LOCAL hFile:DWORD
    LOCAL bytesRead:DWORD
    LOCAL req:REQUEST_RECORD
    LOCAL szPath[MAX_PATH]:BYTE
    LOCAL pBmp:DWORD
    LOCAL fileSize:DWORD
    LOCAL stream[256]:BYTE
    LOCAL kekCashier[32]:BYTE
    LOCAL dek[32]:BYTE
    LOCAL curNonce:DWORD
    LOCAL rec:ACCOUNT_RECORD
    LOCAL szBalDigits[16]:BYTE
    LOCAL szBalFull[48]:BYTE
    LOCAL szNeedMsg[200]:BYTE

    cld
    ; 1. Get selected request index
    invoke SendMessageA, hCshReqList, LB_GETCURSEL, 0, 0
    .IF eax == LB_ERR
        invoke SetStatus, 4, offset szErrNoReqSelected, 1
        mov eax, SV_ERR_INPUT
        ret
    .ENDIF
    mov curSel, eax

    invoke SendMessageA, hCshReqList, LB_GETITEMDATA, curSel, 0
    .IF eax == LB_ERR
        invoke SetStatus, 4, offset szErrNoReqSelected, 1
        mov eax, SV_ERR_INPUT
        ret
    .ENDIF
    mov reqIdx, eax

    ; 2. Read request record from requests.dat
    invoke CreateFileA, offset szRequestsFile, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
    .IF eax == INVALID_HANDLE_VALUE
        invoke SetStatus, 4, offset szErrReqAlreadyDone, 1
        mov eax, SV_ERR_IO
        ret
    .ENDIF
    mov hFile, eax

    mov eax, reqIdx
    mov ecx, REQ_REC_SIZE
    mul ecx
    invoke SetFilePointer, hFile, eax, 0, FILE_BEGIN
    invoke ReadFile, hFile, addr req, REQ_REC_SIZE, addr bytesRead, 0
    invoke CloseHandle, hFile

    .IF bytesRead != REQ_REC_SIZE
        invoke SetStatus, 4, offset szErrReqAlreadyDone, 1
        mov eax, SV_ERR_IO
        ret
    .ENDIF

    ; Check if request is still Pending
    .IF req.Status != REQ_STATUS_PENDING
        invoke SetStatus, 4, offset szErrReqAlreadyDone, 1
        mov eax, SV_ERR_INPUT
        ret
    .ENDIF

    ; 3. The cashier must have inserted THIS depositor's vault image first
    cmp BYTE PTR cshActiveUser, 0
    je needVaultImage
    invoke lstrcmpiA, addr cshActiveUser, addr req.Username
    test eax, eax
    jz vaultMatchesRequest
needVaultImage:
    invoke lstrcpyA, addr szNeedMsg, offset szNeedPart1
    invoke lstrcatA, addr szNeedMsg, addr req.Username
    invoke lstrcatA, addr szNeedMsg, offset szNeedPart2
    invoke SetStatus, 4, addr szNeedMsg, 1
    mov eax, SV_ERR_INPUT
    ret
vaultMatchesRequest:
    invoke lstrcpyA, addr szPath, addr cshActivePath

    ; Read BMP file
    invoke ReadWholeFile, addr szPath, addr fileSize
    .IF eax == 0
        invoke SetStatus, 4, offset szErrCashierOpenImage, 1
        mov eax, SV_ERR_IO
        ret
    .ENDIF
    mov pBmp, eax

    ; Read current vault stream
    invoke ReadVaultStream, pBmp, addr stream
    .IF eax != SV_OK
        invoke GetProcessHeap
        invoke HeapFree, eax, 0, pBmp
        invoke SetStatus, 4, offset szErrCashierOpenImage, 1
        mov eax, SV_ERR_CHECKSUM
        ret
    .ENDIF

    ; Check Magic
    .IF DWORD PTR [stream] != SVLT_MAGIC
        invoke GetProcessHeap
        invoke HeapFree, eax, 0, pBmp
        invoke SetStatus, 4, offset szErrCashierOpenImage, 1
        mov eax, SV_ERR_MAGIC
        ret
    .ENDIF

    ; Derive Cashier KEK and unwrap DEK from stream[24h]
    invoke DeriveCashierKek, addr kekCashier
    invoke SvUnwrapDek, addr stream[24h], addr kekCashier, addr dek
    invoke SvWipe, addr kekCashier, 32

    ; Extract current Nonce from stream[68h]
    mov eax, DWORD PTR [stream + 68h]
    mov curNonce, eax

    ; Copy encrypted record from stream[6Ch]
    lea esi, stream[6Ch]
    lea edi, rec
    mov ecx, ACC_REC_SIZE
    rep movsb

    ; Decrypt record in place with dek, curNonce
    invoke SvCipher, addr rec, ACC_REC_SIZE, addr dek, curNonce, 0

    ; Verify FNV-32 Checksum
    invoke SvFnv32, addr rec, ACC_REC_SIZE
    xor eax, DWORD PTR [dek]
    .IF eax != DWORD PTR [stream + 44h]
        invoke GetProcessHeap
        invoke HeapFree, eax, 0, pBmp
        invoke SvWipe, addr dek, 32
        invoke SvWipe, addr rec, ACC_REC_SIZE
        invoke SetStatus, 4, offset szErrCashierOpenImage, 1
        mov eax, SV_ERR_CHECKSUM
        ret
    .ENDIF

    ; 4. Approving never moves money: free the image, mark the request approved
    invoke GetProcessHeap
    invoke HeapFree, eax, 0, pBmp
    invoke ReqSetStatus, reqIdx, REQ_STATUS_APPROVED

    ; Wipe sensitive buffers
    invoke SvWipe, addr dek, 32
    invoke SvWipe, addr rec, ACC_REC_SIZE

    ; 10. Refresh list box and alert banner
    invoke PopulateCashierRequests, hwndParent
    invoke SetStatus, 4, offset szStatusApprovedOk, 0

    ; Update alert banner count
    invoke ReqCountPending
    .IF eax > 0
        mov ecx, eax
        invoke ItoaDec, ecx, addr szBalDigits
        lea edi, szBalFull
        invoke lstrcpyA, edi, addr szBalDigits
        invoke lstrcatA, addr szBalFull, offset szPendingAlertSuffix
        invoke SetWindowTextA, hCshAlertLbl, addr szBalFull
    .ELSE
        invoke SetWindowTextA, hCshAlertLbl, offset szNoPendingAlert
    .ENDIF

    ; 11. Ask how to apply it; the amount itself is entered manually
    invoke lstrcpyA, addr szNeedMsg, offset szApprPart1
    invoke lstrcatA, addr szNeedMsg, offset cshActiveUser
    invoke lstrcatA, addr szNeedMsg, offset szApprPart2
    invoke ThemedDialog, hwndParent, offset szApprTitle, addr szNeedMsg, offset szBtnDeposit, offset szBtnWithdraw, offset szBtnClose, DLG_KIND_INFO
    .IF eax == 1 || eax == 2
        mov ebx, eax
        invoke SetCashierMode, CSH_MODE_UPDATE
        .IF ebx == 1
            invoke SendMessageA, hCshRadioDep, BM_SETCHECK, BST_CHECKED, 0
            invoke SendMessageA, hCshRadioWdr, BM_SETCHECK, BST_UNCHECKED, 0
        .ELSE
            invoke SendMessageA, hCshRadioDep, BM_SETCHECK, BST_UNCHECKED, 0
            invoke SendMessageA, hCshRadioWdr, BM_SETCHECK, BST_CHECKED, 0
        .ENDIF
        invoke SetWindowTextA, hCshManualAmt, offset szEmptyStr
        invoke SetFocus, hCshManualAmt
    .ENDIF

    mov eax, SV_OK
    ret
DoCashierApprove ENDP

; ------------------------------------------------------------------------------
; DoCashierReject: Rejects selected transaction request (sets Status to 2)
; Inputs:  hwndParent (DWORD)
; Outputs: EAX = SV_OK or error
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
DoCashierReject PROC USES ebx esi edi hwndParent:DWORD
    LOCAL curSel:DWORD
    LOCAL reqIdx:DWORD
    LOCAL hFile:DWORD
    LOCAL bytesRead:DWORD
    LOCAL req:REQUEST_RECORD
    LOCAL szDigits[16]:BYTE
    LOCAL szBuf[48]:BYTE

    cld
    invoke SendMessageA, hCshReqList, LB_GETCURSEL, 0, 0
    .IF eax == LB_ERR
        invoke SetStatus, 4, offset szErrNoReqSelected, 1
        mov eax, SV_ERR_INPUT
        ret
    .ENDIF
    mov curSel, eax

    invoke SendMessageA, hCshReqList, LB_GETITEMDATA, curSel, 0
    .IF eax == LB_ERR
        invoke SetStatus, 4, offset szErrNoReqSelected, 1
        mov eax, SV_ERR_INPUT
        ret
    .ENDIF
    mov reqIdx, eax

    ; Read request
    invoke CreateFileA, offset szRequestsFile, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
    .IF eax == INVALID_HANDLE_VALUE
        invoke SetStatus, 4, offset szErrReqAlreadyDone, 1
        mov eax, SV_ERR_IO
        ret
    .ENDIF
    mov hFile, eax

    mov eax, reqIdx
    mov ecx, REQ_REC_SIZE
    mul ecx
    invoke SetFilePointer, hFile, eax, 0, FILE_BEGIN
    invoke ReadFile, hFile, addr req, REQ_REC_SIZE, addr bytesRead, 0
    invoke CloseHandle, hFile

    .IF bytesRead != REQ_REC_SIZE
        invoke SetStatus, 4, offset szErrReqAlreadyDone, 1
        mov eax, SV_ERR_IO
        ret
    .ENDIF

    .IF req.Status != REQ_STATUS_PENDING
        invoke SetStatus, 4, offset szErrReqAlreadyDone, 1
        mov eax, SV_ERR_INPUT
        ret
    .ENDIF

    ; Update Status to 2 (Rejected)
    invoke ReqSetStatus, reqIdx, REQ_STATUS_REJECTED

    ; Refresh list box
    invoke PopulateCashierRequests, hwndParent
    invoke SetStatus, 4, offset szStatusRejectedOk, 0

    ; Update alert banner count
    invoke ReqCountPending
    .IF eax > 0
        mov ecx, eax
        invoke ItoaDec, ecx, addr szDigits
        lea edi, szBuf
        invoke lstrcpyA, edi, addr szDigits
        invoke lstrcatA, addr szBuf, offset szPendingAlertSuffix
        invoke SetWindowTextA, hCshAlertLbl, addr szBuf
    .ELSE
        invoke SetWindowTextA, hCshAlertLbl, offset szNoPendingAlert
    .ENDIF

    mov eax, SV_OK
    ret
DoCashierReject ENDP

; ------------------------------------------------------------------------------
; DoCashierManualAdjust: Applies manual deposit or withdrawal to loaded vault
; Inputs:  hwndParent (DWORD)
; Outputs: EAX = SV_OK or error
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
DoCashierManualAdjust PROC USES ebx esi edi hwndParent:DWORD
    LOCAL newNonce:DWORD
    LOCAL szAmtText[32]:BYTE
    LOCAL dwAmount:DWORD
    LOCAL adjType:DWORD
    LOCAL pBmp:DWORD
    LOCAL fileSize:DWORD
    LOCAL stream[256]:BYTE
    LOCAL kekCashier[32]:BYTE
    LOCAL dek[32]:BYTE
    LOCAL curNonce:DWORD
    LOCAL rec:ACCOUNT_RECORD
    LOCAL szBalDigits[16]:BYTE
    LOCAL szBalFull[48]:BYTE

    mov eax, hwndParent
    cld
    ; 1. Check if a depositor is loaded
    cmp cshActivePath[0], 0
    jnz vaultIsLoaded
    invoke SetStatus, 4, offset szErrNoVaultLoaded, 1
    mov eax, SV_ERR_INPUT
    ret

vaultIsLoaded:
    ; 2. Determine adjustment type from radio buttons
    invoke SendMessageA, hCshRadioDep, BM_GETCHECK, 0, 0
    .IF eax == BST_CHECKED
        mov adjType, REQ_TYPE_DEPOSIT
    .ELSE
        invoke SendMessageA, hCshRadioWdr, BM_GETCHECK, 0, 0
        .IF eax == BST_CHECKED
            mov adjType, REQ_TYPE_WITHDRAW
        .ELSE
            invoke SetStatus, 4, offset szErrReqType, 1
            mov eax, SV_ERR_INPUT
            ret
        .ENDIF
    .ENDIF

    ; 3. Read and validate amount
    invoke GetWindowTextA, hCshManualAmt, addr szAmtText, sizeof szAmtText
    .IF eax == 0
        invoke SetStatus, 4, offset szErrReqEmptyAmt, 1
        mov eax, SV_ERR_INPUT
        ret
    .ENDIF

    invoke AtoiDec, addr szAmtText
    .IF edx != 0
        invoke SetStatus, 4, offset szErrReqInvalidAmt, 1
        mov eax, SV_ERR_INPUT
        ret
    .ENDIF
    mov dwAmount, eax

    invoke ValidateAmount, dwAmount
    .IF eax == 0
        invoke SetStatus, 4, offset szErrReqInvalidAmt, 1
        mov eax, SV_ERR_INPUT
        ret
    .ENDIF

    ; 4. Read vault BMP file
    invoke ReadWholeFile, addr cshActivePath, addr fileSize
    .IF eax == 0
        invoke SetStatus, 4, offset szErrCashierOpenImage, 1
        mov eax, SV_ERR_IO
        ret
    .ENDIF
    mov pBmp, eax

    invoke ReadVaultStream, pBmp, addr stream
    .IF eax != SV_OK
        invoke GetProcessHeap
        invoke HeapFree, eax, 0, pBmp
        invoke SetStatus, 4, offset szErrCashierOpenImage, 1
        mov eax, SV_ERR_CHECKSUM
        ret
    .ENDIF

    ; Unwrap DEK
    invoke DeriveCashierKek, addr kekCashier
    invoke SvUnwrapDek, addr stream[24h], addr kekCashier, addr dek
    invoke SvWipe, addr kekCashier, 32

    mov eax, DWORD PTR [stream + 68h]
    mov curNonce, eax

    ; Decrypt record
    lea esi, stream[6Ch]
    lea edi, rec
    mov ecx, ACC_REC_SIZE
    rep movsb

    invoke SvCipher, addr rec, ACC_REC_SIZE, addr dek, curNonce, 0

    ; Verify Checksum
    invoke SvFnv32, addr rec, ACC_REC_SIZE
    xor eax, DWORD PTR [dek]
    .IF eax != DWORD PTR [stream + 44h]
        invoke GetProcessHeap
        invoke HeapFree, eax, 0, pBmp
        invoke SvWipe, addr dek, 32
        invoke SvWipe, addr rec, ACC_REC_SIZE
        invoke SetStatus, 4, offset szErrCashierOpenImage, 1
        mov eax, SV_ERR_CHECKSUM
        ret
    .ENDIF

    ; Apply adjustment
    .IF adjType == REQ_TYPE_DEPOSIT
        mov eax, rec.Balance
        add eax, dwAmount
        .IF CARRY?
            invoke GetProcessHeap
            invoke HeapFree, eax, 0, pBmp
            invoke SvWipe, addr dek, 32
            invoke SvWipe, addr rec, ACC_REC_SIZE
            invoke SetStatus, 4, offset szErrApproveOverflow, 1
            mov eax, SV_ERR_INPUT
            ret
        .ENDIF
        mov rec.Balance, eax
    .ELSEIF adjType == REQ_TYPE_WITHDRAW
        mov eax, dwAmount
        .IF eax > rec.Balance
            invoke GetProcessHeap
            invoke HeapFree, eax, 0, pBmp
            invoke SvWipe, addr dek, 32
            invoke SvWipe, addr rec, ACC_REC_SIZE
                    invoke SetStatus, 4, offset szErrApproveFunds, 1
            mov eax, SV_ERR_FUNDS
            ret
        .ENDIF
        mov eax, rec.Balance
        sub eax, dwAmount
        mov rec.Balance, eax
    .ENDIF

    ; Nonce increment
    mov eax, curNonce
    inc eax
    mov newNonce, eax

    ; Re-encrypt
    invoke BuildVaultImage, pBmp, fileSize, addr rec, addr dek, newNonce, 0, 0
    .IF eax != SV_OK
        invoke GetProcessHeap
        invoke HeapFree, eax, 0, pBmp
        invoke SvWipe, addr dek, 32
        invoke SvWipe, addr rec, ACC_REC_SIZE
        invoke SetStatus, 4, offset szErrApproveWrite, 1
        mov eax, SV_ERR_IO
        ret
    .ENDIF

    ; Atomically write BMP
    invoke AtomicWriteFile, addr cshActivePath, pBmp, fileSize
    .IF eax != SV_OK
        invoke GetProcessHeap
        invoke HeapFree, eax, 0, pBmp
        invoke SvWipe, addr dek, 32
        invoke SvWipe, addr rec, ACC_REC_SIZE
        invoke SetStatus, 4, offset szErrApproveWrite, 1
        mov eax, SV_ERR_IO
        ret
    .ENDIF

    invoke GetProcessHeap
    invoke HeapFree, eax, 0, pBmp

    ; Update LastNonce in users.dat
    invoke UsersSetNonce, addr rec.Username, newNonce

    ; Update active session record
    lea esi, rec
    lea edi, cshActiveRec
    mov ecx, ACC_REC_SIZE
    rep movsb
    mov eax, newNonce
    mov cshActiveNonce, eax

    ; Update Screen 4 Balance display
    mov ecx, cshActiveRec.Balance
    invoke ItoaDec, ecx, addr szBalDigits
    lea edi, szBalFull
    invoke lstrcpyA, edi, offset szCurrencyPrefix
    invoke lstrcatA, addr szBalFull, addr szBalDigits
    invoke SetWindowTextA, hCshDetailBal, addr szBalFull

    ; Clear amount edit box
    invoke SetWindowTextA, hCshManualAmt, offset szEmptyStr

    ; Wipe secrets
    invoke SvWipe, addr dek, 32
    invoke SvWipe, addr rec, ACC_REC_SIZE

    invoke SetStatus, 4, offset szStatusManualOk, 0
    mov eax, SV_OK
    ret
DoCashierManualAdjust ENDP

; ------------------------------------------------------------------------------
; ValidateUsername: Checks 3..31 chars of [A-Za-z0-9_] and rejects "admin"
; Inputs:  pStr (DWORD ptr)
; Outputs: EAX = 1 if valid, 0 if invalid
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
ValidateUsername PROC USES ebx esi edi pStr:DWORD
    LOCAL nLen:DWORD

    mov esi, pStr
    test esi, esi
    jz invalidUser

    invoke lstrlenA, esi
    mov nLen, eax
    cmp eax, 3
    jb invalidUser
    cmp eax, 31
    ja invalidUser

    ; Check reserved name "admin"
    invoke lstrcmpiA, esi, offset szReservedAdmin
    test eax, eax
    jz invalidUser

    ; Verify each char is [A-Za-z0-9_]
    mov esi, pStr
checkUserChars:
    movzx eax, BYTE PTR [esi]
    test al, al
    jz validUser

    ; Check '_'
    cmp al, '_'
    je nextUserChar

    ; Check '0'..'9'
    cmp al, '0'
    jb invalidUser
    cmp al, '9'
    jbe nextUserChar

    ; Check 'A'..'Z'
    cmp al, 'A'
    jb invalidUser
    cmp al, 'Z'
    jbe nextUserChar

    ; Check 'a'..'z'
    cmp al, 'a'
    jb invalidUser
    cmp al, 'z'
    jbe nextUserChar

    jmp invalidUser

nextUserChar:
    inc esi
    jmp checkUserChars

validUser:
    mov eax, 1
    ret

invalidUser:
    xor eax, eax
    ret
ValidateUsername ENDP

; ------------------------------------------------------------------------------
; ValidatePassword: Checks 6..31 printable characters (ASCII 32..126)
; Inputs:  pStr (DWORD ptr)
; Outputs: EAX = 1 if valid, 0 if invalid
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
ValidatePassword PROC USES ebx esi edi pStr:DWORD
    mov esi, pStr
    test esi, esi
    jz invalidPass

    invoke lstrlenA, esi
    cmp eax, 6
    jb invalidPass
    cmp eax, 31
    ja invalidPass

    mov esi, pStr
checkPassChars:
    movzx eax, BYTE PTR [esi]
    test al, al
    jz validPass
    cmp al, 32
    jb invalidPass
    cmp al, 126
    ja invalidPass
    inc esi
    jmp checkPassChars

validPass:
    mov eax, 1
    ret

invalidPass:
    xor eax, eax
    ret
ValidatePassword ENDP

; ------------------------------------------------------------------------------
; ValidateFullName: Checks 1..63 printable characters (ASCII 32..126)
; Inputs:  pStr (DWORD ptr)
; Outputs: EAX = 1 if valid, 0 if invalid
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
ValidateFullName PROC USES ebx esi edi pStr:DWORD
    mov esi, pStr
    test esi, esi
    jz invalidName

    invoke lstrlenA, esi
    cmp eax, 1
    jb invalidName
    cmp eax, 63
    ja invalidName

    mov esi, pStr
checkNameChars:
    movzx eax, BYTE PTR [esi]
    test al, al
    jz validName
    cmp al, 32
    jb invalidName
    cmp al, 126
    ja invalidName
    inc esi
    jmp checkNameChars

validName:
    mov eax, 1
    ret

invalidName:
    xor eax, eax
    ret
ValidateFullName ENDP

; ------------------------------------------------------------------------------
; ValidateCnic: Checks format ddddd-ddddddd-d (exactly 15 chars)
; Inputs:  pStr (DWORD ptr)
; Outputs: EAX = 1 if valid, 0 if invalid
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
ValidateCnic PROC USES ebx esi edi pStr:DWORD
    mov esi, pStr
    test esi, esi
    jz invalidCnic

    invoke lstrlenA, esi
    cmp eax, 15
    jne invalidCnic

    mov esi, pStr
    xor ecx, ecx

checkCnicLoop:
    cmp ecx, 15
    jge validCnic
    movzx eax, BYTE PTR [esi + ecx]

    .IF ecx == 5 || ecx == 13
        cmp al, '-'
        jne invalidCnic
    .ELSE
        cmp al, '0'
        jb invalidCnic
        cmp al, '9'
        ja invalidCnic
    .ENDIF

    inc ecx
    jmp checkCnicLoop

validCnic:
    mov eax, 1
    ret

invalidCnic:
    xor eax, eax
    ret
ValidateCnic ENDP

; ------------------------------------------------------------------------------
; ValidateContact: Checks 10..15 chars, digits, optional leading '+'
; Inputs:  pStr (DWORD ptr)
; Outputs: EAX = 1 if valid, 0 if invalid
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
ValidateContact PROC USES ebx esi edi pStr:DWORD
    LOCAL nLen:DWORD

    mov esi, pStr
    test esi, esi
    jz invalidContact

    invoke lstrlenA, esi
    mov nLen, eax
    cmp eax, 10
    jb invalidContact
    cmp eax, 15
    ja invalidContact

    mov esi, pStr
    ; Check optional leading '+'
    movzx eax, BYTE PTR [esi]
    cmp al, '+'
    jne checkPhoneDigits
    inc esi

checkPhoneDigits:
    movzx eax, BYTE PTR [esi]
    test al, al
    jz validContact
    cmp al, '0'
    jb invalidContact
    cmp al, '9'
    ja invalidContact
    inc esi
    jmp checkPhoneDigits

validContact:
    mov eax, 1
    ret

invalidContact:
    xor eax, eax
    ret
ValidateContact ENDP

; ------------------------------------------------------------------------------
; ValidateAmount: Checks 1..MAX_TXN_AMOUNT (100,000,000)
; Inputs:  amount (DWORD)
; Outputs: EAX = 1 if valid, 0 if invalid
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
ValidateAmount PROC USES ebx esi edi amount:DWORD
    mov eax, amount
    cmp eax, 1
    jb invalidAmt
    cmp eax, MAX_TXN_AMOUNT
    ja invalidAmt
    mov eax, 1
    ret

invalidAmt:
    xor eax, eax
    ret
ValidateAmount ENDP

; ------------------------------------------------------------------------------
; AtoiDec: Converts decimal string to DWORD with strict validation
; Inputs:  pStr (DWORD ptr)
; Outputs: EAX = value, EDX = 0 (success) or 1 (invalid/overflow)
; Preserved: EBX, ESI, EDI
; Clobbered: ECX
; ------------------------------------------------------------------------------
AtoiDec PROC USES ebx esi edi pStr:DWORD
    LOCAL val:DWORD

    mov esi, pStr
    test esi, esi
    jz badNum

    ; Must not be empty
    movzx eax, BYTE PTR [esi]
    test al, al
    jz badNum

    mov val, 0

atoiLoop:
    movzx eax, BYTE PTR [esi]
    test al, al
    jz atoiSuccess

    ; Only digits '0'..'9' permitted (rejects '-', '+', spaces, letters)
    cmp al, '0'
    jb badNum
    cmp al, '9'
    ja badNum

    sub al, '0'
    movzx ebx, al   ; ebx = digit

    ; val = val * 10
    mov eax, val
    mov ecx, 10
    mul ecx
    test edx, edx
    jnz badNum      ; 32-bit overflow

    ; val = val + digit
    add eax, ebx
    jc badNum       ; 32-bit overflow
    mov val, eax

    inc esi
    jmp atoiLoop

atoiSuccess:
    mov eax, val
    xor edx, edx
    ret

badNum:
    xor eax, eax
    mov edx, 1
    ret
AtoiDec ENDP

; ------------------------------------------------------------------------------
; ItoaDec: Converts DWORD value to decimal ASCII string
; Inputs:  val (DWORD), pBufOut (DWORD ptr)
; Outputs: EAX = length of string
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
ItoaDec PROC USES ebx esi edi val:DWORD, pBufOut:DWORD
    LOCAL szTmp[16]:BYTE
    LOCAL count:DWORD

    mov edi, pBufOut
    test edi, edi
    jz itoaExitZero

    mov eax, val
    .IF eax == 0
        mov BYTE PTR [edi], '0'
        mov BYTE PTR [edi + 1], 0
        mov eax, 1
        ret
    .ENDIF

    mov count, 0
    lea esi, szTmp

extractDigits:
    test eax, eax
    jz writeReversed
    xor edx, edx
    mov ecx, 10
    div ecx
    add dl, '0'
    mov [esi], dl
    inc esi
    inc count
    jmp extractDigits

writeReversed:
    mov ecx, count
    mov eax, count

reverseLoop:
    dec esi
    mov dl, [esi]
    mov [edi], dl
    inc edi
    dec ecx
    jnz reverseLoop

    mov BYTE PTR [edi], 0
    ret

itoaExitZero:
    xor eax, eax
    ret
ItoaDec ENDP

; ==============================================================================
; THEME: drawing helpers (vault look: graphite + brass on ivory)
; ==============================================================================

; PctOf: EAX = v * pct / 100        (clobbers ECX, EDX only)
PctOf PROC v:DWORD, pct:DWORD
    mov eax, v
    imul eax, pct
    xor edx, edx
    mov ecx, 100
    div ecx
    ret
PctOf ENDP

; FillRc: solid rectangle (absolute client coordinates)
FillRc PROC USES ebx hdc:DWORD, x1:DWORD, y1:DWORD, x2:DWORD, y2:DWORD, clr:DWORD
    LOCAL rc:RECT
    mov eax, x1
    mov rc.left, eax
    mov eax, y1
    mov rc.top, eax
    mov eax, x2
    mov rc.right, eax
    mov eax, y2
    mov rc.bottom, eax
    invoke SetDCBrushColor, hdc, clr
    invoke GetStockObject, DC_BRUSH
    mov ebx, eax
    invoke FillRect, hdc, addr rc, ebx
    ret
FillRc ENDP

; FrameRc: 1-pixel outline of a rectangle
FrameRc PROC USES ebx esi edi hdc:DWORD, x1:DWORD, y1:DWORD, x2:DWORD, y2:DWORD, clr:DWORD
    mov ecx, y1
    inc ecx
    invoke FillRc, hdc, x1, y1, x2, ecx, clr
    mov ecx, y2
    dec ecx
    invoke FillRc, hdc, x1, ecx, x2, y2, clr
    mov ecx, x1
    inc ecx
    invoke FillRc, hdc, x1, y1, ecx, y2, clr
    mov ecx, x2
    dec ecx
    invoke FillRc, hdc, ecx, y1, x2, y2, clr
    ret
FrameRc ENDP

; LerpColor: EAX = colour between c1 and c2 (num/den), per RGB channel
LerpColor PROC USES ebx esi c1:DWORD, c2:DWORD, num:DWORD, den:DWORD
    LOCAL res:DWORD
    mov res, 0
    xor esi, esi                    ; bit shift 0, 8, 16
lerpChan:
    mov ecx, esi
    mov eax, c1
    shr eax, cl
    and eax, 0FFh
    mov ebx, eax
    mov eax, c2
    shr eax, cl
    and eax, 0FFh
    sub eax, ebx
    imul eax, num
    cdq
    idiv den
    add eax, ebx
    and eax, 0FFh
    mov ecx, esi
    shl eax, cl
    or res, eax
    add esi, 8
    cmp esi, 24
    jb lerpChan
    mov eax, res
    ret
LerpColor ENDP

; DrawTxt: text in content coordinates (the centring offset is added here)
DrawTxt PROC USES ebx esi edi hdc:DWORD, pText:DWORD, x1:DWORD, y1:DWORD, x2:DWORD, y2:DWORD, hFnt:DWORD, clr:DWORD, flags:DWORD
    LOCAL rc:RECT
    mov eax, x1
    add eax, curOffX
    mov rc.left, eax
    mov eax, y1
    add eax, curOffY
    mov rc.top, eax
    mov eax, x2
    add eax, curOffX
    mov rc.right, eax
    mov eax, y2
    add eax, curOffY
    mov rc.bottom, eax
    invoke SetBkMode, hdc, TRANSPARENT
    invoke SetTextColor, hdc, clr
    invoke SelectObject, hdc, hFnt
    invoke DrawTextA, hdc, pText, -1, addr rc, flags
    ret
DrawTxt ENDP

; DrawVaultWheel: stylised vault wheel (ring, inner ring, 6 spokes, 12 bolts, hub)
DrawVaultWheel PROC USES ebx esi edi hdc:DWORD, cx0:DWORD, cy0:DWORD, r:DWORD, clrRing:DWORD, clrBolt:DWORD
    LOCAL hPen:DWORD
    LOCAL hOldPen:DWORD
    LOCAL hOldBrush:DWORD
    LOCAL penW:DWORD
    LOCAL rr:DWORD
    LOCAL rb:DWORD
    LOCAL br:DWORD
    LOCAL hr:DWORD
    LOCAL idx:DWORD
    LOCAL px:DWORD
    LOCAL py:DWORD

    mov eax, r
    xor edx, edx
    mov ecx, 12
    div ecx
    cmp eax, 2
    jae wheelPenOk
    mov eax, 2
wheelPenOk:
    mov penW, eax
    mov eax, r
    xor edx, edx
    mov ecx, 16
    div ecx
    cmp eax, 2
    jae wheelBrOk
    mov eax, 2
wheelBrOk:
    mov br, eax
    invoke PctOf, r, 72
    mov rr, eax
    invoke PctOf, r, 86
    mov rb, eax
    invoke PctOf, r, 24
    mov hr, eax

    invoke CreatePen, PS_SOLID, penW, clrRing
    mov hPen, eax
    invoke SelectObject, hdc, hPen
    mov hOldPen, eax
    invoke GetStockObject, NULL_BRUSH
    invoke SelectObject, hdc, eax
    mov hOldBrush, eax

    ; outer ring
    mov esi, cx0
    sub esi, r
    mov edi, cy0
    sub edi, r
    mov ebx, cx0
    add ebx, r
    mov eax, cy0
    add eax, r
    invoke Ellipse, hdc, esi, edi, ebx, eax
    ; inner ring
    mov esi, cx0
    sub esi, rr
    mov edi, cy0
    sub edi, rr
    mov ebx, cx0
    add ebx, rr
    mov eax, cy0
    add eax, rr
    invoke Ellipse, hdc, esi, edi, ebx, eax

    ; six spokes (every second table angle)
    mov idx, 0
wheelSpoke:
    invoke MoveToEx, hdc, cx0, cy0, 0
    mov ecx, idx
    shl ecx, 1
    add ecx, wheelPhase
    cmp ecx, 12
    jb spokeIdxA
    sub ecx, 12
spokeIdxA:
    mov eax, wheelCos[ecx*4]
    imul eax, rr
    cdq
    mov ebx, 100
    idiv ebx
    add eax, cx0
    mov px, eax
    mov ecx, idx
    shl ecx, 1
    add ecx, wheelPhase
    cmp ecx, 12
    jb spokeIdxB
    sub ecx, 12
spokeIdxB:
    mov eax, wheelSin[ecx*4]
    imul eax, rr
    cdq
    mov ebx, 100
    idiv ebx
    add eax, cy0
    mov py, eax
    invoke LineTo, hdc, px, py
    inc idx
    cmp idx, 6
    jb wheelSpoke

    ; filled parts use the DC brush
    invoke GetStockObject, DC_BRUSH
    invoke SelectObject, hdc, eax
    invoke SetDCBrushColor, hdc, clrBolt

    mov idx, 0
wheelBolt:
    mov ecx, idx
    mov eax, wheelCos[ecx*4]
    imul eax, rb
    cdq
    mov ebx, 100
    idiv ebx
    add eax, cx0
    mov px, eax
    mov ecx, idx
    mov eax, wheelSin[ecx*4]
    imul eax, rb
    cdq
    mov ebx, 100
    idiv ebx
    add eax, cy0
    mov py, eax
    mov esi, px
    sub esi, br
    mov edi, py
    sub edi, br
    mov ebx, px
    add ebx, br
    mov eax, py
    add eax, br
    invoke Ellipse, hdc, esi, edi, ebx, eax
    inc idx
    cmp idx, 12
    jb wheelBolt

    ; hub
    invoke SetDCBrushColor, hdc, clrRing
    mov esi, cx0
    sub esi, hr
    mov edi, cy0
    sub edi, hr
    mov ebx, cx0
    add ebx, hr
    mov eax, cy0
    add eax, hr
    invoke Ellipse, hdc, esi, edi, ebx, eax

    invoke SelectObject, hdc, hOldBrush
    invoke SelectObject, hdc, hOldPen
    invoke DeleteObject, hPen
    mov eax, 1
    ret
DrawVaultWheel ENDP

; DrawCard: ivory card with soft shadow, hairline border, brass top edge and an
;           optional divider line (lineY = offset below the card top, 0 = none).
;           Coordinates are in content space (centring offset added here).
DrawCard PROC USES ebx esi edi hdc:DWORD, cx1:DWORD, cy1:DWORD, cardW:DWORD, cardH:DWORD, lineY:DWORD
    LOCAL x1:DWORD
    LOCAL y1:DWORD
    LOCAL x2:DWORD
    LOCAL y2:DWORD

    mov eax, cx1
    add eax, curOffX
    mov x1, eax
    add eax, cardW
    mov x2, eax
    mov eax, cy1
    add eax, curOffY
    mov y1, eax
    add eax, cardH
    mov y2, eax

    mov esi, x1
    add esi, 3
    mov edi, y1
    add edi, 3
    mov ebx, x2
    add ebx, 3
    mov eax, y2
    add eax, 3
    invoke FillRc, hdc, esi, edi, ebx, eax, COLOR_SHADOW
    invoke FillRc, hdc, x1, y1, x2, y2, COLOR_CANVAS
    invoke FrameRc, hdc, x1, y1, x2, y2, COLOR_BORDER
    mov eax, y1
    add eax, 3
    invoke FillRc, hdc, x1, y1, x2, eax, COLOR_BRASS
    .IF lineY != 0
        mov eax, y1
        add eax, lineY
        mov ecx, eax
        inc ecx
        mov esi, x1
        add esi, 14
        mov edi, x2
        sub edi, 14
        invoke FillRc, hdc, esi, eax, edi, ecx, COLOR_BORDER
    .ENDIF
    mov eax, 1
    ret
DrawCard ENDP

; PaintHeader: graphite gradient band, brass rule, vault-wheel emblem, wordmark
PaintHeader PROC USES ebx esi edi hdc:DWORD, rcRight:DWORD, pSub:DWORD
    LOCAL rcT:RECT
    LOCAL idx:DWORD
    LOCAL clr:DWORD

    mov idx, 0
hdrBand:
    invoke LerpColor, COLOR_HEADER, COLOR_HEADER2, idx, 23
    mov clr, eax
    mov esi, idx
    imul esi, 3
    mov edi, esi
    add edi, 3
    invoke FillRc, hdc, 0, esi, rcRight, edi, clr
    inc idx
    cmp idx, 24
    jb hdrBand

    invoke FillRc, hdc, 0, HEADER_HEIGHT - 3, rcRight, HEADER_HEIGHT, COLOR_BRASS
    invoke DrawVaultWheel, hdc, 46, 34, 25, COLOR_BRASS, COLOR_BRASS_LT

    invoke SetBkMode, hdc, TRANSPARENT
    ; wordmark
    mov rcT.left, 88
    mov rcT.top, 6
    mov rcT.right, 560
    mov rcT.bottom, 42
    invoke SetTextColor, hdc, COLOR_BRANDTXT
    invoke SelectObject, hdc, hFontBrand
    invoke DrawTextA, hdc, offset szBrandText, -1, addr rcT, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX
    ; subtitle
    mov eax, subSlide
    add eax, 90
    mov rcT.left, eax
    mov rcT.top, 42
    mov rcT.right, 700
    mov rcT.bottom, 63
    invoke SetTextColor, hdc, COLOR_BRASS_LT
    invoke SelectObject, hdc, hFontBody
    invoke DrawTextA, hdc, pSub, -1, addr rcT, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX
    ; right-hand tag (only when there is room)
    .IF rcRight >= 960
        mov eax, rcRight
        sub eax, 300
        mov rcT.left, eax
        mov rcT.top, 10
        mov eax, rcRight
        sub eax, 24
        mov rcT.right, eax
        mov rcT.bottom, 34
        invoke SetTextColor, hdc, COLOR_MIST
        invoke DrawTextA, hdc, offset szHdrTag, -1, addr rcT, DT_RIGHT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX
        mov esi, rcRight
        sub esi, 150
        mov edi, rcRight
        sub edi, 24
        invoke FrameRc, hdc, esi, 40, edi, 60, COLOR_BRASS_DK
        mov eax, esi
        add eax, 10
        mov ebx, eax
        add ebx, 8
        .IF blinkOn == 1
            invoke FillRc, hdc, eax, 46, ebx, 54, COLOR_SUCCESS
        .ELSE
            invoke FillRc, hdc, eax, 46, ebx, 54, COLOR_HEADER2
        .ENDIF
        mov rcT.left, esi
        add rcT.left, 22
        mov rcT.top, 40
        mov rcT.right, edi
        mov rcT.bottom, 60
        invoke SetTextColor, hdc, COLOR_BRASS_LT
        invoke DrawTextA, hdc, offset szSealed, -1, addr rcT, DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX
    .ENDIF
    mov eax, 1
    ret
PaintHeader ENDP

; GetCtlTextColor: text colour for plain statics (card titles use brass)
GetCtlTextColor PROC hCtl:DWORD
    mov eax, hCtl
    .IF eax == hDepProfileGrp || eax == hDepTxnGrp || eax == hCshDetailGrp || eax == hCshManualGrp
        mov eax, COLOR_BRASS_DK
    .ELSE
        mov eax, COLOR_TEXT
    .ENDIF
    ret
GetCtlTextColor ENDP

; DrawListItem: owner-drawn list row (slate selection, hairline separator)
DrawListItem PROC USES ebx esi edi pDrawItem:DWORD
    LOCAL szItem[128]:BYTE
    LOCAL rcT:RECT
    LOCAL clrBg:DWORD
    LOCAL clrTx:DWORD

    mov esi, pDrawItem
    assume esi:PTR DRAWITEMSTRUCT
    mov clrBg, COLOR_INPUT
    mov clrTx, COLOR_TEXT
    test [esi].itemState, ODS_SELECTED
    jz listNotSel
    mov clrBg, COLOR_STEEL
    mov clrTx, COLOR_WHITE
listNotSel:
    invoke FillRc, [esi].hDC, [esi].rcItem.left, [esi].rcItem.top, [esi].rcItem.right, [esi].rcItem.bottom, clrBg
    cmp [esi].itemID, -1
    je listItemDone
    mov BYTE PTR szItem, 0
    invoke SendMessageA, [esi].hwndItem, LB_GETTEXT, [esi].itemID, addr szItem
    cmp eax, LB_ERR
    je listItemDone
    mov eax, [esi].rcItem.left
    add eax, 8
    mov rcT.left, eax
    mov eax, [esi].rcItem.top
    mov rcT.top, eax
    mov eax, [esi].rcItem.right
    mov rcT.right, eax
    mov eax, [esi].rcItem.bottom
    mov rcT.bottom, eax
    invoke SetBkMode, [esi].hDC, TRANSPARENT
    invoke SetTextColor, [esi].hDC, clrTx
    invoke SelectObject, [esi].hDC, hFontBody
    invoke DrawTextA, [esi].hDC, addr szItem, -1, addr rcT, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX
    test [esi].itemState, ODS_SELECTED
    jnz listItemDone
    mov eax, [esi].rcItem.bottom
    dec eax
    invoke FillRc, [esi].hDC, [esi].rcItem.left, eax, [esi].rcItem.right, [esi].rcItem.bottom, COLOR_SHADOW
listItemDone:
    assume esi:NOTHING
    mov eax, 1
    ret
DrawListItem ENDP

; DrawTile: small feature box - card, wheel badge, bold title, wrapped caption
DrawTile PROC USES ebx esi edi hdc:DWORD, tx:DWORD, ty:DWORD, tw:DWORD, th:DWORD, pTitle:DWORD, pSub:DWORD
    LOCAL wx:DWORD
    LOCAL wy:DWORD
    invoke DrawCard, hdc, tx, ty, tw, th, 0
    mov eax, tx
    add eax, 36
    add eax, curOffX
    mov wx, eax
    mov eax, th
    shr eax, 1
    add eax, ty
    add eax, curOffY
    mov wy, eax
    invoke DrawVaultWheel, hdc, wx, wy, 18, COLOR_BRASS_DK, COLOR_BRASS
    mov esi, tx
    add esi, 68
    mov edi, tx
    add edi, tw
    sub edi, 10
    mov eax, ty
    add eax, 12
    mov ebx, ty
    add ebx, 34
    invoke DrawTxt, hdc, pTitle, esi, eax, edi, ebx, hFontBold, COLOR_TEXT, DT_LEFT or DT_SINGLELINE or DT_NOPREFIX
    mov eax, ty
    add eax, 36
    mov ebx, ty
    add ebx, th
    sub ebx, 6
    invoke DrawTxt, hdc, pSub, esi, eax, edi, ebx, hFontBody, COLOR_SLATE, DT_LEFT or DT_WORDBREAK or DT_NOPREFIX
    mov eax, 1
    ret
DrawTile ENDP

; PaintCards: cards / side panels for the current screen
PaintCards PROC USES ebx esi edi hdc:DWORD
    LOCAL szDig[16]:BYTE
    LOCAL szLine[96]:BYTE
    LOCAL px:DWORD
    LOCAL py:DWORD

    mov eax, curScreen
    .IF eax == 1
        invoke DrawCard, hdc, 20, 122, 728, 318, 0
        mov eax, 764
        add eax, curOffX
        mov px, eax
        mov eax, 122
        add eax, curOffY
        mov py, eax
        mov esi, px
        add esi, 176
        mov edi, py
        add edi, 318
        invoke FillRc, hdc, px, py, esi, edi, COLOR_PANEL_DK
        mov eax, py
        add eax, 3
        invoke FillRc, hdc, px, py, esi, eax, COLOR_BRASS
        mov eax, px
        add eax, 88
        mov ebx, py
        add ebx, 70
        invoke DrawVaultWheel, hdc, eax, ebx, 40, COLOR_BRASS, COLOR_BRASS_LT
        mov eax, py
        add eax, 120
        mov ebx, eax
        inc ebx
        mov ecx, px
        add ecx, 44
        mov edx, px
        add edx, 132
        invoke FillRc, hdc, ecx, eax, edx, ebx, COLOR_BRASS_DK
        invoke DrawTxt, hdc, offset szSideTitle, 764, 252, 940, 276, hFontBold, COLOR_BRASS_LT, DT_CENTER or DT_SINGLELINE or DT_NOPREFIX
        invoke DrawTxt, hdc, offset szSideText, 772, 290, 932, 436, hFontBody, COLOR_MIST, DT_CENTER or DT_NOPREFIX
        invoke DrawTile, hdc, 24, 458, 288, 86, offset szTileA1, offset szTileA2
        invoke DrawTile, hdc, 336, 458, 288, 86, offset szTileB1, offset szTileB2
        invoke DrawTile, hdc, 648, 458, 288, 86, offset szTileC1, offset szTileC2
    .ELSEIF eax == 2
        invoke DrawCard, hdc, 24, 80, 912, 350, 0
        invoke PaintStrength, hdc
        invoke DrawTile, hdc, 24, 446, 288, 86, offset szTileA1, offset szTileA2
        invoke DrawTile, hdc, 336, 446, 288, 86, offset szTileB1, offset szTileB2
        invoke DrawTile, hdc, 648, 446, 288, 86, offset szTileC1, offset szTileC2
    .ELSEIF eax == 3
        invoke DrawCard, hdc, 32, 85, 430, 360, 34
        invoke DrawCard, hdc, 490, 85, 438, 360, 34
        invoke DrawBankCard, hdc, 32, 456
        invoke DrawTile, hdc, 376, 456, 272, 96, offset szTileE1, offset szTileE2
        invoke DrawTile, hdc, 658, 456, 272, 96, offset szTileF1, offset szTileF2
    .ELSEIF eax == 4
        invoke DrawCard, hdc, 24, 108, 470, 286, 0
        invoke DrawCard, hdc, 502, 108, 432, 218, 0
        invoke DrawCard, hdc, 24, 402, 470, 182, 32
        invoke DrawCard, hdc, 502, 330, 432, 254, 32

        ; bottom-left: workflow guide unless the balance-update box is shown
        .IF cshMode != CSH_MODE_UPDATE
            invoke DrawTxt, hdc, offset szWfTitle, 42, 410, 470, 430, hFontBold, COLOR_BRASS_DK, DT_LEFT or DT_SINGLELINE or DT_NOPREFIX
            invoke DrawTxt, hdc, offset szWf1, 42, 446, 480, 468, hFontBody, COLOR_TEXT, DT_LEFT or DT_SINGLELINE or DT_NOPREFIX
            invoke DrawTxt, hdc, offset szWf2, 42, 482, 480, 504, hFontBody, COLOR_TEXT, DT_LEFT or DT_SINGLELINE or DT_NOPREFIX
            invoke DrawTxt, hdc, offset szWf3, 42, 518, 480, 540, hFontBody, COLOR_TEXT, DT_LEFT or DT_SINGLELINE or DT_NOPREFIX
        .ENDIF

        ; bottom-right: details are real controls; other modes are painted here
        .IF cshMode == CSH_MODE_UPDATE
            invoke DrawTxt, hdc, offset szUpdTitle, 518, 338, 920, 360, hFontBold, COLOR_BRASS_DK, DT_LEFT or DT_SINGLELINE or DT_NOPREFIX
            invoke lstrcpyA, addr szLine, offset szUpdUser
            invoke lstrcatA, addr szLine, offset cshActiveUser
            invoke DrawTxt, hdc, addr szLine, 522, 376, 920, 400, hFontBody, COLOR_TEXT, DT_LEFT or DT_SINGLELINE or DT_NOPREFIX
            invoke DrawTxt, hdc, offset szUpdBalLbl, 522, 428, 920, 450, hFontBold, COLOR_SLATE, DT_LEFT or DT_SINGLELINE or DT_NOPREFIX
            invoke ItoaDec, cshActiveRec.Balance, addr szDig
            invoke lstrcpyA, addr szLine, offset szCurrencyPrefix
            invoke lstrcatA, addr szLine, addr szDig
            invoke DrawTxt, hdc, addr szLine, 522, 452, 920, 490, hFontHeader, COLOR_TEXT, DT_LEFT or DT_SINGLELINE or DT_NOPREFIX
        .ELSEIF cshMode != CSH_MODE_DETAILS
            invoke DrawTxt, hdc, offset szLockTitle, 518, 338, 920, 360, hFontBold, COLOR_BRASS_DK, DT_LEFT or DT_SINGLELINE or DT_NOPREFIX
            mov eax, 718
            add eax, curOffX
            mov ebx, 430
            add ebx, curOffY
            invoke DrawVaultWheel, hdc, eax, ebx, 38, COLOR_BRASS, COLOR_BRASS_DK
            invoke DrawTxt, hdc, offset szLockL1, 502, 488, 934, 510, hFontBody, COLOR_SLATE, DT_CENTER or DT_SINGLELINE or DT_NOPREFIX
            invoke DrawTxt, hdc, offset szLockL2, 502, 510, 934, 532, hFontBody, COLOR_SLATE, DT_CENTER or DT_SINGLELINE or DT_NOPREFIX
        .ENDIF
    .ENDIF
    mov eax, 1
    ret
PaintCards ENDP

; ==============================================================================
; Cashier panels: which box is visible after a vault is unlocked
; ==============================================================================
AddCshDet PROC USES ecx edx hCtl:DWORD
    mov ecx, nCshDet
    .IF ecx < 24
        mov edx, hCtl
        mov hCshDetCtls[ecx*4], edx
        inc nCshDet
    .ENDIF
    invoke AddControlToScreen, 4, hCtl
    ret
AddCshDet ENDP

AddCshMan PROC USES ecx edx hCtl:DWORD
    mov ecx, nCshMan
    .IF ecx < 12
        mov edx, hCtl
        mov hCshManCtls[ecx*4], edx
        inc nCshMan
    .ENDIF
    invoke AddControlToScreen, 4, hCtl
    ret
AddCshMan ENDP

; SetCashierMode: CSH_MODE_NONE / DETAILS / UPDATE -> show only the chosen panel
SetCashierMode PROC USES ebx esi edi mode:DWORD
    mov eax, mode
    mov cshMode, eax
    cmp curScreen, SCREEN_CASHIER
    jne modeRepaint

    xor esi, esi
modeDetLoop:
    cmp esi, nCshDet
    jge modeDetDone
    mov edx, SW_HIDE
    .IF cshMode == CSH_MODE_DETAILS
        mov edx, SW_SHOW
    .ENDIF
    invoke ShowWindow, hCshDetCtls[esi*4], edx
    inc esi
    jmp modeDetLoop
modeDetDone:
    xor esi, esi
modeManLoop:
    cmp esi, nCshMan
    jge modeManDone
    mov edx, SW_HIDE
    .IF cshMode == CSH_MODE_UPDATE
        mov edx, SW_SHOW
    .ENDIF
    invoke ShowWindow, hCshManCtls[esi*4], edx
    inc esi
    jmp modeManLoop
modeManDone:
modeRepaint:
    invoke InvalidateRect, hMain, 0, 1
    mov eax, SV_OK
    ret
SetCashierMode ENDP

; ShowCashierChooser: after a vault is unlocked ask what to do with the account
ShowCashierChooser PROC USES ebx esi edi hwndParent:DWORD
    LOCAL szMsg[200]:BYTE
    cmp BYTE PTR cshActiveUser, 0
    je chooserEnd
    invoke lstrcpyA, addr szMsg, offset szChoosePart1
    invoke lstrcatA, addr szMsg, offset cshActiveUser
    invoke lstrcatA, addr szMsg, offset szChoosePart2
    invoke ThemedDialog, hwndParent, offset szChooseTitle, addr szMsg, offset szBtnViewDet, offset szBtnUpdBal, offset szBtnClose, DLG_KIND_INFO
    .IF eax == 1
        invoke SetCashierMode, CSH_MODE_DETAILS
    .ELSEIF eax == 2
        invoke SetCashierMode, CSH_MODE_UPDATE
    .ELSE
        invoke SetCashierMode, CSH_MODE_NONE
    .ENDIF
chooserEnd:
    mov eax, SV_OK
    ret
ShowCashierChooser ENDP

; ==============================================================================
; Themed modal dialog (replaces the grey system message box)
; ==============================================================================
DlgProc PROC USES ebx esi edi hwnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    LOCAL ps:PAINTSTRUCT
    LOCAL rcT:RECT
    LOCAL nBtn:DWORD
    LOCAL clrKind:DWORD
    LOCAL szGlyph[4]:BYTE

    .IF uMsg == WM_CREATE
        mov nBtn, 1
        .IF dlgB2 != 0
            inc nBtn
        .ENDIF
        .IF dlgB3 != 0
            inc nBtn
        .ENDIF
        ; total width = n*BTN_W + (n-1)*12 ; start x = DLG_W - 24 - total
        mov eax, nBtn
        imul eax, DLG_BTN_W
        mov ecx, nBtn
        dec ecx
        imul ecx, 12
        add eax, ecx
        mov esi, DLG_W - 24
        sub esi, eax

        invoke CreateWindowExA, 0, offset szButtonClass, dlgB1,
               WS_CHILD or WS_VISIBLE or WS_TABSTOP or BS_OWNERDRAW,
               esi, DLG_H - 58, DLG_BTN_W, DLG_BTN_H, hwnd, IDC_DLG_BTN1, hInst, 0
        mov hDlgBtn1, eax
        add esi, DLG_BTN_W + 12
        mov hDlgBtn2, 0
        mov hDlgBtn3, 0
        .IF dlgB2 != 0
            invoke CreateWindowExA, 0, offset szButtonClass, dlgB2,
                   WS_CHILD or WS_VISIBLE or WS_TABSTOP or BS_OWNERDRAW,
                   esi, DLG_H - 58, DLG_BTN_W, DLG_BTN_H, hwnd, IDC_DLG_BTN2, hInst, 0
            mov hDlgBtn2, eax
            add esi, DLG_BTN_W + 12
        .ENDIF
        .IF dlgB3 != 0
            invoke CreateWindowExA, 0, offset szButtonClass, dlgB3,
                   WS_CHILD or WS_VISIBLE or WS_TABSTOP or BS_OWNERDRAW,
                   esi, DLG_H - 58, DLG_BTN_W, DLG_BTN_H, hwnd, IDC_DLG_BTN3, hInst, 0
            mov hDlgBtn3, eax
        .ENDIF
        xor eax, eax
        ret

    .ELSEIF uMsg == WM_ERASEBKGND
        mov eax, 1
        ret

    .ELSEIF uMsg == WM_PAINT
        invoke BeginPaint, hwnd, addr ps
        mov clrKind, COLOR_BRASS
        mov BYTE PTR szGlyph, 'i'
        mov BYTE PTR [szGlyph + 1], 0
        .IF dlgKind == DLG_KIND_ERROR
            mov clrKind, COLOR_ERROR
            mov BYTE PTR szGlyph, '!'
        .ELSEIF dlgKind == DLG_KIND_QUESTION
            mov BYTE PTR szGlyph, '?'
        .ELSEIF dlgKind == DLG_KIND_WARNING
            mov clrKind, COLOR_BRASS_DK
            mov BYTE PTR szGlyph, '!'
        .ENDIF

        invoke FillRc, ps.hdc, 0, 0, DLG_W, DLG_H, COLOR_CANVAS
        invoke FillRc, ps.hdc, 0, 0, DLG_W, 46, COLOR_HEADER
        invoke FillRc, ps.hdc, 0, 46, DLG_W, 49, COLOR_BRASS
        invoke FrameRc, ps.hdc, 0, 0, DLG_W, DLG_H, COLOR_HEADER

        ; icon disc
        invoke SetDCBrushColor, ps.hdc, clrKind
        invoke SetDCPenColor, ps.hdc, clrKind
        invoke GetStockObject, DC_BRUSH
        invoke SelectObject, ps.hdc, eax
        invoke GetStockObject, DC_PEN
        invoke SelectObject, ps.hdc, eax
        invoke Ellipse, ps.hdc, 14, 9, 42, 37
        invoke SetBkMode, ps.hdc, TRANSPARENT
        mov rcT.left, 14
        mov rcT.top, 9
        mov rcT.right, 42
        mov rcT.bottom, 37
        invoke SetTextColor, ps.hdc, COLOR_WHITE
        invoke SelectObject, ps.hdc, hFontBold
        invoke DrawTextA, ps.hdc, addr szGlyph, -1, addr rcT, DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX

        ; title
        mov rcT.left, 54
        mov rcT.top, 0
        mov rcT.right, DLG_W - 16
        mov rcT.bottom, 46
        invoke SetTextColor, ps.hdc, COLOR_BRANDTXT
        invoke DrawTextA, ps.hdc, dlgTitle, -1, addr rcT, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX

        ; message
        mov rcT.left, 28
        mov rcT.top, 66
        mov rcT.right, DLG_W - 28
        mov rcT.bottom, DLG_H - 66
        invoke SetTextColor, ps.hdc, COLOR_TEXT
        invoke SelectObject, ps.hdc, hFontBody
        invoke DrawTextA, ps.hdc, dlgMsg, -1, addr rcT, DT_LEFT or DT_WORDBREAK or DT_NOPREFIX

        invoke EndPaint, hwnd, addr ps
        xor eax, eax
        ret

    .ELSEIF uMsg == WM_DRAWITEM
        invoke DrawOwnerItem, hwnd, lParam
        mov eax, 1
        ret

    .ELSEIF uMsg == WM_COMMAND
        mov eax, wParam
        movzx edx, ax
        .IF edx >= IDC_DLG_BTN1 && edx <= IDC_DLG_BTN3
            sub edx, 7000
            mov dlgResult, edx
            mov dlgDone, 1
        .ENDIF
        xor eax, eax
        ret

    .ELSEIF uMsg == WM_CLOSE
        mov dlgResult, 0
        mov dlgDone, 1
        xor eax, eax
        ret
    .ENDIF

    invoke DefWindowProcA, hwnd, uMsg, wParam, lParam
    ret
DlgProc ENDP

; ThemedDialog: modal popup centred over the main window.
; Returns the 1-based number of the pressed button (0 = closed with Esc / X).
ThemedDialog PROC USES ebx esi edi hwndParent:DWORD, pTitle:DWORD, pMsg:DWORD, pB1:DWORD, pB2:DWORD, pB3:DWORD, kind:DWORD
    LOCAL wc:WNDCLASSEX
    LOCAL rcP:RECT
    LOCAL msg:MSG
    LOCAL hOwner:DWORD
    LOCAL dx0:DWORD
    LOCAL dy0:DWORD

    cmp dlgClassReg, 0
    jne dlgClassOk
    mov wc.cbSize, sizeof WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, offset DlgProc
    mov wc.cbClsExtra, 0
    mov wc.cbWndExtra, 0
    mov eax, hInst
    mov wc.hInstance, eax
    mov wc.hIcon, 0
    mov wc.hIconSm, 0
    invoke LoadCursorA, 0, IDC_ARROW
    mov wc.hCursor, eax
    mov eax, hbrCanvas
    mov wc.hbrBackground, eax
    mov wc.lpszMenuName, 0
    mov wc.lpszClassName, offset szDlgClass
    invoke RegisterClassExA, addr wc
    mov dlgClassReg, 1
dlgClassOk:

    mov eax, pTitle
    mov dlgTitle, eax
    mov eax, pMsg
    mov dlgMsg, eax
    mov eax, pB1
    mov dlgB1, eax
    mov eax, pB2
    mov dlgB2, eax
    mov eax, pB3
    mov dlgB3, eax
    mov eax, kind
    mov dlgKind, eax
    mov dlgDone, 0
    mov dlgResult, 0

    mov eax, hwndParent
    test eax, eax
    jnz dlgHaveOwner
    mov eax, hMain
dlgHaveOwner:
    mov hOwner, eax

    invoke GetWindowRect, hOwner, addr rcP
    mov eax, rcP.left
    add eax, rcP.right
    sub eax, DLG_W
    sar eax, 1
    mov dx0, eax
    mov eax, rcP.top
    add eax, rcP.bottom
    sub eax, DLG_H
    sar eax, 1
    mov dy0, eax

    .IF kind == DLG_KIND_ERROR
        invoke MessageBeep, MB_ICONERROR
    .ENDIF

    invoke EnableWindow, hOwner, 0
    invoke CreateWindowExA, WS_EX_TOOLWINDOW, offset szDlgClass, pTitle,
           WS_POPUP or WS_VISIBLE, dx0, dy0, DLG_W, DLG_H, hOwner, 0, hInst, 0
    mov hDlgWnd, eax
    test eax, eax
    jnz dlgCreated
    invoke EnableWindow, hOwner, 1
    xor eax, eax
    ret
dlgCreated:
    invoke SetForegroundWindow, hDlgWnd
    invoke SetFocus, hDlgBtn1

dlgPump:
    cmp dlgDone, 0
    jne dlgPumpEnd
    invoke GetMessageA, addr msg, 0, 0, 0
    cmp eax, 0
    je dlgQuit
    cmp eax, -1
    je dlgPumpEnd
    .IF msg.message == WM_KEYDOWN
        .IF msg.wParam == VK_ESCAPE
            mov dlgResult, 0
            mov dlgDone, 1
            jmp dlgPump
        .ELSEIF msg.wParam == VK_RETURN
            mov dlgResult, 1
            invoke GetFocus
            .IF eax != 0
                .IF eax == hDlgBtn2
                    mov dlgResult, 2
                .ELSEIF eax == hDlgBtn3
                    mov dlgResult, 3
                .ENDIF
            .ENDIF
            mov dlgDone, 1
            jmp dlgPump
        .ENDIF
    .ENDIF
    invoke IsDialogMessageA, hDlgWnd, addr msg
    test eax, eax
    jnz dlgPump
    invoke TranslateMessage, addr msg
    invoke DispatchMessageA, addr msg
    jmp dlgPump
dlgQuit:
    invoke PostQuitMessage, msg.wParam
dlgPumpEnd:
    invoke EnableWindow, hOwner, 1
    invoke DestroyWindow, hDlgWnd
    mov hDlgWnd, 0
    mov hDlgBtn1, 0
    mov hDlgBtn2, 0
    mov hDlgBtn3, 0
    invoke SetForegroundWindow, hOwner
    mov eax, dlgResult
    ret
ThemedDialog ENDP

; ThemedMsgBox: drop-in replacement for MessageBoxA (OK or Yes/No, 4 icon kinds)
ThemedMsgBox PROC USES ebx esi edi hwnd:DWORD, pText:DWORD, pCaption:DWORD, uType:DWORD
    LOCAL kind:DWORD

    cmp hwnd, 0
    jne tmbThemed
    invoke MessageBoxA, hwnd, pText, pCaption, uType
    ret
tmbThemed:
    mov kind, DLG_KIND_INFO
    mov eax, uType
    and eax, 0F0h
    .IF eax == 10h
        mov kind, DLG_KIND_ERROR
    .ELSEIF eax == 20h
        mov kind, DLG_KIND_QUESTION
    .ELSEIF eax == 30h
        mov kind, DLG_KIND_WARNING
    .ENDIF
    mov eax, uType
    and eax, 0Fh
    .IF eax == MB_YESNO
        invoke ThemedDialog, hwnd, pCaption, pText, offset szBtnYes, offset szBtnNo, 0, kind
        .IF eax == 1
            mov eax, IDYES
        .ELSE
            mov eax, IDNO
        .ENDIF
        ret
    .ENDIF
    invoke ThemedDialog, hwnd, pCaption, pText, offset szBtnOk, 0, 0, kind
    mov eax, IDOK
    ret
ThemedMsgBox ENDP



; ==============================================================================
; Splash screen (black full-screen intro) and footer bar
; ==============================================================================
.data
szSplashClass       BYTE "StegoVaultSplash", 0
szSplashTitle       BYTE "S T E G O V A U L T", 0
szSplashSub         BYTE "ENCRYPTED   STEGANOGRAPHIC   VAULT", 0
szSplashMsg1        BYTE "Securing the vault...", 0
szSplashMsg2        BYTE "Loading the encryption engine...", 0
szSplashMsg3        BYTE "Vault ready.", 0
szFootL             BYTE "StegoVault Bank   |   Accounts hidden inside pictures", 0
szFootOut           BYTE "Signed out", 0
szFootDep           BYTE "Depositor session", 0
szFootCsh           BYTE "Cashier session", 0

.data?
splashT             DWORD ?
splashDone          DWORD ?
hSplashFontT        DWORD ?
hSplashFontS        DWORD ?

.code

; SplashFade: colour fading from black to target; t0 = start frame, dur = frames
SplashFade PROC t:DWORD, t0:DWORD, dur:DWORD, target:DWORD
    mov eax, t
    sub eax, t0
    jns sfPos
    xor eax, eax
sfPos:
    cmp eax, dur
    jbe sfOk
    mov eax, dur
sfOk:
    invoke LerpColor, 0, target, eax, dur
    ret
SplashFade ENDP

; SplashBracket: one L-shaped corner bracket (dx, dy = +1 / -1 direction)
SplashBracket PROC USES ebx esi edi hdc:DWORD, bx0:DWORD, by0:DWORD, dirX:DWORD, dirY:DWORD, clr:DWORD
    ; horizontal arm
    mov esi, bx0
    mov edi, bx0
    .IF dirX == 1
        add edi, 28
    .ELSE
        sub esi, 28
    .ENDIF
    mov eax, by0
    mov ebx, by0
    .IF dirY == 1
        add ebx, 3
    .ELSE
        sub eax, 3
    .ENDIF
    invoke FillRc, hdc, esi, eax, edi, ebx, clr
    ; vertical arm
    mov esi, bx0
    mov edi, bx0
    .IF dirX == 1
        add edi, 3
    .ELSE
        sub esi, 3
    .ENDIF
    mov eax, by0
    mov ebx, by0
    .IF dirY == 1
        add ebx, 28
    .ELSE
        sub eax, 28
    .ENDIF
    invoke FillRc, hdc, esi, eax, edi, ebx, clr
    mov eax, 1
    ret
SplashBracket ENDP

; SplashDraw: one animation frame into hdc (w x h)
SplashDraw PROC USES ebx esi edi hdc:DWORD, w:DWORD, h:DWORD, t:DWORD
    LOCAL cx0:DWORD
    LOCAL cy0:DWORD
    LOCAL r:DWORD
    LOCAL clrA:DWORD
    LOCAL clrB:DWORD
    LOCAL ty:DWORD
    LOCAL rcT:RECT
    LOCAL half:DWORD
    LOCAL off0:DWORD

    invoke FillRc, hdc, 0, 0, w, h, 0
    mov eax, w
    shr eax, 1
    mov cx0, eax
    mov eax, h
    shr eax, 1
    sub eax, 50
    mov cy0, eax

    ; wheel radius grows with an ease
    mov eax, t
    .IF eax > 30
        mov eax, 30
    .ENDIF
    imul eax, 70
    xor edx, edx
    mov ecx, 30
    div ecx
    add eax, 20
    mov r, eax

    invoke SplashFade, t, 0, 30, COLOR_BRASS
    mov clrA, eax
    invoke SplashFade, t, 0, 30, COLOR_BRASS_LT
    mov clrB, eax
    invoke DrawVaultWheel, hdc, cx0, cy0, r, clrA, clrB

    ; keyhole in the hub once the wheel has opened
    .IF t >= 30
        invoke GetStockObject, 4                ; BLACK_BRUSH
        invoke SelectObject, hdc, eax
        mov esi, cx0
        sub esi, 5
        mov edi, cy0
        sub edi, 8
        mov ebx, cx0
        add ebx, 6
        mov eax, cy0
        add eax, 3
        invoke Ellipse, hdc, esi, edi, ebx, eax
        mov esi, cx0
        sub esi, 2
        mov edi, cy0
        mov ebx, cx0
        add ebx, 3
        mov eax, cy0
        add eax, 10
        invoke FillRc, hdc, esi, edi, ebx, eax, 0
    .ENDIF

    ; viewfinder brackets: the "picture" that hides the vault
    .IF t >= 20
        invoke SplashFade, t, 20, 25, COLOR_BRASS_DK
        mov clrA, eax
        mov eax, r
        add eax, 34
        mov off0, eax
        mov esi, cx0
        sub esi, off0
        mov edi, cy0
        sub edi, off0
        invoke SplashBracket, hdc, esi, edi, 1, 1, clrA
        mov esi, cx0
        add esi, off0
        invoke SplashBracket, hdc, esi, edi, -1, 1, clrA
        mov edi, cy0
        add edi, off0
        invoke SplashBracket, hdc, esi, edi, -1, -1, clrA
        mov esi, cx0
        sub esi, off0
        invoke SplashBracket, hdc, esi, edi, 1, -1, clrA
    .ENDIF

    ; wordmark
    mov eax, cy0
    add eax, 130
    mov ty, eax
    mov rcT.left, 0
    mov eax, ty
    mov rcT.top, eax
    mov eax, w
    mov rcT.right, eax
    add eax, 0
    mov eax, ty
    add eax, 64
    mov rcT.bottom, eax
    invoke SplashFade, t, 25, 30, COLOR_BRANDTXT
    invoke SetTextColor, hdc, eax
    invoke SetBkMode, hdc, TRANSPARENT
    invoke SelectObject, hdc, hSplashFontT
    invoke DrawTextA, hdc, offset szSplashTitle, -1, addr rcT, DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX

    ; brass rule that draws itself outward
    mov eax, t
    sub eax, 40
    jns ruleOk
    xor eax, eax
ruleOk:
    .IF eax > 30
        mov eax, 30
    .ENDIF
    imul eax, 5
    mov half, eax
    mov esi, cx0
    sub esi, half
    mov edi, cx0
    add edi, half
    mov eax, ty
    add eax, 70
    mov ebx, eax
    add ebx, 2
    invoke FillRc, hdc, esi, eax, edi, ebx, COLOR_BRASS

    ; tagline
    mov eax, ty
    add eax, 82
    mov rcT.top, eax
    add eax, 28
    mov rcT.bottom, eax
    invoke SplashFade, t, 50, 30, COLOR_BRASS_LT
    invoke SetTextColor, hdc, eax
    invoke SelectObject, hdc, hSplashFontS
    invoke DrawTextA, hdc, offset szSplashSub, -1, addr rcT, DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX

    ; loading line and progress bar
    mov eax, h
    sub eax, 112
    mov rcT.top, eax
    add eax, 22
    mov rcT.bottom, eax
    invoke SplashFade, t, 8, 20, COLOR_MIST
    invoke SetTextColor, hdc, eax
    mov esi, offset szSplashMsg1
    .IF t >= 35
        mov esi, offset szSplashMsg2
    .ENDIF
    .IF t >= 72
        mov esi, offset szSplashMsg3
    .ENDIF
    invoke DrawTextA, hdc, esi, -1, addr rcT, DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX

    mov esi, cx0
    sub esi, 150
    mov edi, cx0
    add edi, 150
    mov eax, h
    sub eax, 80
    mov ebx, eax
    add ebx, 3
    invoke FillRc, hdc, esi, eax, edi, ebx, 00241C14h
    mov eax, t
    .IF eax > 105
        mov eax, 105
    .ENDIF
    imul eax, 300
    xor edx, edx
    mov ecx, 105
    div ecx
    add eax, esi
    mov edi, eax
    mov eax, h
    sub eax, 80
    mov ebx, eax
    add ebx, 3
    invoke FillRc, hdc, esi, eax, edi, ebx, COLOR_BRASS
    mov eax, 1
    ret
SplashDraw ENDP

SplashProc PROC USES ebx esi edi hwnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    LOCAL ps:PAINTSTRUCT
    LOCAL rc:RECT
    LOCAL bx0:DWORD
    LOCAL by0:DWORD

    mov eax, uMsg
    .IF eax == WM_ERASEBKGND
        mov eax, 1
        ret
    .ELSEIF eax == WM_TIMER
        invoke GetTickCount
        sub eax, splashStart
        xor edx, edx
        mov ecx, 30
        div ecx
        mov splashT, eax
        .IF eax >= 108
            mov splashDone, 1
        .ENDIF
        ; repaint only the animated box (not the whole screen)
        invoke GetClientRect, hwnd, addr rc
        mov eax, rc.right
        sub eax, SPL_BOX_W
        shr eax, 1
        mov rc.left, eax
        add eax, SPL_BOX_W
        mov rc.right, eax
        mov eax, rc.bottom
        sub eax, SPL_BOX_H
        shr eax, 1
        .IF SDWORD PTR eax < 0
            xor eax, eax
        .ENDIF
        mov rc.top, eax
        add eax, SPL_BOX_H
        mov rc.bottom, eax
        invoke InvalidateRect, hwnd, addr rc, 0
        xor eax, eax
        ret
    .ELSEIF eax == WM_KEYDOWN || eax == 0201h   ; any key / left click skips
        mov splashDone, 1
        xor eax, eax
        ret
    .ELSEIF eax == WM_PAINT
        invoke BeginPaint, hwnd, addr ps
        invoke GetClientRect, hwnd, addr rc
        .IF splashInit == 0
            invoke FillRc, ps.hdc, 0, 0, rc.right, rc.bottom, 0
            invoke CreateCompatibleDC, ps.hdc
            mov hSpMem, eax
            invoke CreateCompatibleBitmap, ps.hdc, SPL_BOX_W, SPL_BOX_H
            mov hSpBmp, eax
            invoke SelectObject, hSpMem, hSpBmp
            mov hSpOld, eax
            mov splashInit, 1
        .ENDIF
        invoke SplashDraw, hSpMem, SPL_BOX_W, SPL_BOX_H, splashT
        mov eax, rc.right
        sub eax, SPL_BOX_W
        shr eax, 1
        mov bx0, eax
        mov eax, rc.bottom
        sub eax, SPL_BOX_H
        shr eax, 1
        .IF SDWORD PTR eax < 0
            xor eax, eax
        .ENDIF
        mov by0, eax
        invoke BitBlt, ps.hdc, bx0, by0, SPL_BOX_W, SPL_BOX_H, hSpMem, 0, 0, SRCCOPY
        invoke EndPaint, hwnd, addr ps
        xor eax, eax
        ret
    .ENDIF
    invoke DefWindowProcA, hwnd, uMsg, wParam, lParam
    ret
SplashProc ENDP

; RunSplash: black full-screen intro animation, returns when finished / skipped
RunSplash PROC USES ebx esi edi
    LOCAL wc:WNDCLASSEX
    LOCAL msg:MSG
    LOCAL hSp:DWORD
    LOCAL sw:DWORD
    LOCAL sh:DWORD

    mov splashT, 0
    mov splashDone, 0
    mov splashInit, 0
    invoke GetTickCount
    mov splashStart, eax
    invoke GetSystemMetrics, 0
    mov sw, eax
    invoke GetSystemMetrics, 1
    mov sh, eax

    invoke RtlZeroMemory, addr wc, sizeof WNDCLASSEX
    mov wc.cbSize, sizeof WNDCLASSEX
    mov wc.lpfnWndProc, offset SplashProc
    mov eax, hInst
    mov wc.hInstance, eax
    invoke LoadCursorA, 0, IDC_ARROW
    mov wc.hCursor, eax
    invoke GetStockObject, 4
    mov wc.hbrBackground, eax
    mov wc.lpszClassName, offset szSplashClass
    invoke RegisterClassExA, addr wc
    test eax, eax
    jz splashExit

    invoke CreateFontA, -58, 0, 0, 0, FW_BOLD, 0, 0, 0, DEFAULT_CHARSET, 0, 0, 4, 0, offset szFontGeorgia
    mov hSplashFontT, eax
    invoke CreateFontA, -17, 0, 0, 0, 400, 0, 0, 0, DEFAULT_CHARSET, 0, 0, 4, 0, offset szFontSegoe
    mov hSplashFontS, eax

    invoke CreateWindowExA, WS_EX_TOPMOST or WS_EX_TOOLWINDOW, offset szSplashClass, offset szBankTitle,
           WS_POPUP or WS_VISIBLE, 0, 0, sw, sh, 0, 0, hInst, 0
    mov hSp, eax
    test eax, eax
    jz splashFonts
    invoke SetForegroundWindow, hSp
    invoke SetTimer, hSp, 1, 15, 0
    invoke UpdateWindow, hSp

splashLoop:
    cmp splashDone, 0
    jne splashEnd
    invoke GetMessageA, addr msg, 0, 0, 0
    test eax, eax
    jz splashQuit
    cmp eax, -1
    je splashEnd
    invoke TranslateMessage, addr msg
    invoke DispatchMessageA, addr msg
    jmp splashLoop
splashQuit:
    invoke PostQuitMessage, msg.wParam
splashEnd:
    invoke KillTimer, hSp, 1
    invoke DestroyWindow, hSp
splashFonts:
    .IF splashInit != 0
        invoke SelectObject, hSpMem, hSpOld
        invoke DeleteObject, hSpBmp
        invoke DeleteDC, hSpMem
        mov splashInit, 0
    .ENDIF
    invoke DeleteObject, hSplashFontT
    invoke DeleteObject, hSplashFontS
splashExit:
    mov eax, 1
    ret
RunSplash ENDP

; PaintFooter: slim graphite status bar along the bottom edge
PaintFooter PROC USES ebx esi edi hdc:DWORD, fw:DWORD, fh:DWORD
    LOCAL rcT:RECT
    mov esi, fh
    sub esi, 26
    invoke FillRc, hdc, 0, esi, fw, fh, COLOR_HEADER
    mov eax, esi
    add eax, 1
    invoke FillRc, hdc, 0, esi, fw, eax, COLOR_BRASS
    invoke SetBkMode, hdc, TRANSPARENT
    invoke SelectObject, hdc, hFontBody
    mov rcT.left, 16
    mov eax, esi
    add eax, 2
    mov rcT.top, eax
    mov rcT.right, 640
    mov eax, fh
    mov rcT.bottom, eax
    invoke SetTextColor, hdc, COLOR_MIST
    invoke DrawTextA, hdc, offset szFootL, -1, addr rcT, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX
    mov eax, fw
    sub eax, 260
    mov rcT.left, eax
    mov eax, fw
    sub eax, 34
    mov rcT.right, eax
    mov eax, offset szFootOut
    .IF curScreen == 3
        mov eax, offset szFootDep
    .ELSEIF curScreen == 4
        mov eax, offset szFootCsh
    .ENDIF
    mov edi, eax
    invoke SetTextColor, hdc, COLOR_BRASS_LT
    invoke DrawTextA, hdc, edi, -1, addr rcT, DT_RIGHT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX
    ; status dot
    mov eax, fw
    sub eax, 24
    mov ebx, eax
    add ebx, 8
    mov ecx, esi
    add ecx, 9
    mov edx, ecx
    add edx, 8
    .IF blinkOn == 1
        invoke FillRc, hdc, eax, ecx, ebx, edx, COLOR_SUCCESS
    .ELSE
        invoke FillRc, hdc, eax, ecx, ebx, edx, COLOR_HEADER2
    .ENDIF
    mov eax, 1
    ret
PaintFooter ENDP



; PaintStrength: live password-strength meter under the registration password box
PaintStrength PROC USES ebx esi edi hdc:DWORD
    LOCAL szP[64]:BYTE
    LOCAL len:DWORD
    LOCAL score:DWORD
    LOCAL clrSeg:DWORD
    LOCAL ax0:DWORD
    LOCAL ay0:DWORD
    LOCAL pWord:DWORD

    mov BYTE PTR szP, 0
    invoke GetWindowTextA, hEditRegPass, addr szP, 63
    invoke lstrlenA, addr szP
    mov len, eax
    lea esi, szP
    xor ebx, ebx
strNext:
    movzx eax, BYTE PTR [esi]
    test eax, eax
    jz strCounted
    inc esi
    .IF al >= '0' && al <= '9'
        or ebx, 1
    .ELSEIF al >= 'A' && al <= 'Z'
        or ebx, 2
    .ELSEIF al >= 'a' && al <= 'z'
        or ebx, 4
    .ELSE
        or ebx, 8
    .ENDIF
    jmp strNext
strCounted:
    xor edi, edi
    .IF len >= 6
        inc edi
    .ENDIF
    .IF len >= 10
        inc edi
    .ENDIF
    mov eax, ebx
    and eax, 6
    .IF eax != 0 && (ebx & 1)
        inc edi
    .ENDIF
    mov eax, ebx
    and eax, 6
    .IF eax == 6
        inc edi
    .ENDIF
    test ebx, 8
    jz strNoSym
    inc edi
strNoSym:
    .IF edi > 4
        mov edi, 4
    .ENDIF
    .IF len < 6 && edi > 1
        mov edi, 1
    .ENDIF
    mov score, edi

    mov clrSeg, COLOR_ERROR
    mov pWord, offset szStrWeak
    .IF edi == 2
        mov clrSeg, COLOR_BRASS_DK
        mov pWord, offset szStrFair
    .ELSEIF edi == 3
        mov clrSeg, COLOR_BRASS
        mov pWord, offset szStrGood
    .ELSEIF edi == 4
        mov clrSeg, COLOR_SUCCESS
        mov pWord, offset szStrStrong
    .ENDIF
    .IF len == 0
        mov pWord, offset szStrEmpty
    .ENDIF

    mov eax, curOffX
    add eax, 40
    mov ax0, eax
    mov eax, curOffY
    add eax, 243
    mov ay0, eax
    xor esi, esi
strSeg:
    mov eax, esi
    imul eax, 96
    add eax, ax0
    mov ebx, eax
    add ebx, 90
    mov ecx, ay0
    mov edx, ecx
    add edx, 4
    mov edi, COLOR_BORDER
    .IF esi < score
        mov edi, clrSeg
    .ENDIF
    invoke FillRc, hdc, eax, ecx, ebx, edx, edi
    inc esi
    cmp esi, 4
    jb strSeg

    ; word on the label row (right of "Password:")
    mov eax, curOffX
    add eax, 300
    mov ecx, curOffY
    add ecx, 196
    mov edx, eax
    add edx, 120
    mov ebx, ecx
    add ebx, 18
    invoke FillRc, hdc, eax, ecx, edx, ebx, COLOR_CANVAS
    .IF len > 0
        invoke DrawTxt, hdc, pWord, 300, 196, 420, 214, hFontBold, clrSeg, DT_RIGHT or DT_SINGLELINE or DT_NOPREFIX
    .ENDIF
    mov eax, 1
    ret
PaintStrength ENDP

; DrawBankCard: dark "vault card" showing the signed-in depositor (330 x 96)
DrawBankCard PROC USES ebx esi edi hdc:DWORD, cx1:DWORD, cy1:DWORD
    LOCAL x1:DWORD
    LOCAL y1:DWORD
    LOCAL idx:DWORD
    LOCAL clr:DWORD

    mov eax, cx1
    add eax, curOffX
    mov x1, eax
    mov eax, cy1
    add eax, curOffY
    mov y1, eax

    mov eax, x1
    add eax, 3
    mov ecx, y1
    add ecx, 3
    mov edx, eax
    add edx, 330
    mov ebx, ecx
    add ebx, 96
    invoke FillRc, hdc, eax, ecx, edx, ebx, COLOR_SHADOW

    mov idx, 0
cardBand:
    invoke LerpColor, COLOR_HEADER, COLOR_HEADER2, idx, 7
    mov clr, eax
    mov esi, idx
    imul esi, 12
    add esi, y1
    mov edi, esi
    add edi, 12
    mov ebx, x1
    add ebx, 330
    invoke FillRc, hdc, x1, esi, ebx, edi, clr
    inc idx
    cmp idx, 8
    jb cardBand

    mov ebx, x1
    add ebx, 330
    mov edi, y1
    add edi, 96
    invoke FrameRc, hdc, x1, y1, ebx, edi, COLOR_BRASS_DK
    mov eax, y1
    add eax, 3
    invoke FillRc, hdc, x1, y1, ebx, eax, COLOR_BRASS

    ; watermark wheel
    mov eax, x1
    add eax, 276
    mov ecx, y1
    add ecx, 52
    invoke DrawVaultWheel, hdc, eax, ecx, 34, COLOR_STEEL, COLOR_STEEL

    ; chip
    mov esi, x1
    add esi, 18
    mov edi, y1
    add edi, 26
    mov ebx, esi
    add ebx, 36
    mov eax, edi
    add eax, 24
    invoke FillRc, hdc, esi, edi, ebx, eax, COLOR_BRASS_LT
    mov eax, edi
    add eax, 11
    mov ecx, eax
    add ecx, 2
    invoke FillRc, hdc, esi, eax, ebx, ecx, COLOR_BRASS_DK
    mov eax, esi
    add eax, 17
    mov ecx, eax
    add ecx, 2
    mov edx, edi
    add edx, 24
    invoke FillRc, hdc, eax, edi, ecx, edx, COLOR_BRASS_DK

    mov eax, cx1
    add eax, 66
    mov ecx, cy1
    add ecx, 12
    mov edx, cx1
    add edx, 320
    mov ebx, cy1
    add ebx, 32
    invoke DrawTxt, hdc, offset szCardBrand, eax, ecx, edx, ebx, hFontBold, COLOR_BRASS_LT, DT_LEFT or DT_SINGLELINE or DT_NOPREFIX

    mov eax, cx1
    add eax, 18
    mov ecx, cy1
    add ecx, 54
    mov edx, cx1
    add edx, 320
    mov ebx, cy1
    add ebx, 80
    invoke DrawTxt, hdc, offset sessRecord, eax, ecx, edx, ebx, hFontHeader, COLOR_BRANDTXT, DT_LEFT or DT_SINGLELINE or DT_NOPREFIX

    mov eax, cx1
    add eax, 18
    mov ecx, cy1
    add ecx, 76
    mov edx, cx1
    add edx, 320
    mov ebx, cy1
    add ebx, 94
    invoke DrawTxt, hdc, offset sessRecord.FullName, eax, ecx, edx, ebx, hFontBody, COLOR_MIST, DT_LEFT or DT_SINGLELINE or DT_NOPREFIX
    mov eax, 1
    ret
DrawBankCard ENDP

; UiTick: 60 ms heartbeat - button hover tracking, header shimmer, vault-dial
;         rotation, blinking status lights
UiTick PROC USES ebx esi edi
    LOCAL pt:POINT
    LOCAL rc:RECT
    LOCAL cls[8]:BYTE
    LOCAL hdc:DWORD
    LOCAL pos:DWORD
    LOCAL span:DWORD
    LOCAL oldH:DWORD

    inc tickCnt

    ; ---- hover tracking (only for button-class children of the main window)
    invoke GetCursorPos, addr pt
    invoke WindowFromPoint, pt.x, pt.y
    mov esi, eax
    test esi, esi
    jz hoverResolved
    invoke GetParent, esi
    cmp eax, hMain
    jne hoverNone
    mov BYTE PTR cls, 0
    invoke GetClassNameA, esi, addr cls, 8
    movzx eax, BYTE PTR cls
    cmp eax, 'B'
    jne hoverNone
    invoke IsWindowVisible, esi
    test eax, eax
    jnz hoverResolved
hoverNone:
    xor esi, esi
hoverResolved:
    mov eax, hHoverCtl
    cmp esi, eax
    je hoverDone
    mov oldH, eax
    mov hHoverCtl, esi
    .IF oldH != 0
        invoke InvalidateRect, oldH, 0, 0
    .ENDIF
    .IF esi != 0
        invoke InvalidateRect, esi, 0, 0
    .ENDIF
hoverDone:

    invoke GetClientRect, hMain, addr rc

    ; ---- brass rule under the header with a travelling highlight
    invoke GetDC, hMain
    test eax, eax
    jz shimDone
    mov hdc, eax
    mov eax, HEADER_HEIGHT
    sub eax, 3
    invoke FillRc, hdc, 0, eax, rc.right, HEADER_HEIGHT, COLOR_BRASS
    mov eax, rc.right
    add eax, 240
    mov span, eax
    mov eax, tickCnt
    imul eax, 10
    xor edx, edx
    div span
    mov pos, edx
    mov esi, pos
    sub esi, 120
    .IF SDWORD PTR esi < 0
        xor esi, esi
    .ENDIF
    mov edi, pos
    .IF edi > rc.right
        mov edi, rc.right
    .ENDIF
    .IF edi > esi
        mov eax, HEADER_HEIGHT
        sub eax, 3
        invoke FillRc, hdc, esi, eax, edi, HEADER_HEIGHT, COLOR_BRASS_LT
    .ENDIF
    invoke ReleaseDC, hMain, hdc
shimDone:

    ; ---- every ~0.7 s: rotate the dial one notch, blink the lights
    ; ---- subtitle slide-in and balance count-up (every tick)
    .IF subSlide != 0
        mov eax, subSlide
        sub eax, 4
        .IF SDWORD PTR eax < 0
            xor eax, eax
        .ENDIF
        mov subSlide, eax
        mov rc.left, 80
        mov rc.top, 40
        mov rc.right, 760
        mov rc.bottom, 66
        invoke InvalidateRect, hMain, addr rc, 0
        invoke GetClientRect, hMain, addr rc
    .ENDIF
    .IF balAnim != 0 && curScreen == 3
        mov eax, balTarget
        xor edx, edx
        mov ecx, 14
        div ecx
        .IF eax == 0
            mov eax, 1
        .ENDIF
        add eax, balCur
        .IF eax >= balTarget
            mov eax, balTarget
            mov balAnim, 0
        .ENDIF
        mov balCur, eax
        invoke ShowBalCur
    .ENDIF

    mov eax, tickCnt
    xor edx, edx
    mov ecx, 24
    div ecx
    test edx, edx
    jnz tickEnd
    mov eax, wheelPhase
    inc eax
    xor edx, edx
    mov ecx, 12
    div ecx
    mov wheelPhase, edx
    xor blinkOn, 1

    mov eax, HEADER_HEIGHT
    sub eax, 3
    mov rc.top, 0
    mov ebx, rc.right
    mov edi, rc.bottom
    mov rc.bottom, eax
    invoke InvalidateRect, hMain, addr rc, 0
    mov rc.bottom, edi
    mov rc.right, ebx
    ; footer strip
    mov eax, rc.bottom
    sub eax, 26
    mov rc.top, eax
    invoke InvalidateRect, hMain, addr rc, 0
    ; login side panel dial
    .IF curScreen == 1
        mov eax, 764
        add eax, curOffX
        mov rc.left, eax
        add eax, 176
        mov rc.right, eax
        mov eax, 122
        add eax, curOffY
        mov rc.top, eax
        add eax, 118
        mov rc.bottom, eax
        invoke InvalidateRect, hMain, addr rc, 0
    .ENDIF
tickEnd:
    mov eax, 1
    ret
UiTick ENDP


; ApplyDarkTitle: dark caption bar on Windows 10/11 (silently skipped if unavailable)
ApplyDarkTitle PROC USES ebx esi edi hwndT:DWORD
    LOCAL useDark:DWORD
    mov useDark, 1
    invoke LoadLibraryA, offset szDwmDll
    test eax, eax
    jz darkTitleEnd
    mov esi, eax
    invoke GetProcAddress, esi, offset szDwmFn
    test eax, eax
    jz darkTitleEnd
    lea ecx, useDark
    push 4
    push ecx
    push 20                         ; DWMWA_USE_IMMERSIVE_DARK_MODE
    push hwndT
    call eax
darkTitleEnd:
    mov eax, 1
    ret
ApplyDarkTitle ENDP


; ShowBalCur: writes "PKR <balCur>" into the dashboard balance label
ShowBalCur PROC USES ebx esi edi
    LOCAL szD[16]:BYTE
    LOCAL szF[48]:BYTE
    invoke ItoaDec, balCur, addr szD
    invoke lstrcpyA, addr szF, offset szCurrencyPrefix
    invoke lstrcatA, addr szF, addr szD
    invoke SetWindowTextA, hDepInfoBal, addr szF
    mov eax, 1
    ret
ShowBalCur ENDP

; StartBalAnim: begin the 0 -> balance count-up after login / refresh
StartBalAnim PROC
    mov eax, sessRecord.Balance
    mov balTarget, eax
    mov balCur, 0
    .IF eax != 0
        mov balAnim, 1
        invoke ShowBalCur
    .ELSE
        mov balAnim, 0
    .ENDIF
    mov eax, 1
    ret
StartBalAnim ENDP


; NotifyDepositor: after login, tell the depositor about requests the cashier has
;   decided since the last visit (approved / declined, then the amount). Each
;   request is announced once (Reserved field of the record is set to 1).
NotifyDepositor PROC USES ebx esi edi hwndP:DWORD
    LOCAL count:DWORD
    LOCAL pBuf:DWORD
    LOCAL cbAlloc:DWORD
    LOCAL pReq:DWORD
    LOCAL idx:DWORD
    LOCAL szMsg[160]:BYTE
    LOCAL szDig[16]:BYTE
    LOCAL hF:DWORD
    LOCAL nWritten:DWORD
    LOCAL one:DWORD

    mov one, 1
    invoke ReqCount
    test eax, eax
    jle ntfEnd
    mov count, eax
    mov ecx, REQ_REC_SIZE
    mul ecx
    mov cbAlloc, eax
    invoke GetProcessHeap
    invoke HeapAlloc, eax, HEAP_ZERO_MEMORY, cbAlloc
    test eax, eax
    jz ntfEnd
    mov pBuf, eax
    invoke ReqReadAll, pBuf, addr count
    test eax, eax
    jnz ntfFree

    mov idx, 0
ntfLoop:
    mov eax, idx
    cmp eax, count
    jae ntfFree
    mov ecx, REQ_REC_SIZE
    mul ecx
    add eax, pBuf
    mov pReq, eax
    mov esi, eax
    assume esi:PTR REQUEST_RECORD
    cmp [esi].Status, REQ_STATUS_PENDING
    je ntfNext
    cmp [esi].Reserved, 0
    jne ntfNext
    invoke lstrcmpiA, esi, offset sessUser
    test eax, eax
    jnz ntfNext

    ; message 1: approved / declined
    invoke lstrcpyA, addr szMsg, offset szNtfA
    mov esi, pReq
    .IF [esi].RequestType == REQ_TYPE_DEPOSIT
        invoke lstrcatA, addr szMsg, offset szWordDeposit
    .ELSE
        invoke lstrcatA, addr szMsg, offset szWordWithdraw
    .ENDIF
    invoke lstrcatA, addr szMsg, offset szNtfB
    mov ecx, idx
    inc ecx
    invoke ItoaDec, ecx, addr szDig
    invoke lstrcatA, addr szMsg, addr szDig
    mov esi, pReq
    .IF [esi].Status == REQ_STATUS_APPROVED
        invoke lstrcatA, addr szMsg, offset szNtfApprEnd
    .ELSE
        invoke lstrcatA, addr szMsg, offset szNtfDeclEnd
    .ENDIF
    invoke ThemedMsgBox, hwndP, addr szMsg, offset szNtfTitle, MB_OK or MB_ICONINFORMATION

    ; message 2: the amount (approved requests only)
    mov esi, pReq
    .IF [esi].Status == REQ_STATUS_APPROVED
        invoke ItoaDec, [esi].Amount, addr szDig
        invoke lstrcpyA, addr szMsg, offset szCurrencyPrefix
        invoke lstrcatA, addr szMsg, addr szDig
        mov esi, pReq
        .IF [esi].RequestType == REQ_TYPE_DEPOSIT
            invoke lstrcatA, addr szMsg, offset szNtfDepEnd
        .ELSE
            invoke lstrcatA, addr szMsg, offset szNtfWdrEnd
        .ENDIF
        invoke ThemedMsgBox, hwndP, addr szMsg, offset szNtfAmtTitle, MB_OK or MB_ICONINFORMATION
    .ENDIF

    ; mark as announced (Reserved at record offset +3Ch)
    invoke CreateFileA, offset szRequestsFile, GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
    .IF eax != INVALID_HANDLE_VALUE
        mov hF, eax
        mov eax, idx
        mov ecx, REQ_REC_SIZE
        mul ecx
        add eax, 3Ch
        invoke SetFilePointer, hF, eax, 0, FILE_BEGIN
        invoke WriteFile, hF, addr one, 4, addr nWritten, 0
        invoke CloseHandle, hF
    .ENDIF
ntfNext:
    assume esi:NOTHING
    inc idx
    jmp ntfLoop
ntfFree:
    invoke GetProcessHeap
    invoke HeapFree, eax, 0, pBuf
ntfEnd:
    mov eax, 1
    ret
NotifyDepositor ENDP

; FormatRegField: live input mask. kind 1 = CNIC (ddddd-ddddddd-d), kind 2 = phone
;   (digits only, at most 11). A dash is auto-inserted after the 5th and 12th digit
;   while typing, but never fights Backspace.
FormatRegField PROC USES ebx esi edi hEdit:DWORD, kind:DWORD
    LOCAL szSrc[80]:BYTE
    LOCAL szDst[32]:BYTE
    LOCAL nDig:DWORD
    LOCAL maxDig:DWORD
    LOCAL rawLen:DWORD
    LOCAL fmtLen:DWORD
    LOCAL prevLen:DWORD

    mov BYTE PTR szSrc, 0
    invoke GetWindowTextA, hEdit, addr szSrc, 79
    mov rawLen, eax
    mov maxDig, 13
    mov eax, lastLenCnic
    .IF kind == 2
        mov maxDig, 11
        mov eax, lastLenPhone
    .ENDIF
    mov prevLen, eax

    lea esi, szSrc
    lea edi, szDst
    mov nDig, 0
fmtNext:
    movzx eax, BYTE PTR [esi]
    test eax, eax
    jz fmtDone
    inc esi
    cmp al, '0'
    jb fmtNext
    cmp al, '9'
    ja fmtNext
    mov ecx, nDig
    cmp ecx, maxDig
    jae fmtNext
    mov [edi], al
    inc edi
    inc nDig
    .IF kind == 1
        mov ecx, nDig
        .IF (ecx == 5 || ecx == 12) && ecx < 13
            ; trailing dash only while typing forward (not when deleting)
            movzx edx, BYTE PTR [esi]
            mov ecx, rawLen
            .IF edx != 0 || ecx > prevLen
                mov BYTE PTR [edi], '-'
                inc edi
            .ENDIF
        .ENDIF
    .ENDIF
    jmp fmtNext
fmtDone:
    mov BYTE PTR [edi], 0
    invoke lstrlenA, addr szDst
    mov fmtLen, eax
    .IF kind == 2
        mov eax, fmtLen
        mov lastLenPhone, eax
    .ELSE
        mov eax, fmtLen
        mov lastLenCnic, eax
    .ENDIF
    mov eax, rawLen
    .IF eax != fmtLen
        invoke SetWindowTextA, hEdit, addr szDst
        invoke SendMessageA, hEdit, 0B1h, fmtLen, fmtLen     ; EM_SETSEL: caret to end
    .ELSE
        invoke lstrcmpA, addr szSrc, addr szDst
        .IF eax != 0
            invoke SetWindowTextA, hEdit, addr szDst
            invoke SendMessageA, hEdit, 0B1h, fmtLen, fmtLen
        .ENDIF
    .ENDIF
    mov eax, 1
    ret
FormatRegField ENDP

END
