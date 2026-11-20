# SPEC.md — Complete Project Specification

## 1. Project Overview
- **Project Name:** StegoVault Bank
- **Core Purpose:** A native Win32 GUI banking application written entirely in 32-bit MASM. It stores no plaintext customer records. Each depositor's account record is encrypted and hidden in the least significant bits of a personal 24-bit BMP image (`Vault_Images\<username>.bmp`). Only that depositor (username + password + their own image) or the Cashier (Master Key) can open it.
- **Inputs:** keyboard text (credentials, form fields, amounts), image files (`.jpg`, `.jpeg`, `.png`, `.bmp`) chosen with `GetOpenFileNameA`.
- **Outputs:** 24-bit `.bmp` vault images in `Vault_Images\`, records appended/updated in `users.dat` and `requests.dat`, native Win32 screens, `OutputDebugStringA` traces.
- **Explicit Non-Goals:** no networking, no SQL or any database engine, no 64-bit build, no plaintext storage of account records or passwords, no C runtime, no real-money use. The ciphers and hash are custom educational constructions (section 5) and are not claimed to be production-grade.
- **Roles (exactly two):** Cashier (single hardcoded account `admin` / `admin123`, holds the Master Key) and Depositor (many accounts).

## 2. Functional Requirements & Behavior
1. **Startup:** Initialise GDI+ (`GdiplusStartup`), fonts, brushes. Ensure `Vault_Images\` exists (`CreateDirectoryA`, `ERROR_ALREADY_EXISTS` is fine), and that `users.dat` and `requests.dat` exist (`CreateFileA` with `OPEN_ALWAYS`, then close). Failure of any step shows a message box and exits.
2. **Screen 1 – Login:** two role tabs. *Depositor tab:* Username, Password (`ES_PASSWORD`), `[Browse My Vault Image...]` + read-only path box, `[Login to Vault]`, `[Register New Depositor Account]`. *Cashier tab:* Username, Password, `[Login as Cashier]`.
3. **Depositor login pipeline (stop at the first failure, wipe buffers on every exit):**
   1. All three inputs present, else "Enter username, password and select your vault image."
   2. Find the username (case-insensitive) in `users.dat`; compute `Verifier' = SvHash256("AUTH" || Salt || Password)`; compare with the stored verifier. Failure: "Invalid username or password." (one message for both causes).
   3. Load the BMP (`LoadVaultBmp`), check `SVLT` magic. Failure: "This file is not a StegoVault image."
   4. Compare the header's `UsernameHash` with `SvHash256(lowercase username)`. Mismatch: **"Unauthorized Image: This vault image does not belong to your account"**.
   5. `KEK = SvHash256("WRAP" || Salt || Password)`; unwrap the DEK; decrypt the record; verify the checksum. Failure: "Vault image is damaged or has been tampered with."
   6. Record `Username` must equal the typed username (case-insensitive), else the same Unauthorized Image error.
   7. Rollback guard: header `Nonce` must be `>= LastNonce` stored in the user's `users.dat` record, else "Stale vault image: an older copy of your image was supplied."
   8. Open the Depositor Dashboard.
4. **Cashier account setup (added in Task 6.3):** the Cashier tab has a `[Create Cashier Account]` button. If `cashier.dat` (80 bytes: Username[32], Salt[16], Verifier[32]) does not exist, it stores the typed username (3..31 of `[A-Za-z0-9_]`, `admin` allowed) and password (6..31) as a salted verifier; if it exists, creation is refused. Delete `cashier.dat` to reset. The Master Key used for vault images is unchanged.
4. **Cashier login (updated, Task 6.4):** only the account stored in `cashier.dat` can log in; there is no default `admin` account. The cashier sees the list and an image preview of every registered vault, but depositor data stays locked until the cashier inserts that depositor's vault image (Open Vault Image); a 1-second "Decrypting the data..." popup is shown, then data is displayed. Approve/Reject/manual adjustment then apply to that opened vault. Original rule: username and password compared byte-for-byte with the constants `admin` / `admin123`. Success opens the Cashier Dashboard; failure shows "Invalid cashier credentials." and clears the password box.
5. **Registration (Screen 2):** fields Full Name, Username, Password, Confirm Password, CNIC, Contact Number, Initial Deposit, Cover Image. Validation rules are in section 3. On `[Create Account & Encrypt Image]`:
   1. Validate every field. 2. Reject duplicate usernames (case-insensitive) and the reserved name `admin`.
   3. Account Number = `ACC-` + decimal (`1000 + (users.dat record count) + 1`), so the first account is `ACC-1001`.
   4. Convert the cover image to an in-memory 24-bit BMP with GDI+ (`LoadImageAsBmp`); check capacity `>= VAULT_STREAM_BYTES * 8` pixel bytes (section 6).
   5. Generate Salt (16 B), DEK (32 B) and Nonce = 1; build the record; encrypt; build the header; embed; write the BMP through the atomic-write routine to `Vault_Images\<username lowercase>.bmp`.
   6. Only after the BMP is on disk, append the user record to `users.dat` (with `LastNonce = 1`). If the append fails, delete the new BMP and report the error.
   7. Show the saved path, return to Login. The original cover image is never modified.
