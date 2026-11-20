; ==============================================================================
; fileio.asm — File Storage, Persistence & Directory Scanning for StegoVault Bank
; ==============================================================================
.586
.model flat, stdcall
option casemap:none

include constants.inc
include structs.inc
include protos.inc

PUBLIC InitStorage
PUBLIC ReadWholeFile
PUBLIC WriteWholeFile
PUBLIC AtomicWriteFile
PUBLIC UsersCount
PUBLIC UsersRepair
PUBLIC CashierExists
PUBLIC CashierCreate
PUBLIC CashierVerify
PUBLIC usersLastErr
PUBLIC usersLastSize
PUBLIC UsersFind
PUBLIC UsersAppend
PUBLIC UsersSetNonce
PUBLIC ReqAppend
PUBLIC ReqCount
PUBLIC ReqReadAll
PUBLIC ReqSetStatus
PUBLIC ReqCountPending
PUBLIC ScanVault

.data
szVaultDir      BYTE "Vault_Images", 0
szUsersFile     BYTE "users.dat", 0
szRequestsFile  BYTE "requests.dat", 0
szUsersBackup   BYTE "users.dat.bak", 0
szCashierFile   BYTE "cashier.dat", 0
szDotTmp        BYTE ".tmp", 0
szSlashBmpStar  BYTE "\*.bmp", 0

.data?
usersLastErr    DWORD ?   ; Windows error of the last failed users.dat open/repair (0 = size problem)
usersLastSize   DWORD ?   ; size in bytes of users.dat at the last check

.code

; ------------------------------------------------------------------------------
; InitStorage: Ensures Vault_Images\ exists, creates users.dat & requests.dat
; Outputs: EAX = SV_OK or error
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
InitStorage PROC USES ebx esi edi
    LOCAL hFile:DWORD
    LOCAL szExePath[MAX_PATH]:BYTE

    ; 0. Pin the working directory to the folder containing main.exe, so the
    ;    relative data paths (users.dat, requests.dat, cashier.dat, Vault_Images\)
    ;    always resolve there however the program was launched.
    invoke GetModuleFileNameA, 0, addr szExePath, MAX_PATH
    test eax, eax
    jz cwdDone
    lea esi, szExePath
    add esi, eax                    ; ESI -> terminating NUL
findSlash:
    lea ecx, szExePath
    cmp esi, ecx
    jbe cwdDone
    dec esi
    cmp BYTE PTR [esi], '\'
    jne findSlash
    mov BYTE PTR [esi], 0           ; cut the file name, keep the folder
    invoke SetCurrentDirectoryA, addr szExePath
cwdDone:

    ; 1. Ensure Vault_Images directory exists
    invoke CreateDirectoryA, offset szVaultDir, 0
    test eax, eax
    jnz dirOk
    invoke GetLastError
    cmp eax, ERROR_ALREADY_EXISTS
    je dirOk
    mov eax, SV_ERR_IO
    ret

dirOk:
    ; 2. Ensure users.dat exists
    invoke CreateFileA, offset szUsersFile, GENERIC_READ or GENERIC_WRITE,
           FILE_SHARE_READ or FILE_SHARE_WRITE, 0, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
    cmp eax, INVALID_HANDLE_VALUE
    je ioErr
    mov hFile, eax
    invoke CloseHandle, hFile

    ; 3. Ensure requests.dat exists
    invoke CreateFileA, offset szRequestsFile, GENERIC_READ or GENERIC_WRITE,
           FILE_SHARE_READ or FILE_SHARE_WRITE, 0, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
    cmp eax, INVALID_HANDLE_VALUE
    je ioErr
    mov hFile, eax
    invoke CloseHandle, hFile

    mov eax, SV_OK
    ret

ioErr:
    mov eax, SV_ERR_IO
    ret
InitStorage ENDP

