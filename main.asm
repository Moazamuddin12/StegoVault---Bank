; ==============================================================================
; main.asm — Main Entry Point, Window Class & Event Loop for StegoVault Bank
; ==============================================================================
.586
.model flat, stdcall
option casemap:none

include constants.inc
include structs.inc
include protos.inc

PUBLIC start
PUBLIC WndProc
PUBLIC ShowScreen
PUBLIC hInst
PUBLIC hMain
PUBLIC curScreen
PUBLIC curRole
PUBLIC curOffX
PUBLIC curOffY

.data
szClassName         BYTE "StegoVaultWnd", 0
szTitle             BYTE "StegoVault Bank", 0

szSubLogin          BYTE "Secure Login: enter your credentials and select your vault image", 0
szSubRegister       BYTE "New Depositor Registration: create your personal encrypted vault image", 0
szSubDepositor      BYTE "Depositor Dashboard: account overview and transaction requests", 0
szSubCashier        BYTE "Cashier Control Center: review requests and audit depositor vaults", 0
szErrInitStorage    BYTE "Failed to initialize application storage repositories.", 0

.data?
hInst               DWORD ?
minWinW             DWORD ?   ; minimum outer window width  (fits 960 x 640 client)
minWinH             DWORD ?   ; minimum outer window height
curOffX             DWORD ?   ; current horizontal content offset (centering)
curOffY             DWORD ?   ; current vertical content offset
moveDeltaX          DWORD ?   ; scratch: X delta passed to EnumMoveProc (must precede moveDeltaY)
moveDeltaY          DWORD ?   ; scratch: Y delta
hMain               DWORD ?
curScreen           DWORD ?
curRole             DWORD ?

.code

; ------------------------------------------------------------------------------
; ShowScreen: Activates screen n and hides other screens
; Inputs:  n (DWORD, SCREEN_*)
; Outputs: EAX = SV_OK
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
ShowScreen PROC USES ebx esi edi n:DWORD
    LOCAL dwCmd:DWORD
    LOCAL idx:DWORD

    mov eax, n
    mov curScreen, eax
    mov subSlide, 44                    ; header subtitle slides in

    ; --- Screen 1 ---
    .IF n == 1
        ; Show common controls
        xor ecx, ecx
loopS1Common:
        cmp ecx, nControlsScreen1
        jge doneS1Common
        mov idx, ecx
        mov edx, [hControlsScreen1 + ecx*4]
        invoke ShowWindow, edx, SW_SHOW
        mov ecx, idx
        inc ecx
        jmp loopS1Common
doneS1Common:
        invoke SwitchLoginTab, curRole
    .ELSE
        ; Hide common controls
        xor ecx, ecx
loopS1Hide:
        cmp ecx, nControlsScreen1
        jge doneS1Hide
        mov idx, ecx
        mov edx, [hControlsScreen1 + ecx*4]
        invoke ShowWindow, edx, SW_HIDE
        mov ecx, idx
        inc ecx
        jmp loopS1Hide
doneS1Hide:
        ; Hide depositor controls
        xor ecx, ecx
loopS1DepHide:
        cmp ecx, nControlsScreen1Dep
        jge doneS1DepHide
        mov idx, ecx
        mov edx, [hControlsScreen1Dep + ecx*4]
        invoke ShowWindow, edx, SW_HIDE
        mov ecx, idx
        inc ecx
        jmp loopS1DepHide
doneS1DepHide:
        ; Hide cashier controls
        xor ecx, ecx
loopS1CshHide:
        cmp ecx, nControlsScreen1Csh
        jge doneS1CshHide
        mov idx, ecx
        mov edx, [hControlsScreen1Csh + ecx*4]
        invoke ShowWindow, edx, SW_HIDE
        mov ecx, idx
        inc ecx
        jmp loopS1CshHide
doneS1CshHide:
    .ENDIF

    ; --- Screen 2 ---
    mov dwCmd, SW_HIDE
    .IF n == 2
        mov dwCmd, SW_SHOW
    .ENDIF
    xor ecx, ecx
loopS2:
    cmp ecx, nControlsScreen2
    jge doneS2
    mov idx, ecx
    mov edx, [hControlsScreen2 + ecx*4]
    invoke ShowWindow, edx, dwCmd
    mov ecx, idx
    inc ecx
    jmp loopS2