5. **Depositor Dashboard (Screen 3):** shows Account Number, Full Name, CNIC, Contact Number and Balance, all taken from the decrypted record held in memory since login. Transaction panel: radio buttons Deposit / Withdraw, Amount box, `[Submit Request to Cashier]` which appends a pending record (Status 0) to `requests.dat` and shows "Request #N submitted." A depositor may not submit a withdrawal larger than the balance currently shown. `[Logout]` wipes the record, keys and form fields and returns to Login. A `[Refresh Balance]` button re-reads the BMP from disk using the DEK still held in memory (so balance changes approved by the Cashier become visible without a new login).
7. **Cashier Dashboard (Screen 4):**
   - On login, scan `requests.dat`; if any Status 0 exists show `MessageBoxA` "N pending request(s) waiting." and fill the **Pending Requests** list box with lines `#<id>  <username>  <Deposit|Withdraw>  <amount>  <Pending|Approved|Rejected>` (all records are listed, pending first selectable).
   - **Registered Depositors** list box filled from `FindFirstFileA`/`FindNextFileA` on `Vault_Images\*.bmp`.
   - Selecting a depositor (list click, or `[Open Vault Image...]` file dialog) loads that BMP, unwraps the DEK with the Master Key, decrypts, verifies the checksum and shows Account Number, Name, Username, CNIC, Contact, Balance.
   - `[Approve Selected Request]`: loads the request's depositor image, applies the amount (deposit adds; withdrawal needs `balance >= amount`, else message box "Insufficient funds: request cannot be approved" and the request stays Pending), re-encrypts the record with `Nonce + 1`, rewrites the BMP atomically, updates `LastNonce` in `users.dat`, and only then sets the request Status to 1. `[Reject Request]` sets Status 2 and changes nothing else. A manual adjust (amount box + Deposit/Withdraw radio) uses the same routine without a request id.
   - `[Logout]` wipes buffers and returns to Login.

## 3. Edge Cases & Error Handling
| Case | Required behaviour |
|---|---|
| Depositor A with A's credentials selects B's image | Step 4 of the login pipeline fails with the Unauthorized Image message. No data from B's image is displayed. |
| Correct image, wrong password | Fails at verifier check (step 2) with the generic invalid message. |
| Image too small | Registration refuses: "Image too small: need at least 64 x 64 pixels." Capacity rule: `(pixelArrayBytes / 8) >= VAULT_STREAM_BYTES` (256 B, about 683 pixels); the UI additionally requires width and height >= 64. |
| JPG/PNG cover | Converted by GDI+ to 24 bpp; stored as BMP, never re-encoded lossily. |
| Non-BMP file or corrupt BMP | `ParseBmp` rejects: bad `BM` signature, DIB header < 40, bit count != 24, compression != 0, non-positive width/height, pixel offset outside file. |
| Pixel array shorter than header claims | Clamp to actual file end before computing capacity. |
| Overdraw | Withdrawal with `amount > balance` is rejected (message box); deposit that would overflow a DWORD is rejected. |
| Amount invalid | Digits only, 1..`MAX_TXN_AMOUNT` (100 000 000); empty, zero, signed or overflow rejected. |
| Duplicate username | "Username already registered." Comparison is case-insensitive. |
| Field validation | Name 1..63 printable chars. Username 3..31 of `[A-Za-z0-9_]`. Password 6..31 chars. CNIC exactly `ddddd-ddddddd-d` (15 chars). Contact 10..15 chars, digits, optional leading `+`. Initial deposit 0..`MAX_TXN_AMOUNT`. |
| Disk write failure mid-update | Atomic write: write `<name>.tmp`, flush, `MoveFileExA(tmp, final, MOVEFILE_REPLACE_EXISTING)`. On failure the old image stays intact and the request stays Pending. |
| Missing/zero-length `users.dat`/`requests.dat` | Treated as empty. A size that is not a multiple of the record size is reported as "Registry file is damaged" and no write is attempted. |
| Rolled-back image | Rejected by the `LastNonce` guard (login step 7). |
| Heap/GDI+ failure | Every `HeapAlloc` and GDI+ status is checked; the user sees "Out of memory." or "Could not decode the image."; all partial buffers are freed. |
| Two vault images with same username in different case | Filenames and lookups are normalised to lowercase. |

