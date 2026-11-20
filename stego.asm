; ==============================================================================
; stego.asm — Steganography & Image Handling for StegoVault Bank
; ==============================================================================
.586
.model flat, stdcall
option casemap:none

include constants.inc
include structs.inc
include protos.inc

PUBLIC DeriveCashierKek
PUBLIC LoadImageAsBmp
PUBLIC ParseBmp
PUBLIC EmbedBytes
PUBLIC ExtractBytes
PUBLIC ReadVaultStream
PUBLIC WriteVaultStream
PUBLIC BuildVaultImage
PUBLIC OpenVaultImage
PUBLIC InitGdiplus
PUBLIC ShutdownGdiplus

.data
szMasterKeyString DB "SV-MASTER-KEY-2026", 0

.data?
gdipToken       DWORD ?

.code

; ------------------------------------------------------------------------------
; InitGdiplus: Helper to start GDI+ once if not already running
; ------------------------------------------------------------------------------
InitGdiplus PROC USES ebx esi edi
    LOCAL gsi:GdiplusStartupInput
    .IF gdipToken == 0
        mov gsi.GdiplusVersion, 1
        mov gsi.DebugEventCallback, 0
        mov gsi.SuppressBackgroundThread, 0
        mov gsi.SuppressExternalCodecs, 0
        invoke GdiplusStartup, addr gdipToken, addr gsi, 0
        test eax, eax
        jnz gdipFail
    .ENDIF
    mov eax, 1
    ret
gdipFail:
    xor eax, eax
    ret
InitGdiplus ENDP

; ------------------------------------------------------------------------------
; ShutdownGdiplus: Helper to shut down GDI+ on application exit
; ------------------------------------------------------------------------------
ShutdownGdiplus PROC USES ebx esi edi
    .IF gdipToken != 0
        invoke GdiplusShutdown, gdipToken
        mov gdipToken, 0
    .ENDIF
    xor eax, eax
    ret
ShutdownGdiplus ENDP

; ------------------------------------------------------------------------------
; LoadImageAsBmp: Converts any GDI+ readable image file into 24-bit BMP buffer
; Inputs:  path (DWORD ptr), pSizeOut (DWORD ptr)
; Outputs: EAX = pointer to heap buffer containing BMP, or 0 on error
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
LoadImageAsBmp PROC USES ebx esi edi path:DWORD, pSizeOut:DWORD
    LOCAL wszPath[260]:WORD
    LOCAL pBitmap:DWORD
    LOCAL imgW:DWORD
    LOCAL imgH:DWORD
    LOCAL stride:DWORD
    LOCAL pixelBytes:DWORD
    LOCAL totalFileSize:DWORD
    LOCAL pBmpBuf:DWORD
    LOCAL rcLock:RECT
    LOCAL bmpData:BitmapData
    LOCAL y:DWORD
    LOCAL srcRow:DWORD
    LOCAL destRow:DWORD
    LOCAL rowBytes:DWORD
    LOCAL newW:DWORD
    LOCAL newH:DWORD
    LOCAL pScaled:DWORD
    LOCAL pGraphics:DWORD
    LOCAL scaleStatus:DWORD

    ; 1. Ensure GDI+ is initialized
    invoke InitGdiplus
    test eax, eax
    jz loadErrExit

    ; 2. Convert ASCII path to UTF-16
    invoke MultiByteToWideChar, CP_ACP, 0, path, -1, addr wszPath, 260
    test eax, eax
    jz loadErrExit

    ; 3. Load image via GDI+
    invoke GdipCreateBitmapFromFile, addr wszPath, addr pBitmap
    test eax, eax
    jnz loadErrExit

    ; 4. Check dimensions
    invoke GdipGetImageWidth, pBitmap, addr imgW
    invoke GdipGetImageHeight, pBitmap, addr imgH

    mov eax, imgW
    cmp eax, MIN_IMG_DIM
    jb disposeAndFail
    cmp eax, 20000
    ja disposeAndFail

    mov eax, imgH
    cmp eax, MIN_IMG_DIM
    jb disposeAndFail
    cmp eax, 20000
    ja disposeAndFail

    ; 4b. Downscale large photos so the vault BMP stays small and the UI stays
    ;     responsive: the longer side is reduced to MAX_COVER_DIM (aspect kept).
    mov eax, imgW
    cmp eax, MAX_COVER_DIM
    ja needScale
    mov eax, imgH
    cmp eax, MAX_COVER_DIM
    jbe noScale