doneS2:

    ; --- Screen 3 ---
    mov dwCmd, SW_HIDE
    .IF n == 3
        mov dwCmd, SW_SHOW
    .ENDIF
    xor ecx, ecx
loopS3:
    cmp ecx, nControlsScreen3
    jge doneS3
    mov idx, ecx
    mov edx, [hControlsScreen3 + ecx*4]
    invoke ShowWindow, edx, dwCmd
    mov ecx, idx
    inc ecx
    jmp loopS3
doneS3:

    ; --- Screen 4 ---
    mov dwCmd, SW_HIDE
    .IF n == 4
        mov dwCmd, SW_SHOW
    .ENDIF
    xor ecx, ecx
loopS4:
    cmp ecx, nControlsScreen4
    jge doneS4
    mov idx, ecx
    mov edx, [hControlsScreen4 + ecx*4]
    invoke ShowWindow, edx, dwCmd
    mov ecx, idx
    inc ecx
    jmp loopS4
doneS4:

    .IF n == 4
        invoke SetCashierMode, cshMode
    .ENDIF
    invoke RedrawWindow, hMain, 0, 0, RDW_FULL_REPAINT
    mov eax, SV_OK
    ret
ShowScreen ENDP

; ------------------------------------------------------------------------------
; EnumMoveProc: EnumChildWindows callback; shifts one child by (moveDeltaX, moveDeltaY)
; Inputs:  hChild (DWORD), lParam = pointer to two DWORDs: deltaX, deltaY
; Outputs: EAX = 1 (continue enumeration)
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
EnumMoveProc PROC USES ebx esi edi hChild:DWORD, lParam:DWORD
    LOCAL rcChild:RECT
    LOCAL ptChild:POINT

    invoke GetWindowRect, hChild, addr rcChild
    test eax, eax
    jz enumDone
    mov eax, rcChild.left
    mov ptChild.x, eax
    mov eax, rcChild.top
    mov ptChild.y, eax
    invoke ScreenToClient, hMain, addr ptChild
    mov edx, lParam
    mov eax, ptChild.x
    add eax, [edx]
    mov ecx, ptChild.y
    add ecx, [edx + 4]
    invoke SetWindowPos, hChild, 0, eax, ecx, 0, 0, SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE
enumDone:
    mov eax, 1
    ret
EnumMoveProc ENDP

; ------------------------------------------------------------------------------
; WndProc: Main window message processor
; Inputs:  hwnd (DWORD), uMsg (DWORD), wParam (DWORD), lParam (DWORD)
; Outputs: LRESULT (EAX)
; Preserved: EBX, ESI, EDI, EBP
; Clobbered: EAX, ECX, EDX
; ------------------------------------------------------------------------------
WndProc PROC USES ebx esi edi hwnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
    LOCAL ps:PAINTSTRUCT
    LOCAL rcBody:RECT
    LOCAL hMemDC:DWORD
    LOCAL hMemBmp:DWORD
    LOCAL hMemOld:DWORD
    LOCAL pSubtitle:DWORD
    LOCAL rcClient:RECT

    .IF uMsg == WM_CREATE
        mov eax, hwnd
        mov hMain, eax
        invoke InitGuiResources
        invoke BuildScreens, hwnd
        invoke ShowScreen, 1
        xor eax, eax
        ret

    .ELSEIF uMsg == WM_GETMINMAXINFO
        mov edx, lParam
        mov eax, minWinW
        mov [edx + MMI_MINTRACK_X], eax
        mov eax, minWinH
        mov [edx + MMI_MINTRACK_Y], eax
        xor eax, eax
        ret

    .ELSEIF uMsg == WM_SIZE
        .IF wParam != SIZE_MINIMIZED
            ; Centre the fixed 960 x 640 content block inside the client area
            mov eax, lParam
            movzx ecx, ax                   ; new client width
            shr eax, 16                     ; new client height
            xor edx, edx
            sub ecx, WIN_WIDTH
            jle zeroOffX
            shr ecx, 1
            mov edx, ecx
zeroOffX:
            mov esi, edx                    ; new X offset
            xor edx, edx
            sub eax, WIN_HEIGHT
            jle zeroOffY
            shr eax, 1
            mov edx, eax