## 4. Data Models & Memory/State Layout

### 4.1 Vault stream embedded in the BMP (little-endian, 256 bytes = `VAULT_STREAM_BYTES`)
Bytes are written to the pixel array starting at the first byte of the pixel data (`bfOffBits`), most significant bit first, one bit per pixel byte (B, G, R, B, G, R, ...). Padding bytes at the end of rows are part of the linear byte stream (same rule as the existing StegoLock engine). Total pixel bytes consumed: `256 * 8 = 2048`.

| Offset | Size | Field |
|---|---|---|
| `+0x00` | 4 | `Magic` = `"SVLT"` (`0x544C5653`) |
| `+0x04` | 32 | `UserWrappedDEK` = `DEK XOR KEK_user` |
| `+0x24` | 32 | `CashierWrappedDEK` = `DEK XOR KEK_cashier` |
| `+0x44` | 4 | `Checksum` = `Fnv32(plaintext record) XOR DEK[0..3]` |
| `+0x48` | 32 | `UsernameHash` = `SvHash256(lowercase username)` |
| `+0x68` | 4 | `Nonce` (DWORD, starts at 1, +1 on every rewrite) |
| `+0x6C` | 148 | `EncryptedRecord` |

Deliberate deviation from the first draft: the 4-byte `Nonce` field was added at `+0x68`, pushing the payload to `+0x6C`. Without it every rewrite would reuse the same keystream, and an observer holding two versions of an image could XOR them to learn the plaintext difference. Header = 108 bytes (`VAULT_HDR_SIZE`), record = 148 bytes (`ACC_REC_SIZE`).

### 4.2 Account record (plaintext layout, 148 bytes, zero-padded strings)
| Offset | Size | Field |
|---|---|---|
| `+0x00` | 16 | Account Number, e.g. `ACC-1001\0` |
| `+0x10` | 64 | Full Name |
| `+0x50` | 32 | Username (stored as typed at registration) |
| `+0x70` | 16 | CNIC, e.g. `42101-1234567-1\0` |
| `+0x80` | 16 | Contact Number |
| `+0x90` | 4 | Balance (DWORD, whole currency units) |

### 4.3 `users.dat` (fixed 96-byte records, no file header; record count = file size / 96)
| Offset | Size | Field |
|---|---|---|
| `+0x00` | 32 | Username (lowercase, NUL padded) |
| `+0x20` | 16 | Salt (random) |
| `+0x30` | 32 | Verifier = `SvHash256("AUTH" || Salt || Password)` |
| `+0x50` | 4 | LastNonce (DWORD) |
| `+0x54` | 12 | Reserved (zero) |

### 4.4 `requests.dat` (fixed 64-byte records, no file header; request id = record index + 1)
| Offset | Size | Field |
|---|---|---|
| `+0x00` | 32 | Username (lowercase) |
| `+0x20` | 16 | Account Number |
| `+0x30` | 4 | RequestType (1 = Deposit, 2 = Withdraw) |
| `+0x34` | 4 | Amount |
| `+0x38` | 4 | Status (0 Pending, 1 Approved, 2 Rejected) |
| `+0x3C` | 4 | Reserved |
A status change is a single `SetFilePointer` to `index * 64 + 0x38` followed by a 4-byte `WriteFile`.

### 4.5 Runtime state (`.data?`)
`hInst`, `hMain`, `curScreen`, `curRole`, `gdipToken`, brush and font handles, control-handle table (section 8), `sessUser[32]`, `sessSalt[16]`, `sessDEK[32]`, `sessRecord[148]`, `sessNonce`, `sessIsCashier`, `imgPtr`, `imgSize`, `pixOff`, `imgW`, `imgH`, `pixBytes`. Heap blocks hold whole BMP images (maximum accepted size 64 MB).