needScale:
    mov eax, imgW
    cmp eax, imgH
    jb tallImage
    mov newW, MAX_COVER_DIM
    mov eax, imgH
    mov ecx, MAX_COVER_DIM
    mul ecx
    div imgW
    mov newH, eax
    jmp haveNewDims
tallImage:
    mov newH, MAX_COVER_DIM
    mov eax, imgW
    mov ecx, MAX_COVER_DIM
    mul ecx
    div imgH
    mov newW, eax
haveNewDims:
    cmp newW, MIN_IMG_DIM
    jb noScale
    cmp newH, MIN_IMG_DIM
    jb noScale
    invoke GdipCreateBitmapFromScan0, newW, newH, 0, PIXEL_FORMAT_24BPP_RGB, 0, addr pScaled
    test eax, eax
    jnz noScale
    invoke GdipGetImageGraphicsContext, pScaled, addr pGraphics
    test eax, eax
    jnz scaleFailed
    invoke GdipSetInterpolationMode, pGraphics, INTERP_HQ_BICUBIC
    invoke GdipDrawImageRectI, pGraphics, pBitmap, 0, 0, newW, newH
    mov scaleStatus, eax
    invoke GdipDeleteGraphics, pGraphics
    cmp scaleStatus, 0
    jne scaleFailed
    invoke GdipDisposeImage, pBitmap
    mov eax, pScaled
    mov pBitmap, eax
    mov eax, newW
    mov imgW, eax
    mov eax, newH
    mov imgH, eax
    jmp noScale
scaleFailed:
    invoke GdipDisposeImage, pScaled
noScale:

    ; 5. Calculate stride = (imgW * 3 + 3) AND (NOT 3)
    mov eax, imgW
    lea eax, [eax + eax*2]  ; eax = imgW * 3
    add eax, 3
    and eax, 0FFFFFFFCh     ; NOT 3
    mov stride, eax

    ; pixelBytes = stride * imgH
    mov ecx, imgH
    mul ecx
    mov pixelBytes, eax

    ; totalFileSize = 54 + pixelBytes
    add eax, 54
    cmp eax, MAX_FILE_BYTES
    ja disposeAndFail
    mov totalFileSize, eax

    ; 6. Allocate heap memory for 24-bit BMP file
    invoke GetProcessHeap
    invoke HeapAlloc, eax, HEAP_ZERO_MEMORY, totalFileSize
    test eax, eax
    jz disposeAndFail
    mov pBmpBuf, eax

    ; 7. Fill BITMAPFILEHEADER (14 bytes)
    mov esi, pBmpBuf
    mov WORD PTR [esi], 4D42h           ; bfType = 'BM'
    mov eax, totalFileSize
    mov [esi + 2], eax                  ; bfSize
    mov WORD PTR [esi + 6], 0           ; bfReserved1
    mov WORD PTR [esi + 8], 0           ; bfReserved2
    mov DWORD PTR [esi + 10], 54        ; bfOffBits

    ; 8. Fill BITMAPINFOHEADER (40 bytes)
    mov DWORD PTR [esi + 14], 40        ; biSize
    mov eax, imgW
    mov [esi + 18], eax                 ; biWidth
    mov eax, imgH
    mov [esi + 22], eax                 ; biHeight (positive = bottom-up)
    mov WORD PTR [esi + 26], 1          ; biPlanes
    mov WORD PTR [esi + 28], 24         ; biBitCount = 24
    mov DWORD PTR [esi + 30], 0         ; biCompression = BI_RGB
    mov eax, pixelBytes
    mov [esi + 34], eax                 ; biSizeImage
    mov DWORD PTR [esi + 38], 2835      ; biXPelsPerMeter
    mov DWORD PTR [esi + 42], 2835      ; biYPelsPerMeter
    mov DWORD PTR [esi + 46], 0         ; biClrUsed
    mov DWORD PTR [esi + 50], 0         ; biClrImportant

    ; 9. Lock bits in 24bpp RGB
    mov rcLock.left, 0
    mov rcLock.top, 0
    mov eax, imgW
    mov rcLock.right, eax
    mov eax, imgH
    mov rcLock.bottom, eax

    invoke GdipBitmapLockBits, pBitmap, addr rcLock, IMAGE_LOCK_READ,
           PIXEL_FORMAT_24BPP_RGB, addr bmpData
    test eax, eax
    jnz freeAndFail

    ; 10. Copy rows bottom-up
    mov eax, imgW
    lea eax, [eax + eax*2]  ; rowBytes = imgW * 3
    mov rowBytes, eax

    mov y, 0