; ------------------------------------------------------------------------------
; ReadWholeFile: Reads entire file into heap-allocated buffer
; Inputs:  path (DWORD ptr), pSizeOut (DWORD ptr)
; Outputs: EAX = pointer to buffer or 0 on error
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
ReadWholeFile PROC USES ebx esi edi path:DWORD, pSizeOut:DWORD
    LOCAL hFile:DWORD
    LOCAL fileSize:DWORD
    LOCAL pBuf:DWORD
    LOCAL bytesRead:DWORD

    invoke CreateFileA, path, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, 0,
           OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
    cmp eax, INVALID_HANDLE_VALUE
    je errExit
    mov hFile, eax

    invoke GetFileSize, hFile, 0
    cmp eax, 0FFFFFFFFh
    je closeAndFail
    cmp eax, MAX_FILE_BYTES
    ja closeAndFail
    mov fileSize, eax

    ; Allocate memory (fileSize + 1)
    mov edx, fileSize
    inc edx
    invoke GetProcessHeap
    invoke HeapAlloc, eax, HEAP_ZERO_MEMORY, edx
    test eax, eax
    jz closeAndFail
    mov pBuf, eax

    .IF fileSize > 0
        invoke ReadFile, hFile, pBuf, fileSize, addr bytesRead, 0
        test eax, eax
        jz freeAndFail
        mov eax, bytesRead
        cmp eax, fileSize
        jne freeAndFail
    .ENDIF

    invoke CloseHandle, hFile

    .IF pSizeOut != 0
        mov edx, pSizeOut
        mov ecx, fileSize
        mov [edx], ecx
    .ENDIF

    mov eax, pBuf
    ret

freeAndFail:
    invoke GetProcessHeap
    invoke HeapFree, eax, 0, pBuf

closeAndFail:
    invoke CloseHandle, hFile

errExit:
    xor eax, eax
    ret
ReadWholeFile ENDP

; ------------------------------------------------------------------------------
; WriteWholeFile: Writes buffer to file overwriting it
; Inputs:  path (DWORD ptr), pBuf (DWORD ptr), nBytes (DWORD)
; Outputs: EAX = SV_OK or error
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
WriteWholeFile PROC USES ebx esi edi path:DWORD, pBuf:DWORD, nBytes:DWORD
    LOCAL hFile:DWORD
    LOCAL bytesWritten:DWORD

    invoke CreateFileA, path, GENERIC_WRITE, 0, 0,
           CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
    cmp eax, INVALID_HANDLE_VALUE
    je errExit
    mov hFile, eax

    .IF nBytes > 0
        invoke WriteFile, hFile, pBuf, nBytes, addr bytesWritten, 0
        test eax, eax
        jz closeAndFail
        mov eax, bytesWritten
        cmp eax, nBytes
        jne closeAndFail
    .ENDIF

    invoke CloseHandle, hFile
    mov eax, SV_OK
    ret

closeAndFail:
    invoke CloseHandle, hFile

errExit:
    mov eax, SV_ERR_IO
    ret
WriteWholeFile ENDP

; ------------------------------------------------------------------------------
; AtomicWriteFile: Writes path.tmp then atomically moves to path
; Inputs:  path (DWORD ptr), pBuf (DWORD ptr), nBytes (DWORD)
; Outputs: EAX = SV_OK or error
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
AtomicWriteFile PROC USES ebx esi edi path:DWORD, pBuf:DWORD, nBytes:DWORD
    LOCAL szTmpPath[260]:BYTE
    LOCAL hFile:DWORD
    LOCAL bytesWritten:DWORD

    ; Build path.tmp
    invoke lstrcpyA, addr szTmpPath, path
    invoke lstrcatA, addr szTmpPath, offset szDotTmp

    invoke CreateFileA, addr szTmpPath, GENERIC_WRITE, 0, 0,
           CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
    cmp eax, INVALID_HANDLE_VALUE
    je errExit
    mov hFile, eax

    .IF nBytes > 0
        invoke WriteFile, hFile, pBuf, nBytes, addr bytesWritten, 0
        test eax, eax
        jz failAndDel
        mov eax, bytesWritten
        cmp eax, nBytes
        jne failAndDel
    .ENDIF

    invoke FlushFileBuffers, hFile
    invoke CloseHandle, hFile

    ; Atomically replace final file
    invoke MoveFileExA, addr szTmpPath, path, MOVEFILE_REPLACE_EXISTING
    test eax, eax
    jz delTmp

    mov eax, SV_OK
    ret

failAndDel:
    invoke CloseHandle, hFile

delTmp:
    invoke DeleteFileA, addr szTmpPath