## 5. Cryptography Specification (`crypto.asm`)
- **SvHash256 (educational 256-bit hash):** state `H[0..7]`, `H[i] = 0x811C9DC5 XOR (i * 0x9E3779B9)`. For every input byte `b`, for lane `i` in 0..7: `H[i] = (H[i] XOR b) * 0x01000193`, then `H[i] = ROL(H[i], (i XOR 5) + 1)`. Finalise with 4 rounds: for `i` in 0..7, `H[i] = (H[i] + ROL(H[(i+1) AND 7], 7)) XOR ROR(H[(i+5) AND 7], 3)`, then `H[i] = H[i] * 0x85EBCA6B`. Output the eight DWORDs little-endian (32 bytes). Input is passed as a pointer and length; multi-part inputs are concatenated in a scratch buffer.
- **Key derivation:** `Verifier = SvHash256("AUTH" || Salt || Password)`; `KEK_user = SvHash256("WRAP" || Salt || Password)`; `KEK_cashier = SvHash256("WRAP" || MasterKey)` with `MasterKey` = constant string `SV-MASTER-KEY-2026`. Different prefixes keep the stored verifier from revealing the KEK.
- **DEK generation:** 32 bytes from a xorshift32 PRNG seeded with `rdtsc` (low XOR high, forced odd), re-seeded and run through SvHash256 per 32-byte block. Salt uses the same generator.
- **SvCipher (symmetric stream cipher, 2 passes, in place):** `seedBlock = SvHash256(DEK || Nonce)`. Pass `p` (0, 1) starts a 32-bit LCG state at `seedBlock.dword[p]`. For each byte at index `i`: `state = state * 1664525 + 1013904223`; `ks = state >> 16`. **Encrypt:** `t = plain XOR (ks AND 0FFh)`; `t = ROL(t, (ks >> 8) AND 7)`; `t = t + DEK[i MOD 32] + prevCipher` (mod 256); `prevCipher = t`. **Decrypt (inverse):** `t = cipher - prevCipher - DEK[i MOD 32]`; `t = ROR(t, (ks >> 8) AND 7)`; `plain = t XOR (ks AND 0FFh)`; `prevCipher = cipher`. Decryption applies pass 1 then pass 0.
- **Checksum:** FNV-1a 32 over the plaintext record. Stored XORed with `DEK[0..3]`.
- **Wipe:** `SvWipe(ptr, len)` fills with zero using `rep stosb`; called on every exit path that handled secrets.

## 6. Steganography Specification (`stego.asm`)
- **Image loading:** `LoadImageAsBmp(path, pSizeOut)` converts any GDI+ readable image to a heap-allocated 24-bit BMP file image (54-byte header, bottom-up rows padded to 4 bytes, rows copied with `Stride`, zero-filled padding). Size limit: width and height each <= 20 000 and total <= 64 MB. For `.bmp` inputs the same conversion is used so every vault image is a canonical 24-bit file.
- **Parsing:** `ParseBmp` validates as in section 3, computes `stride = (W*3 + 3) AND NOT 3`, `pixBytes = min(stride * H, fileSize - bfOffBits)`, `capacity = pixBytes / 8`.
- **Embed:** `EmbedBytes(pPix, pData, count)`: for each data byte, 8 pixel bytes: `px = (px AND 0FEh)`, `shl al,1`, `adc px,0`. **Extract:** `ExtractBytes(pPix, pDest, count)`: `and px,1`, `shl al,1`, `or al,px`. Only pixel bytes change; the 54-byte header is untouched, so the file stays a valid viewable BMP.
- **`ReadVaultStream(imgPtr)`** extracts `VAULT_STREAM_BYTES` into a 256-byte buffer. **`WriteVaultStream(imgPtr, stream)`** embeds it. A vault file always contains exactly one stream at the start of the pixel array.

