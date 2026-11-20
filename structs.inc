; ==============================================================================
; structs.inc — StegoVault Bank Structure Definitions
; ==============================================================================

; --- Domain Structures (SPEC section 4) ---

VAULT_HEADER STRUCT
    Magic               DWORD   ?   ; +0x00: "SVLT" (0x544C5653)
    UserWrappedDEK      BYTE    32 DUP (?) ; +0x04: DEK XOR KEK_user
    CashierWrappedDEK   BYTE    32 DUP (?) ; +0x24: DEK XOR KEK_cashier
    Checksum            DWORD   ?   ; +0x44: Fnv32(record) XOR DEK[0..3]
    UsernameHash        BYTE    32 DUP (?) ; +0x48: SvHash256(lowercase username)
    Nonce               DWORD   ?   ; +0x68: starts at 1, +1 per rewrite
VAULT_HEADER ENDS ; Size = 108 bytes

ACCOUNT_RECORD STRUCT
    AccountNumber       BYTE    16 DUP (?) ; +0x00: e.g. "ACC-1001\0"
    FullName            BYTE    64 DUP (?) ; +0x10: Full name
    Username            BYTE    32 DUP (?) ; +0x50: As typed at registration
    CNIC                BYTE    16 DUP (?) ; +0x70: e.g. "42101-1234567-1\0"
    Contact             BYTE    16 DUP (?) ; +0x80: Contact phone
    Balance             DWORD   ?          ; +0x90: Account balance (whole units)
ACCOUNT_RECORD ENDS ; Size = 148 bytes

USER_RECORD STRUCT
    Username            BYTE    32 DUP (?) ; +0x00: lowercase, NUL-padded
    Salt                BYTE    16 DUP (?) ; +0x20: random salt
    Verifier            BYTE    32 DUP (?) ; +0x30: SvHash256("AUTH"||Salt||Pass)
    LastNonce           DWORD   ?          ; +0x50: Last observed Nonce
    Reserved            BYTE    12 DUP (?) ; +0x54: zero
USER_RECORD ENDS ; Size = 96 bytes

REQUEST_RECORD STRUCT
    Username            BYTE    32 DUP (?) ; +0x00: lowercase
    AccountNumber       BYTE    16 DUP (?) ; +0x20: Account number
    RequestType         DWORD   ?          ; +0x30: 1=Deposit, 2=Withdraw
    Amount              DWORD   ?          ; +0x34: Amount requested
    Status              DWORD   ?          ; +0x38: 0=Pending, 1=Approved, 2=Rejected
    Reserved            DWORD   ?          ; +0x3C: Reserved
REQUEST_RECORD ENDS ; Size = 64 bytes

; --- Win32 & GDI Structures ---

POINT STRUCT
    x                   DWORD   ?
    y                   DWORD   ?
POINT ENDS

RECT STRUCT
    left                DWORD   ?
    top                 DWORD   ?
    right               DWORD   ?
    bottom              DWORD   ?
RECT ENDS

PAINTSTRUCT STRUCT
    hdc                 DWORD   ?
    fErase              DWORD   ?
    rcPaint             RECT    <>
    fRestore            DWORD   ?
    fIncUpdate          DWORD   ?
    rgbReserved         BYTE    32 DUP (?)
PAINTSTRUCT ENDS

MSG STRUCT
    hwnd                DWORD   ?
    message             DWORD   ?
    wParam              DWORD   ?
    lParam              DWORD   ?
    time                DWORD   ?
    pt                  POINT   <>
MSG ENDS

WNDCLASSEX STRUCT
    cbSize              DWORD   ?
    style               DWORD   ?
    lpfnWndProc         DWORD   ?
    cbClsExtra          DWORD   ?
    cbWndExtra          DWORD   ?
    hInstance           DWORD   ?
    hIcon               DWORD   ?
    hCursor             DWORD   ?
    hbrBackground       DWORD   ?
    lpszMenuName        DWORD   ?
    lpszClassName       DWORD   ?
    hIconSm             DWORD   ?