errExit:
    mov eax, SV_ERR_IO
    ret
AtomicWriteFile ENDP

; ------------------------------------------------------------------------------
; CashierExists: Is a cashier account configured (cashier.dat of CASH_REC_SIZE bytes)?
; Outputs: EAX = 1 yes, 0 no (not created yet, or unreadable)
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
CashierExists PROC USES ebx esi edi
    LOCAL hFile:DWORD
    LOCAL fileSize:DWORD

    invoke CreateFileA, offset szCashierFile, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, 0,
           OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
    cmp eax, INVALID_HANDLE_VALUE
    je noCashier
    mov hFile, eax
    invoke GetFileSize, hFile, 0
    mov fileSize, eax
    invoke CloseHandle, hFile
    cmp fileSize, CASH_REC_SIZE
    jne noCashier
    mov eax, 1
    ret
noCashier:
    xor eax, eax
    ret
CashierExists ENDP

; ------------------------------------------------------------------------------
; CashierCreate: Writes cashier.dat = Username[32] | Salt[16] | Verifier[32]
;   (verifier = SvDeriveKeys "AUTH" hash; the password itself is never stored).
; Inputs:  pUser (NUL-terminated, <= 31 chars), pPass (NUL-terminated)
; Outputs: EAX = SV_OK or SV_ERR_*
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
CashierCreate PROC USES ebx esi edi pUser:DWORD, pPass:DWORD
    LOCAL rec[CASH_REC_SIZE]:BYTE
    LOCAL kek[32]:BYTE
    LOCAL passLen:DWORD

    lea ebx, rec
    invoke SvWipe, ebx, CASH_REC_SIZE
    invoke lstrcpyA, ebx, pUser
    lea eax, [ebx + 32]
    invoke SvRandom, eax, 16
    invoke lstrlenA, pPass
    mov passLen, eax
    lea eax, [ebx + 32]
    lea ecx, [ebx + 48]
    lea edx, kek
    invoke SvDeriveKeys, eax, pPass, passLen, ecx, edx
    invoke AtomicWriteFile, offset szCashierFile, ebx, CASH_REC_SIZE
    mov esi, eax
    invoke SvWipe, addr kek, 32
    invoke SvWipe, ebx, CASH_REC_SIZE
    mov eax, esi
    ret
CashierCreate ENDP

; ------------------------------------------------------------------------------
; CashierVerify: Checks a username/password against cashier.dat
; Inputs:  pUser, pPass (NUL-terminated)
; Outputs: EAX = SV_OK match, SV_ERR_AUTH mismatch, SV_ERR_IO unreadable file
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
CashierVerify PROC USES ebx esi edi pUser:DWORD, pPass:DWORD
    LOCAL rec[CASH_REC_SIZE]:BYTE
    LOCAL verifier[32]:BYTE
    LOCAL kek[32]:BYTE
    LOCAL hFile:DWORD
    LOCAL bytesRead:DWORD
    LOCAL passLen:DWORD
    LOCAL result:DWORD

    mov result, SV_ERR_IO
    invoke CreateFileA, offset szCashierFile, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, 0,
           OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
    cmp eax, INVALID_HANDLE_VALUE
    je cvDone
    mov hFile, eax
    invoke ReadFile, hFile, addr rec, CASH_REC_SIZE, addr bytesRead, 0
    push eax
    invoke CloseHandle, hFile
    pop eax
    test eax, eax
    jz cvDone
    cmp bytesRead, CASH_REC_SIZE
    jne cvDone

    mov result, SV_ERR_AUTH
    lea ebx, rec
    invoke lstrcmpiA, pUser, ebx
    test eax, eax
    jnz cvWipe

    invoke lstrlenA, pPass
    mov passLen, eax
    lea eax, [ebx + 32]
    lea ecx, verifier
    lea edx, kek
    invoke SvDeriveKeys, eax, pPass, passLen, ecx, edx

    ; Constant-time compare of the 32-byte verifier
    xor ecx, ecx
    xor edx, edx
cvCmp:
    movzx eax, BYTE PTR [ebx + 48 + ecx]
    lea esi, verifier
    movzx esi, BYTE PTR [esi + ecx]
    xor eax, esi
    or edx, eax
    inc ecx
    cmp ecx, 32
    jb cvCmp
    test edx, edx
    jnz cvWipe
    mov result, SV_OK