rowCopyLoop:
    mov eax, y
    cmp eax, imgH
    jge rowCopyDone

    ; srcRow = bmpData.Scan0 + (imgH - 1 - y) * bmpData.Stride
    mov eax, imgH
    dec eax
    sub eax, y
    mov ecx, bmpData.Stride
    mul ecx
    add eax, bmpData.Scan0
    mov srcRow, eax

    ; destRow = pBmpBuf + 54 + y * stride
    mov eax, y
    mov ecx, stride
    mul ecx
    add eax, 54
    add eax, pBmpBuf
    mov destRow, eax

    invoke RtlMoveMemory, destRow, srcRow, rowBytes

    inc y
    jmp rowCopyLoop

rowCopyDone:
    invoke GdipBitmapUnlockBits, pBitmap, addr bmpData
    invoke GdipDisposeImage, pBitmap

    .IF pSizeOut != 0
        mov edx, pSizeOut
        mov eax, totalFileSize
        mov [edx], eax
    .ENDIF

    mov eax, pBmpBuf
    ret

freeAndFail:
    invoke GetProcessHeap
    invoke HeapFree, eax, 0, pBmpBuf

disposeAndFail:
    invoke GdipDisposeImage, pBitmap

loadErrExit:
    xor eax, eax
    ret
LoadImageAsBmp ENDP

; ------------------------------------------------------------------------------
; ParseBmp: Validates BMP header and calculates image dimensions and pixel array
; Inputs:  pBmp (DWORD ptr), fileSize (DWORD), pWidth (DWORD ptr),
;          pHeight (DWORD ptr), pPixOff (DWORD ptr), pPixBytes (DWORD ptr)
; Outputs: EAX = SV_OK or SV_ERR_BMP / SV_ERR_CAPACITY
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
ParseBmp PROC USES ebx esi edi pBmp:DWORD, fileSize:DWORD, pWidth:DWORD, pHeight:DWORD, pPixOff:DWORD, pPixBytes:DWORD
    LOCAL w:DWORD
    LOCAL h:DWORD
    LOCAL offBits:DWORD
    LOCAL stride:DWORD
    LOCAL expectedPix:DWORD
    LOCAL availablePix:DWORD
    LOCAL actualPix:DWORD
    LOCAL cap:DWORD

    mov esi, pBmp
    test esi, esi
    jz badBmp

    ; Check minimum size: 54 bytes
    mov eax, fileSize
    cmp eax, 54
    jb badBmp

    ; 1. Check 'BM' signature (0x4D42)
    cmp WORD PTR [esi], 4D42h
    jne badBmp

    ; 2. Check bfOffBits >= 54 and < fileSize
    mov eax, [esi + 10]
    cmp eax, 54
    jb badBmp
    cmp eax, fileSize
    jae badBmp
    mov offBits, eax

    ; 3. DIB header biSize >= 40
    mov eax, [esi + 14]
    cmp eax, 40
    jb badBmp

    ; 4. BitCount must be 24
    movzx eax, WORD PTR [esi + 28]
    cmp eax, 24
    jne badBmp

    ; 5. Compression must be 0 (BI_RGB)
    mov eax, [esi + 30]
    test eax, eax
    jnz badBmp

    ; 6. Width and Height must be positive
    mov eax, [esi + 18]     ; biWidth
    cmp eax, 0
    jle badBmp
    mov w, eax

    mov eax, [esi + 22]     ; biHeight
    cmp eax, 0
    jle badBmp
    mov h, eax

    ; 7. Compute stride = (w * 3 + 3) AND (NOT 3)
    mov eax, w
    lea eax, [eax + eax*2]  ; w * 3
    add eax, 3
    and eax, 0FFFFFFFCh
    mov stride, eax

    ; expectedPix = stride * h
    mov ecx, h
    mul ecx
    mov expectedPix, eax

    ; availablePix = fileSize - offBits
    mov eax, fileSize
    sub eax, offBits
    mov availablePix, eax

    ; actualPix = min(expectedPix, availablePix)
    mov eax, expectedPix
    .IF eax > availablePix
        mov eax, availablePix
    .ENDIF
    mov actualPix, eax

    ; 8. Capacity = actualPix / 8. Must be >= VAULT_STREAM_BYTES (256)
    mov eax, actualPix
    shr eax, 3              ; div 8
    mov cap, eax
    cmp eax, VAULT_STREAM_BYTES
    jb capErr

    ; Store results if requested
    .IF pWidth != 0
        mov edx, pWidth
        mov eax, w
        mov [edx], eax
    .ENDIF

    .IF pHeight != 0
        mov edx, pHeight
        mov eax, h
        mov [edx], eax
    .ENDIF

    .IF pPixOff != 0
        mov edx, pPixOff
        mov eax, offBits
        mov [edx], eax
    .ENDIF

    .IF pPixBytes != 0
        mov edx, pPixBytes
        mov eax, actualPix
        mov [edx], eax
    .ENDIF

    mov eax, SV_OK
    ret