WNDCLASSEX ENDS

DRAWITEMSTRUCT STRUCT
    CtlType             DWORD   ?
    CtlID               DWORD   ?
    itemID              DWORD   ?
    itemAction          DWORD   ?
    itemState           DWORD   ?
    hwndItem            DWORD   ?
    hDC                 DWORD   ?
    rcItem              RECT    <>
    itemData            DWORD   ?
DRAWITEMSTRUCT ENDS

OPENFILENAMEA STRUCT
    lStructSize         DWORD   ?
    hwndOwner           DWORD   ?
    hInstance           DWORD   ?
    lpstrFilter         DWORD   ?
    lpstrCustomFilter   DWORD   ?
    nMaxCustFilter      DWORD   ?
    nFilterIndex        DWORD   ?
    lpstrFile           DWORD   ?
    nMaxFile            DWORD   ?
    lpstrFileTitle      DWORD   ?
    nMaxFileTitle       DWORD   ?
    lpstrInitialDir     DWORD   ?
    lpstrTitle          DWORD   ?
    Flags               DWORD   ?
    nFileOffset         WORD    ?
    nFileExtension      WORD    ?
    lpstrDefExt         DWORD   ?
    lCustData           DWORD   ?
    lpfnHook            DWORD   ?
    lpTemplateName      DWORD   ?
    pvReserved          DWORD   ?
    dwReserved          DWORD   ?
    FlagsEx             DWORD   ?
OPENFILENAMEA ENDS

FILETIME STRUCT
    dwLowDateTime       DWORD   ?
    dwHighDateTime      DWORD   ?
FILETIME ENDS

WIN32_FIND_DATAA STRUCT
    dwFileAttributes    DWORD   ?
    ftCreationTime      FILETIME <>
    ftLastAccessTime    FILETIME <>
    ftLastWriteTime     FILETIME <>
    nFileSizeHigh       DWORD   ?
    nFileSizeLow        DWORD   ?
    dwReserved0         DWORD   ?
    dwReserved1         DWORD   ?
    cFileName           BYTE    260 DUP (?)
    cAlternateFileName  BYTE    14 DUP (?)
    dwFileType          DWORD   ?
    dwCreatorType       DWORD   ?
    wFinderFlags        WORD    ?
WIN32_FIND_DATAA ENDS

BITMAPFILEHEADER STRUCT
    bfType              WORD    ?   ; 'BM' = 4D42h
    bfSize              DWORD   ?
    bfReserved1         WORD    ?
    bfReserved2         WORD    ?
    bfOffBits           DWORD   ?
BITMAPFILEHEADER ENDS

BITMAPINFOHEADER STRUCT
    biSize              DWORD   ?   ; 40
    biWidth             DWORD   ?
    biHeight            DWORD   ?
    biPlanes            WORD    ?   ; 1
    biBitCount          WORD    ?   ; 24
    biCompression       DWORD   ?   ; 0 (BI_RGB)
    biSizeImage         DWORD   ?
    biXPelsPerMeter     DWORD   ?
    biYPelsPerMeter     DWORD   ?
    biClrUsed           DWORD   ?
    biClrImportant      DWORD   ?
BITMAPINFOHEADER ENDS

GdiplusStartupInput STRUCT
    GdiplusVersion          DWORD   ?
    DebugEventCallback      DWORD   ?
    SuppressBackgroundThread DWORD   ?
    SuppressExternalCodecs   DWORD   ?
GdiplusStartupInput ENDS

BitmapData STRUCT
    bmWidth             DWORD   ?
    bmHeight            DWORD   ?
    Stride              DWORD   ?
    PixelFormat         DWORD   ?
    Scan0               DWORD   ?
    Reserved            DWORD   ?
BitmapData ENDS