cvWipe:
    invoke SvWipe, addr verifier, 32
    invoke SvWipe, addr kek, 32
cvDone:
    mov eax, result
    ret
CashierVerify ENDP

; ------------------------------------------------------------------------------
; UsersRepair: Repairs a users.dat whose size is not a multiple of USER_REC_SIZE.
;   A copy is first saved as users.dat.bak, then any incomplete trailing record
;   is cut off so every remaining record is whole. Complete records are untouched.
; Outputs: EAX = SV_OK        file repaired
;          EAX = SV_ERR_INPUT size already valid (nothing to repair)
;          EAX = SV_ERR_IO    backup / open / truncate failed (file left as it was)
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
UsersRepair PROC USES ebx esi edi
    LOCAL hFile:DWORD
    LOCAL fileSize:DWORD
    LOCAL newSize:DWORD

    mov usersLastErr, 0
    invoke CreateFileA, offset szUsersFile, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, 0,
           OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
    cmp eax, INVALID_HANDLE_VALUE
    jne repOpened1
    invoke GetLastError
    mov usersLastErr, eax
    jmp repIoErr
repOpened1:
    mov hFile, eax
    invoke GetFileSize, hFile, 0
    mov fileSize, eax
    invoke CloseHandle, hFile
    cmp fileSize, 0FFFFFFFFh
    jne repSized
    mov usersLastErr, 1
    jmp repIoErr
repSized:
    mov eax, fileSize
    xor edx, edx
    mov ecx, USER_REC_SIZE
    div ecx
    test edx, edx
    jz repNothing
    mov ecx, fileSize
    sub ecx, edx
    mov newSize, ecx

    ; Best-effort backup copy (a failed backup does not block the repair:
    ; only an incomplete trailing record is removed, whole records are kept)
    invoke CopyFileA, offset szUsersFile, offset szUsersBackup, 0

    invoke CreateFileA, offset szUsersFile, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, 0,
           OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
    cmp eax, INVALID_HANDLE_VALUE
    jne repOpened2
    invoke GetLastError
    mov usersLastErr, eax
    jmp repIoErr
repOpened2:
    mov hFile, eax
    invoke SetFilePointer, hFile, newSize, 0, FILE_BEGIN
    cmp eax, 0FFFFFFFFh
    jne repSeekOk
    invoke GetLastError
    mov usersLastErr, eax
    jmp repCloseErr
repSeekOk:
    invoke SetEndOfFile, hFile
    test eax, eax
    jnz repTruncOk
    invoke GetLastError
    mov usersLastErr, eax
    jmp repCloseErr
repTruncOk:
    invoke CloseHandle, hFile
    mov eax, SV_OK
    ret

repCloseErr:
    invoke CloseHandle, hFile
repIoErr:
    mov eax, SV_ERR_IO
    ret
repNothing:
    mov eax, SV_ERR_INPUT
    ret
UsersRepair ENDP

; ------------------------------------------------------------------------------
; UsersCount: Returns number of registered users in users.dat
; Outputs: EAX = count of users (>= 0), or -1 on error / damaged file
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
UsersCount PROC USES ebx esi edi
    LOCAL hFile:DWORD
    LOCAL fileSize:DWORD

    mov usersLastErr, 0
    mov usersLastSize, 0
    invoke CreateFileA, offset szUsersFile, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, 0,
           OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
    cmp eax, INVALID_HANDLE_VALUE
    jne countOpened
    invoke GetLastError
    mov usersLastErr, eax
    jmp failExit
countOpened:
    mov hFile, eax

    invoke GetFileSize, hFile, 0
    mov fileSize, eax
    invoke CloseHandle, hFile

    cmp fileSize, 0FFFFFFFFh
    jne countSized
    mov usersLastErr, 1
    jmp failExit
countSized:
    mov eax, fileSize
    mov usersLastSize, eax

    ; Check if multiple of USER_REC_SIZE (96); usersLastErr stays 0 = size problem
    xor edx, edx
    mov ecx, USER_REC_SIZE
    div ecx
    test edx, edx
    jnz failExit
    ret

