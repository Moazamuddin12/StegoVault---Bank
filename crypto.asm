; ==============================================================================
; crypto.asm — Cryptographic & Hashing Operations for StegoVault Bank
; ==============================================================================
.586
.model flat, stdcall
option casemap:none

include constants.inc
include structs.inc
include protos.inc

PUBLIC SvHash256
PUBLIC SvDeriveKeys
PUBLIC SvCipher
PUBLIC SvWrapDek
PUBLIC SvUnwrapDek
PUBLIC SvRandom
PUBLIC SvFnv32
PUBLIC SvWipe

.code

; ------------------------------------------------------------------------------
; SvHash256: Computes educational 256-bit hash (SPEC section 5)
; Inputs:  pData (DWORD ptr), nLen (DWORD), pOut32 (DWORD ptr)
; Outputs: EAX = 0 (SV_OK)
; Preserved: EBX, ESI, EDI
; Clobbered: EAX, ECX, EDX
; ------------------------------------------------------------------------------
SvHash256 PROC USES ebx esi edi pData:DWORD, nLen:DWORD, pOut32:DWORD
    LOCAL H[8]:DWORD
    LOCAL rotTable[8]:DWORD
    LOCAL roundCount:DWORD
    LOCAL lane:DWORD
    LOCAL t1:DWORD
    LOCAL t2:DWORD

    ; Initialize rotation table for lanes 0..7: (i XOR 5) + 1
    ; i=0 -> 6, i=1 -> 5, i=2 -> 8, i=3 -> 7, i=4 -> 2, i=5 -> 1, i=6 -> 4, i=7 -> 3
    mov rotTable[0*4], 6
    mov rotTable[1*4], 5
    mov rotTable[2*4], 8
    mov rotTable[3*4], 7
    mov rotTable[4*4], 2
    mov rotTable[5*4], 1
    mov rotTable[6*4], 4
    mov rotTable[7*4], 3

    ; Initialize state: H[i] = 0x811C9DC5 XOR (i * 0x9E3779B9)
    xor ecx, ecx
initH:
    cmp ecx, 8
    jge initDone
    mov eax, ecx
    mov edx, 9E3779B9h
    mul edx             ; eax = i * 0x9E3779B9
    xor eax, 811C9DC5h
    mov H[ecx*4], eax
    inc ecx
    jmp initH
initDone:

    ; Process each input byte
    mov esi, pData
    mov edi, nLen
    test esi, esi
    jz finalizeHash
    test edi, edi
    jz finalizeHash

byteLoop:
    test edi, edi
    jz finalizeHash
    movzx edx, BYTE PTR [esi]   ; edx = byte b

    ; For lane i in 0..7:
    xor ecx, ecx
laneLoop:
    cmp ecx, 8
    jge nextByte

    ; H[i] = (H[i] XOR b) * 0x01000193
    mov eax, H[ecx*4]
    xor eax, edx
    imul eax, 01000193h

    ; H[i] = ROL(H[i], rotTable[i])
    push ecx
    mov ecx, rotTable[ecx*4]
    rol eax, cl
    pop ecx

    mov H[ecx*4], eax
    inc ecx
    jmp laneLoop

nextByte:
    inc esi
    dec edi
    jmp byteLoop

finalizeHash:
    ; Finalise with 4 rounds:
    ; for round in 0..3:
    ;   for i in 0..7:
    ;     H[i] = (H[i] + ROL(H[(i+1) AND 7], 7)) XOR ROR(H[(i+5) AND 7], 3)
    ;     H[i] = H[i] * 0x85EBCA6B
    mov roundCount, 4

roundLoop:
    xor ecx, ecx
finalLaneLoop:
    cmp ecx, 8
    jge roundNext

    mov lane, ecx

    ; next1 = (i + 1) AND 7
    mov eax, ecx
    inc eax
    and eax, 7
    mov eax, H[eax*4]
    rol eax, 7
    mov t1, eax

    ; next2 = (i + 5) AND 7
    mov eax, ecx
    add eax, 5
    and eax, 7
    mov eax, H[eax*4]
    ror eax, 3
    mov t2, eax

    mov ecx, lane
    mov eax, H[ecx*4]
    add eax, t1
    xor eax, t2
    mov edx, 85EBCA6Bh
    imul eax, edx
    mov H[ecx*4], eax

    inc ecx
    jmp finalLaneLoop

roundNext:
    dec roundCount
    jnz roundLoop

    ; Copy 8 DWORDs to output
    mov edi, pOut32
    test edi, edi
    jz doneHash
    lea esi, H
    mov ecx, 8