zeroOffY:
            mov edi, edx                    ; new Y offset
            mov eax, esi
            sub eax, curOffX
            mov moveDeltaX, eax
            mov eax, edi
            sub eax, curOffY
            mov moveDeltaY, eax
            mov curOffX, esi
            mov curOffY, edi
            mov eax, moveDeltaX
            or eax, moveDeltaY
            .IF eax != 0
                invoke EnumChildWindows, hwnd, offset EnumMoveProc, offset moveDeltaX
            .ENDIF
            invoke RedrawWindow, hwnd, 0, 0, RDW_FULL_REPAINT
        .ENDIF
        xor eax, eax
        ret

    .ELSEIF uMsg == WM_ERASEBKGND
        mov eax, 1                          ; WM_PAINT repaints everything
        ret

    .ELSEIF uMsg == WM_TIMER
        invoke UiTick
        xor eax, eax
        ret

    .ELSEIF uMsg == WM_COMMAND
        mov eax, wParam
        movzx edx, ax       ; Control ID in EDX
        shr eax, 16         ; Notification code in EAX
        .IF edx == IDC_REG_CNIC_TXT && eax == 0300h
            invoke FormatRegField, lParam, 1
            xor eax, eax
            ret
        .ELSEIF edx == IDC_REG_PHONE_TXT && eax == 0300h
            invoke FormatRegField, lParam, 2
            xor eax, eax
            ret
        .ENDIF
        .IF edx == IDC_REG_PASS_TXT && eax == 0300h        ; EN_CHANGE: live strength meter
            invoke GetDC, hwnd
            mov esi, eax
            invoke PaintStrength, esi
            invoke ReleaseDC, hwnd, esi
            xor eax, eax
            ret
        .ENDIF
        .IF edx == IDC_LOGIN_TAB_DEP
            invoke SwitchLoginTab, ROLE_DEPOSITOR
        .ELSEIF edx == IDC_LOGIN_TAB_CSH
            invoke SwitchLoginTab, ROLE_CASHIER
        .ELSEIF edx == IDC_LOGIN_DEP_BROWSE
            invoke BrowseLoginImage, hwnd, hEditDepImg
        .ELSEIF edx == IDC_LOGIN_DEP_SUBMIT
            invoke DoDepositorLogin, hwnd
        .ELSEIF edx == IDC_LOGIN_DEP_GOTO_REG
            invoke ShowScreen, SCREEN_REGISTER
        .ELSEIF edx == IDC_LOGIN_CSH_SUBMIT
            invoke DoCashierLogin, hwnd
        .ELSEIF edx == IDC_LOGIN_CSH_CREATE
            invoke DoCashierCreate, hwnd
        .ELSEIF edx == IDC_REG_BROWSE
            invoke BrowseCoverImage, hwnd, hEditRegCover
        .ELSEIF edx == IDC_REG_SUBMIT
            invoke LoadCursorA, 0, IDC_WAIT
            invoke SetCursor, eax
            invoke DoRegister, hwnd
            invoke LoadCursorA, 0, IDC_ARROW
            invoke SetCursor, eax
        .ELSEIF edx == IDC_REG_BACK
            invoke ShowScreen, SCREEN_LOGIN
        .ELSEIF edx == IDC_DEP_REFRESH_BTN
            invoke DoRefreshBalance
        .ELSEIF edx == IDC_DEP_LOGOUT_BTN
            invoke DoLogout
        .ELSEIF edx == IDC_DEP_TXN_SUBMIT_BTN
            invoke DoSubmitRequest, hwnd
        .ELSEIF edx == IDC_CSH_APPROVE_BTN
            invoke DoCashierApprove, hwnd
        .ELSEIF edx == IDC_CSH_REJECT_BTN
            invoke DoCashierReject, hwnd
        .ELSEIF edx == IDC_CSH_APPLY_BTN
            invoke DoCashierManualAdjust, hwnd
        .ELSEIF edx == IDC_CSH_LOGOUT_BTN
            invoke DoCashierLogout
        .ELSEIF edx == IDC_CSH_OPEN_IMG_BTN
            invoke BrowseCashierImage, hwnd
        .ELSEIF edx == IDC_CSH_DEP_LIST
            .IF eax == LBN_SELCHANGE
                invoke OnCashierDepListSelChange, hwnd
            .ENDIF
        .ELSEIF edx == IDC_CSH_REQ_LIST
            .IF eax == LBN_SELCHANGE
                invoke OnCashierReqListSelChange, hwnd
            .ENDIF
        .ENDIF
        xor eax, eax
        ret

    .ELSEIF uMsg == WM_PAINT
        invoke BeginPaint, hwnd, addr ps
        invoke GetClientRect, hwnd, addr rcClient

        ; Double buffer only the invalidated rectangle (small = fast, no flicker)
        mov esi, ps.rcPaint.right
        sub esi, ps.rcPaint.left
        mov edi, ps.rcPaint.bottom
        sub edi, ps.rcPaint.top
        .IF SDWORD PTR esi <= 0 || SDWORD PTR edi <= 0
            invoke EndPaint, hwnd, addr ps
            xor eax, eax
            ret
        .ENDIF
        invoke CreateCompatibleDC, ps.hdc
        mov hMemDC, eax
        invoke CreateCompatibleBitmap, ps.hdc, esi, edi
        mov hMemBmp, eax
        invoke SelectObject, hMemDC, hMemBmp
        mov hMemOld, eax
        mov eax, ps.rcPaint.left
        neg eax
        mov ecx, ps.rcPaint.top
        neg ecx
        invoke SetViewportOrgEx, hMemDC, eax, ecx, 0

        ; Subtitle determination
        mov eax, curScreen
        .IF eax == 2
            mov pSubtitle, offset szSubRegister
        .ELSEIF eax == 3
            mov pSubtitle, offset szSubDepositor
        .ELSEIF eax == 4
            mov pSubtitle, offset szSubCashier
        .ELSE
            mov pSubtitle, offset szSubLogin
        .ENDIF

        ; Canvas body background
        mov rcBody.left, 0
        mov rcBody.top, HEADER_HEIGHT
        mov eax, rcClient.right
        mov rcBody.right, eax
        mov eax, rcClient.bottom
        mov rcBody.bottom, eax
        invoke FillRect, hMemDC, addr rcBody, hbrCanvas

        ; Vault-themed cards / panels, then header band with emblem
        invoke PaintCards, hMemDC
        invoke PaintHeader, hMemDC, rcClient.right, pSubtitle
        invoke PaintFooter, hMemDC, rcClient.right, rcClient.bottom

        mov esi, ps.rcPaint.right
        sub esi, ps.rcPaint.left
        mov edi, ps.rcPaint.bottom
        sub edi, ps.rcPaint.top
        invoke BitBlt, ps.hdc, ps.rcPaint.left, ps.rcPaint.top, esi, edi, hMemDC, 0, 0, SRCCOPY
        invoke SelectObject, hMemDC, hMemOld
        invoke DeleteObject, hMemBmp
        invoke DeleteDC, hMemDC

        invoke EndPaint, hwnd, addr ps
        xor eax, eax
        ret

    .ELSEIF uMsg == WM_CTLCOLORSTATIC
        mov eax, lParam
        .IF eax == hStatusScreen1
            mov edx, statusErrScreen1
            .IF edx == 1
                invoke SetTextColor, wParam, COLOR_ERROR
            .ELSE
                invoke SetTextColor, wParam, COLOR_SUCCESS
            .ENDIF
        .ELSEIF eax == hStatusScreen2
            mov edx, statusErrScreen2
            .IF edx == 1
                invoke SetTextColor, wParam, COLOR_ERROR
            .ELSE
                invoke SetTextColor, wParam, COLOR_SUCCESS
            .ENDIF
        .ELSEIF eax == hStatusScreen3
            mov edx, statusErrScreen3
            .IF edx == 1
                invoke SetTextColor, wParam, COLOR_ERROR
            .ELSE
                invoke SetTextColor, wParam, COLOR_SUCCESS
            .ENDIF
        .ELSEIF eax == hStatusScreen4
            mov edx, statusErrScreen4
            .IF edx == 1
                invoke SetTextColor, wParam, COLOR_ERROR
            .ELSE
                invoke SetTextColor, wParam, COLOR_SUCCESS
            .ENDIF
        .ELSE
            invoke GetCtlTextColor, lParam
            invoke SetTextColor, wParam, eax
        .ENDIF

        invoke SetBkMode, wParam, TRANSPARENT
        mov eax, hbrCanvas
        ret

    .ELSEIF uMsg == WM_CTLCOLOREDIT
        invoke SetBkColor, wParam, COLOR_INPUT
        invoke SetTextColor, wParam, COLOR_TEXT
        mov eax, hbrInput
        ret

    .ELSEIF uMsg == WM_MEASUREITEM
        mov edx, lParam
        mov DWORD PTR [edx + 16], 24        ; MEASUREITEMSTRUCT.itemHeight
        mov eax, 1
        ret

    .ELSEIF uMsg == WM_DRAWITEM
        invoke DrawOwnerItem, hwnd, lParam
        mov eax, 1
        ret

    .ELSEIF uMsg == WM_DESTROY
        invoke FreeGuiResources
        invoke ShutdownGdiplus
        invoke PostQuitMessage, 0
        xor eax, eax
        ret
    .ENDIF

    invoke DefWindowProcA, hwnd, uMsg, wParam, lParam
    ret