failExit:
    mov eax, -1
    ret
UsersCount ENDP

; ------------------------------------------------------------------------------
; UsersFind: Looks up user by username (case-insensitive) in users.dat
; Inputs:  pUsername (DWORD ptr), pRecordOut (DWORD ptr)
; Outputs: EAX = SV_OK if found, SV_ERR_AUTH if not found, SV_ERR_IO on error
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
UsersFind PROC USES ebx esi edi pUsername:DWORD, pRecordOut:DWORD
    LOCAL hFile:DWORD
    LOCAL fileSize:DWORD
    LOCAL rec:USER_RECORD
    LOCAL bytesRead:DWORD
    LOCAL numRecs:DWORD
    LOCAL i:DWORD

    invoke CreateFileA, offset szUsersFile, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, 0,
           OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
    cmp eax, INVALID_HANDLE_VALUE
    je ioErr
    mov hFile, eax

    invoke GetFileSize, hFile, 0
    mov fileSize, eax
    cmp eax, 0FFFFFFFFh
    je closeAndIoErr

    ; Check if multiple of 96
    mov eax, fileSize
    xor edx, edx
    mov ecx, USER_REC_SIZE
    div ecx
    test edx, edx
    jnz closeAndIoErr ; Damaged file!
    mov numRecs, eax

    xor ecx, ecx
searchLoop:
    cmp ecx, numRecs
    jge notFound
    mov i, ecx

    invoke ReadFile, hFile, addr rec, USER_REC_SIZE, addr bytesRead, 0
    test eax, eax
    jz closeAndIoErr
    mov eax, bytesRead
    cmp eax, USER_REC_SIZE
    jne closeAndIoErr

    ; Case-insensitive compare
    invoke lstrcmpiA, pUsername, addr rec.Username
    test eax, eax
    jz foundUser

    mov ecx, i
    inc ecx
    jmp searchLoop

foundUser:
    invoke CloseHandle, hFile

    ; Copy record to output
    .IF pRecordOut != 0
        invoke RtlMoveMemory, pRecordOut, addr rec, USER_REC_SIZE
    .ENDIF

    mov eax, SV_OK
    ret

notFound:
    invoke CloseHandle, hFile
    mov eax, SV_ERR_AUTH
    ret

closeAndIoErr:
    invoke CloseHandle, hFile

ioErr:
    mov eax, SV_ERR_IO
    ret
UsersFind ENDP

; ------------------------------------------------------------------------------
; UsersAppend: Appends a 96-byte USER_RECORD to users.dat
; Inputs:  pRecord (DWORD ptr)
; Outputs: EAX = SV_OK or error
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
UsersAppend PROC USES ebx esi edi pRecord:DWORD
    LOCAL hFile:DWORD
    LOCAL fileSize:DWORD
    LOCAL bytesWritten:DWORD

    invoke CreateFileA, offset szUsersFile, GENERIC_READ or GENERIC_WRITE,
           FILE_SHARE_READ or FILE_SHARE_WRITE, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
    cmp eax, INVALID_HANDLE_VALUE
    je ioErr
    mov hFile, eax

    invoke GetFileSize, hFile, 0
    mov fileSize, eax
    cmp eax, 0FFFFFFFFh
    je closeAndIoErr

    ; Check damaged size
    mov eax, fileSize
    xor edx, edx
    mov ecx, USER_REC_SIZE
    div ecx
    test edx, edx
    jnz closeAndIoErr

    ; Seek to end
    invoke SetFilePointer, hFile, 0, 0, FILE_END

    ; Write record
    invoke WriteFile, hFile, pRecord, USER_REC_SIZE, addr bytesWritten, 0
    test eax, eax
    jz rollbackAndFail
    mov eax, bytesWritten
    cmp eax, USER_REC_SIZE
    jne rollbackAndFail

    invoke FlushFileBuffers, hFile
    invoke CloseHandle, hFile
    mov eax, SV_OK
    ret

rollbackAndFail:
    ; Truncate back to original size
    invoke SetFilePointer, hFile, fileSize, 0, FILE_BEGIN
    invoke SetEndOfFile, hFile

closeAndIoErr:
    invoke CloseHandle, hFile