capErr:
    mov eax, SV_ERR_CAPACITY
    ret

badBmp:
    mov eax, SV_ERR_BMP
    ret
ParseBmp ENDP

; ------------------------------------------------------------------------------
; EmbedBytes: Embeds data bytes into least significant bits of pixel bytes
; Inputs:  pPix (DWORD ptr), pData (DWORD ptr), nCount (DWORD)
; Outputs: EAX = SV_OK
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
EmbedBytes PROC USES ebx esi edi pPix:DWORD, pData:DWORD, nCount:DWORD
    mov edi, pPix
    mov esi, pData
    mov edx, nCount

    test edi, edi
    jz embedDone
    test esi, esi
    jz embedDone
    test edx, edx
    jz embedDone

embedByteLoop:
    test edx, edx
    jz embedDone

    mov al, [esi]       ; Current data byte
    mov ecx, 8          ; 8 bits to embed (MSB first)

embedBitLoop:
    mov bl, [edi]       ; Read pixel byte
    and bl, 0FEh        ; Clear LSB (this clears CF)
    shl al, 1           ; Carry flag = MSB (bit 7)
    adc bl, 0           ; Add Carry Flag into LSB
    mov [edi], bl       ; Write modified pixel byte
    inc edi             ; Next pixel byte
    dec ecx
    jnz embedBitLoop

    inc esi             ; Next data byte
    dec edx
    jmp embedByteLoop

embedDone:
    mov eax, SV_OK
    ret
EmbedBytes ENDP

; ------------------------------------------------------------------------------
; ExtractBytes: Extracts data bytes from least significant bits of pixel bytes
; Inputs:  pPix (DWORD ptr), pDest (DWORD ptr), nCount (DWORD)
; Outputs: EAX = SV_OK
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
ExtractBytes PROC USES ebx esi edi pPix:DWORD, pDest:DWORD, nCount:DWORD
    mov esi, pPix
    mov edi, pDest
    mov edx, nCount

    test esi, esi
    jz extractDone
    test edi, edi
    jz extractDone
    test edx, edx
    jz extractDone

extractByteLoop:
    test edx, edx
    jz extractDone

    xor al, al          ; Accumulator for 8 bits
    mov ecx, 8

extractBitLoop:
    mov bl, [esi]       ; Read pixel byte
    inc esi
    and bl, 1           ; Extract LSB
    shl al, 1           ; Shift accumulator left
    or al, bl           ; Insert extracted bit into bit 0
    dec ecx
    jnz extractBitLoop

    mov [edi], al       ; Store reconstructed byte
    inc edi
    dec edx
    jmp extractByteLoop

extractDone:
    mov eax, SV_OK
    ret
ExtractBytes ENDP

; ------------------------------------------------------------------------------
; ReadVaultStream: Extracts 256-byte vault stream from BMP buffer
; Inputs:  pBmp (DWORD ptr), pStreamOut (DWORD ptr)
; Outputs: EAX = SV_OK
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
ReadVaultStream PROC USES ebx esi edi pBmp:DWORD, pStreamOut:DWORD
    mov esi, pBmp
    test esi, esi
    jz streamErr

    ; bfOffBits is at offset 10 (0x0A) in BMP
    mov eax, [esi + 10]
    add eax, esi        ; eax = pointer to pixel data

    invoke ExtractBytes, eax, pStreamOut, VAULT_STREAM_BYTES
    mov eax, SV_OK
    ret