copyHLane:
    mov eax, [esi]
    mov [edi], eax
    add esi, 4
    add edi, 4
    dec ecx
    jnz copyHLane

doneHash:
    xor eax, eax
    ret
SvHash256 ENDP

; ------------------------------------------------------------------------------
; SvFnv32: Computes FNV-1a 32-bit checksum
; Inputs:  pData (DWORD ptr), nLen (DWORD)
; Outputs: EAX = 32-bit checksum
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
SvFnv32 PROC USES ebx esi edi pData:DWORD, nLen:DWORD
    mov eax, 811C9DC5h  ; FNV offset basis
    mov esi, pData
    mov ecx, nLen
    test esi, esi
    jz fnvDone
    test ecx, ecx
    jz fnvDone

fnvLoop:
    movzx edx, BYTE PTR [esi]
    xor eax, edx
    imul eax, 01000193h ; FNV prime
    inc esi
    dec ecx
    jnz fnvLoop

fnvDone:
    ret
SvFnv32 ENDP

; ------------------------------------------------------------------------------
; SvWipe: Securely zeros memory buffer
; Inputs:  pBuf (DWORD ptr), nLen (DWORD)
; Outputs: EAX = 0 (SV_OK)
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
SvWipe PROC USES ebx esi edi pBuf:DWORD, nLen:DWORD
    mov edi, pBuf
    mov ecx, nLen
    test edi, edi
    jz wipeDone
    test ecx, ecx
    jz wipeDone

    xor eax, eax
    rep stosb

wipeDone:
    mov eax, SV_OK
    ret
SvWipe ENDP

; ------------------------------------------------------------------------------
; SvRandom: Fills buffer with pseudo-random bytes using rdtsc xorshift + SvHash256
; Inputs:  pBuf (DWORD ptr), nLen (DWORD)
; Outputs: EAX = 0 (SV_OK)
; Preserved: EBX, ESI, EDI
; Clobbered: ECX, EDX
; ------------------------------------------------------------------------------
SvRandom PROC USES ebx esi edi pBuf:DWORD, nLen:DWORD
    LOCAL rawBlock[32]:BYTE
    LOCAL hashBlock[32]:BYTE
    LOCAL state:DWORD
    LOCAL bytesLeft:DWORD
    LOCAL pDest:DWORD

    mov eax, pBuf
    mov pDest, eax
    mov eax, nLen
    mov bytesLeft, eax

randOuter:
    cmp bytesLeft, 0
    jle randSuccess

    ; Seed xorshift32 from rdtsc (low XOR high, forced odd)
    rdtsc
    xor eax, edx
    or eax, 1           ; Force odd
    mov state, eax

    ; Generate 8 DWORDs (32 bytes) with xorshift32
    lea edi, rawBlock
    xor ecx, ecx
genDwords:
    cmp ecx, 8
    jge doHashBlock

    ; x ^= x << 13
    mov eax, state
    mov edx, eax
    shl edx, 13
    xor eax, edx

    ; x ^= x >> 17
    mov edx, eax
    shr edx, 17
    xor eax, edx

    ; x ^= x << 5
    mov edx, eax
    shl edx, 5
    xor eax, edx

    mov state, eax
    mov [edi + ecx*4], eax
    inc ecx
    jmp genDwords

doHashBlock:
    ; Run raw block through SvHash256
    invoke SvHash256, addr rawBlock, 32, addr hashBlock

    ; Copy up to 32 bytes to destination
    mov ecx, bytesLeft
    .IF ecx > 32
        mov ecx, 32
    .ENDIF

    lea esi, hashBlock
    mov edi, pDest
    push ecx
    rep movsb
    pop ecx

    add pDest, ecx
    sub bytesLeft, ecx
    jmp randOuter

randSuccess:
    ; Wipe temporary buffers
    invoke SvWipe, addr rawBlock, 32
    invoke SvWipe, addr hashBlock, 32
    mov eax, SV_OK
    ret
SvRandom ENDP