## 7. File I/O Specification (`fileio.asm`)
All wrappers return `EAX = 0` success, else `SV_ERR_*`.
- `InitStorage`: create `Vault_Images`, create-if-missing `users.dat`, `requests.dat`.
- `ReadWholeFile(path, pSize)` / `WriteWholeFile(path, buf, n)` using `CreateFileA`, `GetFileSizeEx`, `ReadFile`, `WriteFile`, `CloseHandle`; reject files over 64 MB.
- `AtomicWriteFile(path, buf, n)`: write `path + ".tmp"`, `FlushFileBuffers`, `MoveFileExA(..., MOVEFILE_REPLACE_EXISTING)`.
- `UsersFind(name, pRecord)`, `UsersAppend(pRecord)`, `UsersSetNonce(name, nonce)` (`SetFilePointer` + `WriteFile`), `UsersCount()`.
- `ReqAppend(pRecord)`, `ReqReadAll(pBuf, pCount)`, `ReqSetStatus(index, status)`, `ReqCountPending()`.
- `ScanVault(callback)` using `FindFirstFileA("Vault_Images\*.bmp")`, `FindNextFileA`, `FindClose`.
- `SetEndOfFile` is used when a record file must be truncated after a failed append (restore the previous size).

## 8. GUI Specification (`gui.asm`, `main.asm`)
- One top-level window, resizable window with a 960 x 640 minimum client size (`WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_THICKFRAME | WS_CLIPCHILDREN`); the 960 x 640 content block is re-centred on `WM_SIZE`, and double-clicking the title bar maximises/restores, class `StegoVaultWnd`. Four screens are groups of child controls created once at `WM_CREATE`; `ShowScreen(n)` hides all other groups with `ShowWindow`.
- Header band 0..72 px painted in `WM_PAINT` with the navy brush: title "StegoVault Bank" (Segoe UI -22 bold, white) and the screen name. Canvas `0x00F4F6F9`.
- Buttons are `BS_OWNERDRAW` (steel fill, darker when pressed, white text); edit controls have `WS_BORDER`; colours come from `WM_CTLCOLORSTATIC` / `WM_CTLCOLOREDIT` / `WM_DRAWITEM`.
- Control ID ranges: Login 1000-1099, Register 1100-1199, Depositor 1200-1299, Cashier 1300-1399; every ID is an EQU in `constants.inc`.
- Status line at the bottom of each screen (static) shows success/error text in the success/error colours.
- Radio buttons use `BS_AUTORADIOBUTTON` with `WS_GROUP`; list boxes use `LBS_NOTIFY | WS_VSCROLL`.

## 9. Module Breakdown & Contracts
- **`main.asm`** — `start` (entry): `GetModuleHandleA`, `WinMain`, `ExitProcess`. `WndProc`, `ShowScreen`, command dispatch.
- **`gui.asm`** — `BuildScreens`, `DrawOwnerItem`, `SetStatus(screen, text, isError)`, field validators (`ValidateUsername`, `ValidateCnic`, ...), `AtoiDec(str) -> eax=value, edx=0 ok / 1 invalid`, `ItoaDec(value, buf)`.
- **`crypto.asm`**
  - `SvHash256(pData, nLen, pOut32)`: preserves EBX/ESI/EDI; clobbers EAX/ECX/EDX; `EAX = 0`.
  - `SvDeriveKeys(pSalt, pPass, passLen, pVerifierOut, pKekOut)`.
  - `SvCipher(pBuf, nLen, pDek, nonce, bEncrypt)`: in place; internal loop contract `ESI = buffer cursor`, `EDI = bytes left`, `EBX = LCG state`, `DL = prevCipher`.
  - `SvWrapDek(pDek, pKek, pOut)` / `SvUnwrapDek(pWrapped, pKek, pDekOut)` (32-byte XOR).
  - `SvRandom(pBuf, nLen)`, `SvFnv32(pData, nLen) -> EAX`, `SvWipe(pBuf, nLen)`.
- **`stego.asm`** — `LoadImageAsBmp`, `ParseBmp`, `EmbedBytes`, `ExtractBytes`, `ReadVaultStream`, `WriteVaultStream`, `BuildVaultImage(pCover, pRecord, pDek, nonce, ...)`, `OpenVaultImage(path, ...)`.
- **`fileio.asm`** — section 7.