streamErr:
    mov eax, SV_ERR_BMP
    ret
ReadVaultStream ENDP

; ------------------------------------------------------------------------------
; WriteVaultStream: Embeds 256-byte vault stream into BMP buffer
; Inputs:  pBmp (DWORD ptr), pStreamIn (DWORD ptr)
; Outputs: EAX = SV_OK
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
WriteVaultStream PROC USES ebx esi edi pBmp:DWORD, pStreamIn:DWORD
    mov esi, pBmp
    test esi, esi
    jz streamErr2

    ; bfOffBits is at offset 10 (0x0A) in BMP
    mov eax, [esi + 10]
    add eax, esi        ; eax = pointer to pixel data

    invoke EmbedBytes, eax, pStreamIn, VAULT_STREAM_BYTES
    mov eax, SV_OK
    ret

streamErr2:
    mov eax, SV_ERR_BMP
    ret
WriteVaultStream ENDP

; ------------------------------------------------------------------------------
; DeriveCashierKek: Derives KEK_cashier = SvHash256("WRAP" || "SV-MASTER-KEY-2026")
; Inputs:  pKekOut (DWORD ptr to 32-byte buffer)
; Outputs: EAX = SV_OK
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
DeriveCashierKek PROC USES ebx esi edi pKekOut:DWORD
    LOCAL masterBuf[32]:BYTE

    cld
    mov DWORD PTR [masterBuf], 50415257h    ; "WRAP" in little-endian ('W'=57h, 'R'=52h, 'A'=41h, 'P'=50h)
    lea edi, masterBuf[4]
    lea esi, szMasterKeyString
    mov ecx, 18
    rep movsb

    ; Total prefix + master key = 4 + 18 = 22 bytes
    invoke SvHash256, addr masterBuf, 22, pKekOut
    invoke SvWipe, addr masterBuf, 32
    mov eax, SV_OK
    ret
DeriveCashierKek ENDP

; ------------------------------------------------------------------------------
; BuildVaultImage: Builds complete vault image from cover image and account record
; Inputs:  pCoverBmp (DWORD ptr), coverSize (DWORD), pRecord (DWORD ptr),
;          pDek (DWORD ptr), nonce (DWORD), pKekUser (DWORD ptr), pOutStream (DWORD ptr)
; Outputs: EAX = SV_OK or error
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
BuildVaultImage PROC USES ebx esi edi pCoverBmp:DWORD, coverSize:DWORD, pRecord:DWORD, pDek:DWORD, nonce:DWORD, pKekUser:DWORD, pOutStream:DWORD
    LOCAL stream[256]:BYTE
    LOCAL oldStream[256]:BYTE
    LOCAL encRecord[148]:BYTE
    LOCAL kekCashier[32]:BYTE
    LOCAL lowerUser[36]:BYTE

    mov esi, pRecord
    test esi, esi
    jz bldErrInput

    mov edx, pDek
    test edx, edx
    jz bldErrInput

    ; If cover image provided, validate it first
    .IF pCoverBmp != 0
        invoke ParseBmp, pCoverBmp, coverSize, NULL, NULL, NULL, NULL
        .IF eax != SV_OK
            ret
        .ENDIF
    .ENDIF

    ; 1. Magic: "SVLT" (0x544C5653)
    mov DWORD PTR [stream], SVLT_MAGIC

    ; 2. UserWrappedDEK at stream + 0x04
    .IF pKekUser != 0
        invoke SvWrapDek, pDek, pKekUser, addr stream[4]
    .ELSE
        .IF pCoverBmp != 0
            invoke ReadVaultStream, pCoverBmp, addr oldStream
            cld
            lea esi, oldStream[4]
            lea edi, stream[4]
            mov ecx, 32
            rep movsb
            invoke SvWipe, addr oldStream, 256
        .ELSE
            mov eax, SV_ERR_INPUT
            ret
        .ENDIF
    .ENDIF

    ; 3. CashierWrappedDEK at stream + 0x24
    invoke DeriveCashierKek, addr kekCashier
    invoke SvWrapDek, pDek, addr kekCashier, addr stream[24h]
    invoke SvWipe, addr kekCashier, 32

    ; 4. Checksum at stream + 0x44: SvFnv32(plaintext record) XOR DEK[0..3]
    invoke SvFnv32, pRecord, ACC_REC_SIZE
    mov edx, pDek
    xor eax, DWORD PTR [edx]
    mov DWORD PTR [stream + 44h], eax

    ; 5. UsernameHash at stream + 0x48: SvHash256(lowercase username)
    mov esi, pRecord
    add esi, 50h            ; offset of Username in ACCOUNT_RECORD
    lea edi, lowerUser
    xor ecx, ecx