; ------------------------------------------------------------------------------
; SvDeriveKeys: Derives Verifier and KEK from Salt and Password
; Inputs:  pSalt (DWORD ptr), pPass (DWORD ptr), passLen (DWORD),
;          pVerifierOut (DWORD ptr), pKekOut (DWORD ptr)
; Outputs: EAX = 0 (SV_OK)
; Preserved: EBX, ESI, EDI
; Clobbered: EAX, ECX, EDX
; ------------------------------------------------------------------------------
SvDeriveKeys PROC USES ebx esi edi pSalt:DWORD, pPass:DWORD, passLen:DWORD, pVerifierOut:DWORD, pKekOut:DWORD
    LOCAL scratch[128]:BYTE
    LOCAL totalLen:DWORD

    ; Buffer layout: 4 bytes prefix ("AUTH" or "WRAP") + 16 bytes Salt + passLen bytes Pass
    ; Check passLen <= 64
    mov ecx, passLen
    cmp ecx, 64
    ja deriveErr

    ; Total length = 4 + 16 + passLen = 20 + passLen
    add ecx, 20
    mov totalLen, ecx

    ; 1. Derive Verifier: "AUTH" || Salt || Pass
    mov DWORD PTR [scratch], 48545541h  ; "AUTH" in little-endian ('A'=41, 'U'=55, 'T'=54, 'H'=48)
    lea edi, scratch[4]
    mov esi, pSalt
    mov ecx, 16
    rep movsb

    .IF passLen > 0
        mov esi, pPass
        mov ecx, passLen
        rep movsb
    .ENDIF

    .IF pVerifierOut != 0
        invoke SvHash256, addr scratch, totalLen, pVerifierOut
    .ENDIF

    ; 2. Derive KEK: "WRAP" || Salt || Pass
    mov DWORD PTR [scratch], 50415257h  ; "WRAP" in little-endian ('W'=57, 'R'=52, 'A'=41, 'P'=50)
    lea edi, scratch[4]
    mov esi, pSalt
    mov ecx, 16
    rep movsb

    .IF passLen > 0
        mov esi, pPass
        mov ecx, passLen
        rep movsb
    .ENDIF

    .IF pKekOut != 0
        invoke SvHash256, addr scratch, totalLen, pKekOut
    .ENDIF

    ; Wipe sensitive scratch memory
    invoke SvWipe, addr scratch, 128
    mov eax, SV_OK
    ret

deriveErr:
    mov eax, SV_ERR_INPUT
    ret
SvDeriveKeys ENDP

; ------------------------------------------------------------------------------
; SvWrapDek: Wraps DEK with KEK via 32-byte XOR
; Inputs:  pDek (DWORD ptr), pKek (DWORD ptr), pOut (DWORD ptr)
; Outputs: EAX = 0 (SV_OK)
; Preserved: EBX, ESI, EDI
; Clobbered: EAX, ECX, EDX
; ------------------------------------------------------------------------------
SvWrapDek PROC USES ebx esi edi pDek:DWORD, pKek:DWORD, pOut:DWORD
    mov esi, pDek
    mov ebx, pKek
    mov edi, pOut
    xor ecx, ecx

xorWrapLoop:
    cmp ecx, 8          ; 8 DWORDs = 32 bytes
    jge wrapDone
    mov eax, [esi + ecx*4]
    xor eax, [ebx + ecx*4]
    mov [edi + ecx*4], eax
    inc ecx
    jmp xorWrapLoop

wrapDone:
    mov eax, SV_OK
    ret
SvWrapDek ENDP

; ------------------------------------------------------------------------------
; SvUnwrapDek: Unwraps DEK with KEK via 32-byte XOR
; Inputs:  pWrapped (DWORD ptr), pKek (DWORD ptr), pDekOut (DWORD ptr)
; Outputs: EAX = 0 (SV_OK)
; Preserved: EBX, ESI, EDI
; Clobbered: EAX, ECX, EDX
; ------------------------------------------------------------------------------
SvUnwrapDek PROC USES ebx esi edi pWrapped:DWORD, pKek:DWORD, pDekOut:DWORD
    mov esi, pWrapped
    mov ebx, pKek
    mov edi, pDekOut
    xor ecx, ecx

xorUnwrapLoop:
    cmp ecx, 8
    jge unwrapDone
    mov eax, [esi + ecx*4]
    xor eax, [ebx + ecx*4]
    mov [edi + ecx*4], eax
    inc ecx
    jmp xorUnwrapLoop

unwrapDone:
    mov eax, SV_OK
    ret
SvUnwrapDek ENDP