ioErr:
    mov eax, SV_ERR_IO
    ret
UsersAppend ENDP

; ------------------------------------------------------------------------------
; UsersSetNonce: Updates LastNonce for a given user in users.dat
; Inputs:  pUsername (DWORD ptr), newNonce (DWORD)
; Outputs: EAX = SV_OK or error
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
UsersSetNonce PROC USES ebx esi edi pUsername:DWORD, newNonce:DWORD
    LOCAL hFile:DWORD
    LOCAL fileSize:DWORD
    LOCAL rec:USER_RECORD
    LOCAL bytesRead:DWORD
    LOCAL bytesWritten:DWORD
    LOCAL numRecs:DWORD
    LOCAL i:DWORD
    LOCAL targetOffset:DWORD

    invoke CreateFileA, offset szUsersFile, GENERIC_READ or GENERIC_WRITE,
           FILE_SHARE_READ or FILE_SHARE_WRITE, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
    cmp eax, INVALID_HANDLE_VALUE
    je ioErr
    mov hFile, eax

    invoke GetFileSize, hFile, 0
    mov fileSize, eax
    cmp eax, 0FFFFFFFFh
    je closeAndIoErr

    ; Check damaged size
    mov eax, fileSize
    xor edx, edx
    mov ecx, USER_REC_SIZE
    div ecx
    test edx, edx
    jnz closeAndIoErr
    mov numRecs, eax

    xor ecx, ecx
searchLoop:
    cmp ecx, numRecs
    jge notFound
    mov i, ecx

    invoke ReadFile, hFile, addr rec, USER_REC_SIZE, addr bytesRead, 0
    test eax, eax
    jz closeAndIoErr
    mov eax, bytesRead
    cmp eax, USER_REC_SIZE
    jne closeAndIoErr

    invoke lstrcmpiA, pUsername, addr rec.Username
    test eax, eax
    jz matchFound

    mov ecx, i
    inc ecx
    jmp searchLoop

matchFound:
    ; Target file offset = i * 96 + 80 (LastNonce is at offset +0x50 = 80)
    mov eax, i
    mov ecx, USER_REC_SIZE
    mul ecx
    add eax, 50h ; +0x50 is LastNonce
    mov targetOffset, eax

    invoke SetFilePointer, hFile, targetOffset, 0, FILE_BEGIN
    invoke WriteFile, hFile, addr newNonce, 4, addr bytesWritten, 0
    test eax, eax
    jz closeAndIoErr
    mov eax, bytesWritten
    cmp eax, 4
    jne closeAndIoErr

    invoke FlushFileBuffers, hFile
    invoke CloseHandle, hFile
    mov eax, SV_OK
    ret

notFound:
    invoke CloseHandle, hFile
    mov eax, SV_ERR_AUTH
    ret

closeAndIoErr:
    invoke CloseHandle, hFile

ioErr:
    mov eax, SV_ERR_IO
    ret
UsersSetNonce ENDP

; ------------------------------------------------------------------------------
; ReqAppend: Appends a 64-byte REQUEST_RECORD to requests.dat
; Inputs:  pRecord (DWORD ptr)
; Outputs: EAX = SV_OK or error
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
ReqAppend PROC USES ebx esi edi pRecord:DWORD
    LOCAL hFile:DWORD
    LOCAL fileSize:DWORD
    LOCAL bytesWritten:DWORD

    invoke CreateFileA, offset szRequestsFile, GENERIC_READ or GENERIC_WRITE,
           FILE_SHARE_READ or FILE_SHARE_WRITE, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
    cmp eax, INVALID_HANDLE_VALUE
    je ioErr
    mov hFile, eax

    invoke GetFileSize, hFile, 0
    mov fileSize, eax
    cmp eax, 0FFFFFFFFh
    je closeAndIoErr

    ; Check damaged size (multiple of 64)
    mov eax, fileSize
    xor edx, edx
    mov ecx, REQ_REC_SIZE
    div ecx
    test edx, edx
    jnz closeAndIoErr

    ; Seek to end
    invoke SetFilePointer, hFile, 0, 0, FILE_END

    ; Write record
    invoke WriteFile, hFile, pRecord, REQ_REC_SIZE, addr bytesWritten, 0
    test eax, eax
    jz rollbackAndFail
    mov eax, bytesWritten
    cmp eax, REQ_REC_SIZE
    jne rollbackAndFail

    invoke FlushFileBuffers, hFile
    invoke CloseHandle, hFile
    mov eax, SV_OK
    ret