WndProc ENDP

; ------------------------------------------------------------------------------
; start: Application entry point
; ------------------------------------------------------------------------------
start PROC C
    LOCAL wc:WNDCLASSEX
    LOCAL msg:MSG
    LOCAL rc:RECT
    LOCAL dwStyle:DWORD
    LOCAL winW:DWORD
    LOCAL winH:DWORD

    invoke GetModuleHandleA, 0
    mov hInst, eax

    ; Initialize persistent storage
    invoke InitStorage
    .IF eax != SV_OK
        invoke MessageBoxA, 0, offset szErrInitStorage, offset szTitle, MB_ICONERROR or MB_OK
        invoke ExitProcess, 1
    .ENDIF

    ; Setup WNDCLASSEX
    mov wc.cbSize, sizeof WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, offset WndProc
    mov wc.cbClsExtra, 0
    mov wc.cbWndExtra, 0
    mov eax, hInst
    mov wc.hInstance, eax
    invoke LoadIconA, 0, IDI_APPLICATION
    mov wc.hIcon, eax
    mov wc.hIconSm, eax
    invoke LoadCursorA, 0, IDC_ARROW
    mov wc.hCursor, eax
    invoke CreateSolidBrush, COLOR_CANVAS
    mov wc.hbrBackground, eax
    mov wc.lpszMenuName, 0
    mov wc.lpszClassName, offset szClassName

    invoke RegisterClassExA, addr wc
    test eax, eax
    jz appExit

    ; Black animated intro before the main window appears
    invoke RunSplash

    ; Calculate exact window rect for 960 x 640 client area
    mov rc.left, 0
    mov rc.top, 0
    mov rc.right, WIN_WIDTH
    mov rc.bottom, WIN_HEIGHT

    ; Resizable window: caption, system menu, min/max boxes, sizing frame
    ; (double-clicking the title bar maximises / restores it)
    mov dwStyle, WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX or WS_MAXIMIZEBOX or WS_THICKFRAME
    invoke AdjustWindowRectEx, addr rc, dwStyle, 0, 0

    mov eax, rc.right
    sub eax, rc.left
    mov winW, eax

    mov eax, rc.bottom
    sub eax, rc.top
    mov winH, eax
    mov eax, winW
    mov minWinW, eax
    mov eax, winH
    mov minWinH, eax

    mov curRole, ROLE_DEPOSITOR

    ; Create top-level window
    invoke CreateWindowExA, 0, offset szClassName, offset szTitle, dwStyle,
           CW_USEDEFAULT, CW_USEDEFAULT, winW, winH, 0, 0, hInst, 0
    mov hMain, eax
    test eax, eax
    jz appExit

    invoke ShowWindow, hMain, SW_SHOWMAXIMIZED
    invoke SetTimer, hMain, 2, 30, 0
    invoke UpdateWindow, hMain

    ; Message loop
msgLoop:
    invoke GetMessageA, addr msg, 0, 0, 0
    test eax, eax
    jz exitLoop
    cmp eax, -1
    je exitLoop

    invoke TranslateMessage, addr msg
    invoke DispatchMessageA, addr msg
    jmp msgLoop

exitLoop:
    invoke ExitProcess, msg.wParam
    ret

appExit:
    invoke ExitProcess, 1
    ret
start ENDP

END