; ------------------------------------------------------------------------------
; SvCipher: In-place symmetric 2-pass stream cipher (SPEC section 5)
; Inputs:  pBuf (DWORD ptr), nLen (DWORD), pDek (DWORD ptr), nonce (DWORD), bEncrypt (DWORD)
; Outputs: EAX = 0 (SV_OK)
; Preserved: EBX, ESI, EDI
; Clobbered: EAX, ECX, EDX
; ------------------------------------------------------------------------------
SvCipher PROC USES ebx esi edi pBuf:DWORD, nLen:DWORD, pDek:DWORD, nonce:DWORD, bEncrypt:DWORD
    LOCAL seedInput[36]:BYTE
    LOCAL seedBlock[32]:BYTE
    LOCAL passNum:DWORD
    LOCAL prevCipher:BYTE
    LOCAL curByte:BYTE
    LOCAL ksByte:BYTE
    LOCAL rotAmt:BYTE
    LOCAL dekByte:BYTE
    LOCAL idx:DWORD

    mov eax, pBuf
    test eax, eax
    jz cipherDone
    mov eax, nLen
    test eax, eax
    jz cipherDone

    ; 1. seedBlock = SvHash256(DEK || Nonce)
    lea edi, seedInput
    mov esi, pDek
    mov ecx, 32
    rep movsb

    mov eax, nonce
    mov DWORD PTR seedInput[32], eax

    invoke SvHash256, addr seedInput, 36, addr seedBlock
    invoke SvWipe, addr seedInput, 36

    .IF bEncrypt != 0
        ; --- ENCRYPT: Pass 0 then Pass 1 ---
        mov passNum, 0
encPassLoop:
        cmp passNum, 2
        jge cipherSuccess

        ; LCG state = seedBlock.dword[passNum]
        mov eax, passNum
        lea esi, seedBlock
        mov ebx, [esi + eax*4]

        mov prevCipher, 0
        mov idx, 0

encByteLoop:
        mov eax, idx
        cmp eax, nLen
        jge encPassNext

        ; state = state * 1664525 + 1013904223
        mov eax, ebx
        mov edx, 0019660Dh
        imul eax, edx
        add eax, 3C6EF35Fh
        mov ebx, eax

        ; ks = state >> 16
        shr eax, 16
        mov dl, al
        mov ksByte, dl          ; ks AND 0FFh
        shr eax, 8
        and al, 7
        mov rotAmt, al          ; (ks >> 8) AND 7

        ; dekByte = DEK[idx MOD 32]
        mov eax, idx
        and eax, 31
        mov esi, pDek
        mov al, [esi + eax]
        mov dekByte, al

        ; plain = pBuf[idx]
        mov esi, pBuf
        add esi, idx
        mov al, [esi]

        ; t = plain XOR ksByte
        xor al, ksByte

        ; t = ROL(t, rotAmt)
        mov cl, rotAmt
        rol al, cl

        ; t = t + dekByte + prevCipher
        add al, dekByte
        add al, prevCipher

        ; pBuf[idx] = t
        mov [esi], al
        mov prevCipher, al

        inc idx
        jmp encByteLoop

encPassNext:
        inc passNum
        jmp encPassLoop

    .ELSE
        ; --- DECRYPT: Pass 1 then Pass 0 ---
        mov passNum, 1
decPassLoop:
        cmp passNum, 0
        jl cipherSuccess

        ; LCG state = seedBlock.dword[passNum]
        mov eax, passNum
        lea esi, seedBlock
        mov ebx, [esi + eax*4]

        mov prevCipher, 0
        mov idx, 0

decByteLoop:
        mov eax, idx
        cmp eax, nLen
        jge decPassNext

        ; state = state * 1664525 + 1013904223
        mov eax, ebx
        mov edx, 0019660Dh
        imul eax, edx
        add eax, 3C6EF35Fh
        mov ebx, eax

        ; ks = state >> 16
        shr eax, 16
        mov dl, al
        mov ksByte, dl          ; ks AND 0FFh
        shr eax, 8
        and al, 7
        mov rotAmt, al          ; (ks >> 8) AND 7

        ; dekByte = DEK[idx MOD 32]
        mov eax, idx
        and eax, 31
        mov esi, pDek
        mov al, [esi + eax]
        mov dekByte, al

        ; cipher = pBuf[idx]
        mov esi, pBuf
        add esi, idx
        mov al, [esi]
        mov curByte, al         ; saveCipher

        ; t = cipher - prevCipher - dekByte
        sub al, prevCipher
        sub al, dekByte

        ; t = ROR(t, rotAmt)
        mov cl, rotAmt
        ror al, cl

        ; plain = t XOR ksByte
        xor al, ksByte

        ; pBuf[idx] = plain
        mov [esi], al

        ; prevCipher = saveCipher
        mov al, curByte
        mov prevCipher, al

        inc idx
        jmp decByteLoop

decPassNext:
        dec passNum
        jmp decPassLoop

    .ENDIF

cipherSuccess:
    invoke SvWipe, addr seedBlock, 32
    mov eax, SV_OK
    ret

cipherDone:
    mov eax, SV_OK
    ret
SvCipher ENDP

END