rollbackAndFail:
    invoke SetFilePointer, hFile, fileSize, 0, FILE_BEGIN
    invoke SetEndOfFile, hFile

closeAndIoErr:
    invoke CloseHandle, hFile

ioErr:
    mov eax, SV_ERR_IO
    ret
ReqAppend ENDP

; ------------------------------------------------------------------------------
; ReqCount: Returns the number of 64-byte records in requests.dat
; Outputs: EAX = record count, or -1 on error
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
ReqCount PROC USES ebx esi edi
    LOCAL hFile:DWORD
    LOCAL fileSize:DWORD

    invoke CreateFileA, offset szRequestsFile, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, 0,
           OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
    cmp eax, INVALID_HANDLE_VALUE
    je countFail
    mov hFile, eax

    invoke GetFileSize, hFile, 0
    mov fileSize, eax
    invoke CloseHandle, hFile

    cmp fileSize, 0FFFFFFFFh
    je countFail

    ; Check if multiple of REQ_REC_SIZE (64)
    mov eax, fileSize
    xor edx, edx
    mov ecx, REQ_REC_SIZE
    div ecx
    test edx, edx
    jnz countFail    ; Damaged file

    ret

countFail:
    mov eax, -1
    ret
ReqCount ENDP

; ------------------------------------------------------------------------------
; ReqReadAll: Reads all request records into buffer
; Inputs:  pBuf (DWORD ptr), pCountOut (DWORD ptr)
; Outputs: EAX = SV_OK or error
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
ReqReadAll PROC USES ebx esi edi pBuf:DWORD, pCountOut:DWORD
    LOCAL hFile:DWORD
    LOCAL fileSize:DWORD
    LOCAL bytesRead:DWORD
    LOCAL numRecs:DWORD

    invoke CreateFileA, offset szRequestsFile, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, 0,
           OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
    cmp eax, INVALID_HANDLE_VALUE
    je ioErr
    mov hFile, eax

    invoke GetFileSize, hFile, 0
    mov fileSize, eax
    cmp eax, 0FFFFFFFFh
    je closeAndIoErr

    ; Check multiple of 64
    mov eax, fileSize
    xor edx, edx
    mov ecx, REQ_REC_SIZE
    div ecx
    test edx, edx
    jnz closeAndIoErr
    mov numRecs, eax

    .IF pCountOut != 0
        mov edx, pCountOut
        mov ecx, numRecs
        mov [edx], ecx
    .ENDIF

    .IF pBuf != 0 && fileSize > 0
        invoke ReadFile, hFile, pBuf, fileSize, addr bytesRead, 0
        test eax, eax
        jz closeAndIoErr
        mov eax, bytesRead
        cmp eax, fileSize
        jne closeAndIoErr
    .ENDIF

    invoke CloseHandle, hFile
    mov eax, SV_OK
    ret

closeAndIoErr:
    invoke CloseHandle, hFile

ioErr:
    mov eax, SV_ERR_IO
    ret
ReqReadAll ENDP