## 10. Constants & Error Codes (`constants.inc`)
`VAULT_HDR_SIZE=108`, `ACC_REC_SIZE=148`, `VAULT_STREAM_BYTES=256`, `USER_REC_SIZE=96`, `REQ_REC_SIZE=64`, `DEK_SIZE=32`, `SALT_SIZE=16`, `MAX_FILE_BYTES=4000000h`, `MAX_TXN_AMOUNT=100000000`, `MIN_IMG_DIM=64`. Errors: `SV_OK=0`, `SV_ERR_IO=1`, `SV_ERR_MEM=2`, `SV_ERR_BMP=3`, `SV_ERR_CAPACITY=4`, `SV_ERR_MAGIC=5`, `SV_ERR_NOT_OWNER=6`, `SV_ERR_CHECKSUM=7`, `SV_ERR_AUTH=8`, `SV_ERR_EXISTS=9`, `SV_ERR_FUNDS=10`, `SV_ERR_INPUT=11`, `SV_ERR_STALE=12`, `SV_ERR_GDIP=13`.

## 11. Known Limitations (state them honestly in the viva)
- Hash, wrapping and stream cipher are custom teaching constructions, not vetted cryptography. Do not use for real money.
- The Master Key and the `admin` / `admin123` credentials are compiled into the executable by requirement, so anyone who disassembles the program can recover them.
- The `LastNonce` guard stops a depositor restoring an old image only while `users.dat` is not also rolled back.
- LSB data does not survive JPEG/PNG re-saving or resizing; vault images must stay BMP.

## 12. Acceptance Tests (used by Phase 5)
1. Register `alice`, `bob`; hex-dump `alice.bmp`: bytes 0x00..0x35 identical to a fresh conversion, only LSBs differ after the offset.
2. Alice logs in with her own image and sees her record and balance.
3. Alice logs in with Bob's image: exact Unauthorized Image message.
4. Alice submits Withdraw larger than her balance: depositor-side rejection. Alice submits Deposit 5000: `requests.dat` gains one 64-byte record with Status 0.
5. Cashier login shows the pending alert, approves the deposit; alice's `Nonce` increases by 1, her balance increases by 5000, the request Status becomes 1.
6. Copy `alice.bmp` before step 5 and restore it afterwards: login fails with the stale image message.
7. Flip one LSB in the header region with a hex editor: login fails with the damaged/tampered message.
8. Cashier approves a withdrawal larger than the stored balance: rejection message box, request remains Pending.


## UI Theme and Cashier Flow (Task 6.8)
- Palette: graphite header (#18232E to #22313F) with brass rule (#B8935A), ivory canvas/cards (#F5F2EB), slate buttons (#2F3E4D), brass primary buttons. Wordmark in Georgia bold; body in Segoe UI.
- All error messages (SetStatus isError=1) and former MessageBoxA calls are shown in a themed modal popup centred over the main window (ThemedDialog); Esc closes, Enter presses the focused button.
- Cashier: pending requests always visible. After the depositor's own vault image is inserted and verified, a popup offers View details / Update balance / Close. View shows only the personal-details card; Update shows only the deposit/withdraw box. Selecting the already-unlocked account again re-opens the popup.


## 13. Approve flow (Build 6.10)
`[Approve Selected Request]` NEVER changes a balance. It requires the matching vault to be open, sets the request Status to 1 (Approved), then shows a themed popup "Deposit / Withdraw / Close". Choosing Deposit or Withdraw reveals the Balance-update panel with that radio pre-selected; the cashier types the amount and presses `[Apply Adjustment]` (manual adjustment routine, Nonce + 1). The manual box is hidden until then.

## 14. Splash and footer (Build 6.11)
On start the app shows a full-screen black splash (class StegoVaultSplash, 30 ms timer, 108 frames) with an animated vault-wheel/keyhole logo framed by viewfinder brackets, then the main window opens. Footer bar (26 px) at the bottom of the main window shows the tagline and session state.

## 15. Interactive UI (Build 6.12)
Hover glow on owner-draw buttons, animated header rule, rotating vault dial, blinking status lights, live password-strength meter (Weak/Fair/Good/Strong, 4 segments) on registration, and a vault-card graphic on the depositor dashboard.

## 16. Theme (Build 6.13)
Dark obsidian surfaces with a teal accent replace the ivory/brass palette; token names in constants.inc are unchanged. Main window paints through a back buffer.

## 17. Request notifications and input masks (Build 6.16)
requests.dat `Reserved` (+0x3C) = 1 once the depositor has been told the outcome. Registration: CNIC auto-formats as ddddd-ddddddd-d; phone accepts digits only, at most 11.