bldLowerLoop:
    cmp ecx, 32
    jae bldLowerDone
    mov al, [esi + ecx]
    test al, al
    jz bldLowerDone
    cmp al, 'A'
    jb bldNotUp
    cmp al, 'Z'
    ja bldNotUp
    add al, 32
bldNotUp:
    mov [edi + ecx], al
    inc ecx
    jmp bldLowerLoop
bldLowerDone:
    mov BYTE PTR [edi + ecx], 0
    invoke SvHash256, addr lowerUser, ecx, addr stream[48h]
    invoke SvWipe, addr lowerUser, 36

    ; 6. Nonce at stream + 0x68
    mov eax, nonce
    mov DWORD PTR [stream + 68h], eax

    ; 7. EncryptedRecord at stream + 0x6C
    cld
    mov esi, pRecord
    lea edi, encRecord
    mov ecx, ACC_REC_SIZE
    rep movsb

    invoke SvCipher, addr encRecord, ACC_REC_SIZE, pDek, nonce, 1

    lea esi, encRecord
    lea edi, stream[6Ch]
    mov ecx, ACC_REC_SIZE
    rep movsb
    invoke SvWipe, addr encRecord, ACC_REC_SIZE

    ; 8. Embed into cover BMP if provided
    .IF pCoverBmp != 0
        invoke WriteVaultStream, pCoverBmp, addr stream
    .ENDIF

    ; 9. Output stream if requested
    .IF pOutStream != 0
        cld
        lea esi, stream
        mov edi, pOutStream
        mov ecx, VAULT_STREAM_BYTES
        rep movsb
    .ENDIF

    invoke SvWipe, addr stream, VAULT_STREAM_BYTES
    mov eax, SV_OK
    ret

bldErrInput:
    mov eax, SV_ERR_INPUT
    ret
BuildVaultImage ENDP

; ------------------------------------------------------------------------------
; OpenVaultImage: Reads and decrypts vault image for depositor or cashier
; Inputs:  path (DWORD ptr), pRecordOut (DWORD ptr), pKek (DWORD ptr),
;          expectedUser (DWORD ptr), pNonceOut (DWORD ptr), isCashier (DWORD)
; Outputs: EAX = SV_OK or error
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
OpenVaultImage PROC USES ebx esi edi path:DWORD, pRecordOut:DWORD, pKek:DWORD, expectedUser:DWORD, pNonceOut:DWORD, isCashier:DWORD
    LOCAL pBmp:DWORD
    LOCAL bAllocated:DWORD
    LOCAL fileSize:DWORD
    LOCAL stream[256]:BYTE
    LOCAL dek[32]:BYTE
    LOCAL decRecord[148]:BYTE
    LOCAL kekCashier[32]:BYTE
    LOCAL lowerUser[36]:BYTE
    LOCAL calcUserHash[32]:BYTE
    LOCAL nonce:DWORD
    LOCAL status:DWORD

    mov bAllocated, 0
    mov pBmp, 0
    mov status, SV_OK

    mov esi, path
    test esi, esi
    jz openIoErr

    ; Check if path points to a file on disk or already loaded in-memory BMP buffer
    invoke ReadWholeFile, path, addr fileSize
    .IF eax != 0
        mov pBmp, eax
        mov bAllocated, 1
    .ELSE
        mov edx, path
        cmp WORD PTR [edx], 4D42h       ; 'BM'
        jne openIoErr
        mov pBmp, edx
        mov bAllocated, 0
        mov eax, [edx + 2]              ; bfSize in BMP header
        mov fileSize, eax
    .ENDIF

    ; Validate BMP structure and capacity
    invoke ParseBmp, pBmp, fileSize, NULL, NULL, NULL, NULL
    .IF eax != SV_OK
        mov status, eax
        jmp cleanupExit
    .ENDIF

    ; Extract 256-byte stream
    invoke ReadVaultStream, pBmp, addr stream
    .IF eax != SV_OK
        mov status, eax
        jmp cleanupExit
    .ENDIF

    ; Check Magic
    cmp DWORD PTR [stream], SVLT_MAGIC
    je magicOk
    mov status, SV_ERR_MAGIC
    jmp cleanupExit