; ------------------------------------------------------------------------------
; ReqSetStatus: Updates Status field of request by index
; Inputs:  reqIndex (DWORD), newStatus (DWORD)
; Outputs: EAX = SV_OK or error
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
ReqSetStatus PROC USES ebx esi edi reqIndex:DWORD, newStatus:DWORD
    LOCAL hFile:DWORD
    LOCAL fileSize:DWORD
    LOCAL bytesWritten:DWORD
    LOCAL targetOffset:DWORD
    LOCAL maxIndex:DWORD

    invoke CreateFileA, offset szRequestsFile, GENERIC_READ or GENERIC_WRITE,
           FILE_SHARE_READ or FILE_SHARE_WRITE, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
    cmp eax, INVALID_HANDLE_VALUE
    je ioErr
    mov hFile, eax

    invoke GetFileSize, hFile, 0
    mov fileSize, eax
    cmp eax, 0FFFFFFFFh
    je closeAndIoErr

    ; Check multiple of 64
    mov eax, fileSize
    xor edx, edx
    mov ecx, REQ_REC_SIZE
    div ecx
    test edx, edx
    jnz closeAndIoErr
    mov maxIndex, eax

    mov eax, reqIndex
    cmp eax, maxIndex
    jae closeAndIoErr

    ; Target offset = reqIndex * 64 + 0x38 (56 decimal: Status offset)
    mov eax, reqIndex
    mov ecx, REQ_REC_SIZE
    mul ecx
    add eax, 38h
    mov targetOffset, eax

    invoke SetFilePointer, hFile, targetOffset, 0, FILE_BEGIN
    invoke WriteFile, hFile, addr newStatus, 4, addr bytesWritten, 0
    test eax, eax
    jz closeAndIoErr
    mov eax, bytesWritten
    cmp eax, 4
    jne closeAndIoErr

    invoke FlushFileBuffers, hFile
    invoke CloseHandle, hFile
    mov eax, SV_OK
    ret

closeAndIoErr:
    invoke CloseHandle, hFile

ioErr:
    mov eax, SV_ERR_IO
    ret
ReqSetStatus ENDP

; ------------------------------------------------------------------------------
; ReqCountPending: Returns number of status 0 (Pending) requests
; Outputs: EAX = pending count, or -1 on error
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
ReqCountPending PROC USES ebx esi edi
    LOCAL hFile:DWORD
    LOCAL fileSize:DWORD
    LOCAL rec:REQUEST_RECORD
    LOCAL bytesRead:DWORD
    LOCAL numRecs:DWORD
    LOCAL pendingCount:DWORD
    LOCAL i:DWORD

    invoke CreateFileA, offset szRequestsFile, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, 0,
           OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
    cmp eax, INVALID_HANDLE_VALUE
    je failExit
    mov hFile, eax

    invoke GetFileSize, hFile, 0
    mov fileSize, eax
    cmp eax, 0FFFFFFFFh
    je closeAndFail

    ; Check multiple of 64
    mov eax, fileSize
    xor edx, edx
    mov ecx, REQ_REC_SIZE
    div ecx
    test edx, edx
    jnz closeAndFail
    mov numRecs, eax

    mov pendingCount, 0
    xor ecx, ecx

countLoop:
    cmp ecx, numRecs
    jge doneCount
    mov i, ecx

    invoke ReadFile, hFile, addr rec, REQ_REC_SIZE, addr bytesRead, 0
    test eax, eax
    jz closeAndFail
    mov eax, bytesRead
    cmp eax, REQ_REC_SIZE
    jne closeAndFail

    .IF rec.Status == REQ_STATUS_PENDING
        inc pendingCount
    .ENDIF

    mov ecx, i
    inc ecx
    jmp countLoop

doneCount:
    invoke CloseHandle, hFile
    mov eax, pendingCount
    ret

closeAndFail:
    invoke CloseHandle, hFile

failExit:
    mov eax, -1
    ret
ReqCountPending ENDP

; ------------------------------------------------------------------------------
; ScanVault: Scans Vault_Images\*.bmp and calls callback(pFileName)
; Inputs:  pCallback (DWORD ptr)
; Outputs: EAX = SV_OK or error
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
ScanVault PROC USES ebx esi edi pCallback:DWORD
    LOCAL findData:WIN32_FIND_DATAA
    LOCAL hFind:DWORD
    LOCAL szPattern[260]:BYTE

    invoke lstrcpyA, addr szPattern, offset szVaultDir
    invoke lstrcatA, addr szPattern, offset szSlashBmpStar

    invoke FindFirstFileA, addr szPattern, addr findData
    cmp eax, INVALID_HANDLE_VALUE
    je doneNoFiles
    mov hFind, eax

scanLoop:
    ; Skip '.' files
    cmp findData.cFileName[0], '.'
    je nextFile

    ; Call callback(addr findData.cFileName)
    lea eax, findData.cFileName
    push eax
    call pCallback

nextFile:
    invoke FindNextFileA, hFind, addr findData
    test eax, eax
    jnz scanLoop

    invoke FindClose, hFind

doneNoFiles:
    mov eax, SV_OK
    ret
ScanVault ENDP

END