magicOk:
    ; If depositor and expectedUser provided, verify UsernameHash
    .IF isCashier == 0 && expectedUser != 0
        mov esi, expectedUser
        lea edi, lowerUser
        xor ecx, ecx
openLowerLoop:
        cmp ecx, 32
        jae openLowerDone
        mov al, [esi + ecx]
        test al, al
        jz openLowerDone
        cmp al, 'A'
        jb openNotUp
        cmp al, 'Z'
        ja openNotUp
        add al, 32
openNotUp:
        mov [edi + ecx], al
        inc ecx
        jmp openLowerLoop
openLowerDone:
        mov BYTE PTR [edi + ecx], 0
        invoke SvHash256, addr lowerUser, ecx, addr calcUserHash

        ; Compare with stream[48h] (UsernameHash)
        cld
        lea esi, calcUserHash
        lea edi, stream[48h]
        mov ecx, 32
        repe cmpsb
        je userHashOk
        mov status, SV_ERR_NOT_OWNER
        jmp cleanupExit
userHashOk:
    .ENDIF

    ; Unwrap DEK
    .IF isCashier != 0
        .IF pKek != 0
            invoke SvUnwrapDek, addr stream[24h], pKek, addr dek
        .ELSE
            invoke DeriveCashierKek, addr kekCashier
            invoke SvUnwrapDek, addr stream[24h], addr kekCashier, addr dek
            invoke SvWipe, addr kekCashier, 32
        .ENDIF
    .ELSE
        .IF pKek == 0
            mov status, SV_ERR_AUTH
            jmp cleanupExit
        .ENDIF
        invoke SvUnwrapDek, addr stream[04h], pKek, addr dek
    .ENDIF

    ; Extract Nonce from stream[68h]
    mov eax, DWORD PTR [stream + 68h]
    mov nonce, eax

    ; Copy encrypted record from stream[6Ch]
    cld
    lea esi, stream[6Ch]
    lea edi, decRecord
    mov ecx, ACC_REC_SIZE
    rep movsb

    ; Decrypt record in-place with SvCipher
    invoke SvCipher, addr decRecord, ACC_REC_SIZE, addr dek, nonce, 0

    ; Verify Checksum
    invoke SvFnv32, addr decRecord, ACC_REC_SIZE
    mov edx, DWORD PTR [dek]
    xor eax, edx
    cmp eax, DWORD PTR [stream + 44h]
    je chkOk
    mov status, SV_ERR_CHECKSUM
    jmp cleanupExit

chkOk:
    ; If depositor and expectedUser provided, verify record.Username equals expectedUser
    .IF isCashier == 0 && expectedUser != 0
        invoke lstrcmpiA, addr decRecord[50h], expectedUser
        test eax, eax
        jz recOwnerOk
        mov status, SV_ERR_NOT_OWNER
        jmp cleanupExit
recOwnerOk:
    .ENDIF

    ; Store outputs
    .IF pRecordOut != 0
        cld
        lea esi, decRecord
        mov edi, pRecordOut
        mov ecx, ACC_REC_SIZE
        rep movsb
    .ENDIF

    .IF pNonceOut != 0
        mov edx, pNonceOut
        mov eax, nonce
        mov [edx], eax
    .ENDIF

    mov status, SV_OK

cleanupExit:
    invoke SvWipe, addr stream, 256
    invoke SvWipe, addr dek, 32
    invoke SvWipe, addr decRecord, 148
    invoke SvWipe, addr kekCashier, 32
    invoke SvWipe, addr lowerUser, 36
    invoke SvWipe, addr calcUserHash, 32

    .IF bAllocated != 0 && pBmp != 0
        invoke GetProcessHeap
        invoke HeapFree, eax, 0, pBmp
    .ENDIF

    mov eax, status
    ret

openIoErr:
    mov eax, SV_ERR_IO
    ret
OpenVaultImage ENDP

END
