# PLAN.md — Phased Implementation Plan

Rule: one task at a time. A task is done only when its **Verify** line passes. Mark `[x]` and log it in `PROGRESS.md` before starting the next.

## Phase 1: Workspace, Build Pipeline & Minimal Skeleton
- [x] **1.1** Create `constants.inc`, `structs.inc`, `protos.inc` (every EQU from SPEC section 10, window styles, colours, control IDs, struct layouts) and the five modules `main.asm`, `gui.asm`, `crypto.asm`, `stego.asm`, `fileio.asm` as compilable stubs, plus `build.bat`. **Verify:** `build.bat` assembles all five files with 0 errors; link may fail only for the missing entry point.
- [x] **1.2** Implement `start`, the main window class, `WndProc`, message loop and `WM_DESTROY`. Fixed 960 x 640 window titled "StegoVault Bank". **Verify:** `main.exe` opens, closes cleanly, exit code 0, no leaked handles in a quick run.
- [x] **1.3** Fonts (Segoe UI body -14, header -22 bold), brushes for the banking palette, header band in `WM_PAINT`, `WM_CTLCOLORSTATIC` / `WM_CTLCOLOREDIT` / owner-draw button routine. **Verify:** a test static, edit and button show navy header, off-white canvas, white input, steel button; pressing the button visibly darkens it.
- [x] **1.4** Screen switching framework: control-group table, `ShowScreen(n)`, status line helper `SetStatus`. **Verify:** a temporary key or button cycles through four empty screens; only the active screen's controls are visible.

## Phase 2: File I/O & Core Data Management
- [x] **2.1** `InitStorage`: create `Vault_Images\`, `users.dat`, `requests.dat` if missing; `ReadWholeFile`, `WriteWholeFile`, `AtomicWriteFile` with full error checks. **Verify:** first run creates the three items; second run changes nothing; writing a 10 KB test buffer then reading it back is byte-identical; `.tmp` file never remains.
- [x] **2.2** `users.dat`: `UsersCount`, `UsersFind` (case-insensitive), `UsersAppend`, `UsersSetNonce`, damaged-size detection. **Verify:** append two fake records, find each by mixed-case name, update a nonce, hex-check offsets `+0x00`, `+0x50`; a 100-byte file is reported as damaged.
- [x] **2.3** `requests.dat`: `ReqAppend`, `ReqReadAll`, `ReqSetStatus`, `ReqCountPending`. **Verify:** three appended requests give 192 bytes; changing the second to Status 1 modifies only the 4 bytes at `0x78`; pending count updates.
- [x] **2.4** Numeric helpers `AtoiDec` / `ItoaDec` and field validators (username, password, CNIC, contact, amount). **Verify:** table of accept/reject inputs from SPEC section 3 (empty, `0`, `-5`, `99999999999`, `12a`, `100000000`, `100000001`) all behave as specified.

## Phase 3: Cryptography & Steganography Engine
- [x] **3.1** `SvHash256`, `SvFnv32`, `SvWipe`, `SvRandom` (rdtsc xorshift). **Verify:** hashing `"abc"` twice gives equal output; changing one input bit changes at least 100 of 256 output bits (temporary debug check); two `SvRandom` calls differ.
- [x] **3.2** `SvDeriveKeys`, `SvWrapDek` / `SvUnwrapDek`, `SvCipher` encrypt/decrypt. **Verify:** encrypt then decrypt a 148-byte record round-trips; wrong DEK gives a failing checksum; different nonce gives different ciphertext for the same plaintext.
- [x] **3.3** `LoadImageAsBmp` (GDI+ startup/shutdown, `GdipCreateBitmapFromFile`, `GdipBitmapLockBits`, bottom-up row copy, status checks) and `ParseBmp`. **Verify:** one JPG, one PNG and one BMP convert; resulting buffers parse with correct width/height/capacity; a text file renamed `.png` is rejected with "Could not decode the image."; a 32 x 32 image is rejected as too small.
- [x] **3.4** `EmbedBytes`, `ExtractBytes`, `ReadVaultStream`, `WriteVaultStream`. **Verify:** embed 256 known bytes, save with `WriteWholeFile`, hex-check that bytes 0..53 equal the source header and that only bit 0 of the following bytes changed; extract returns the same 256 bytes.
- [x] **3.5** `BuildVaultImage` and `OpenVaultImage` (header assembly, wrap both DEKs, checksum, username hash, nonce, record encrypt/decrypt, all failure codes). **Verify:** a build-then-open round trip from a test harness returns the original record for both the user path and the cashier path; each of these fails with its own code: wrong password, wrong username hash, flipped header bit, wrong magic.

## Phase 4: GUI Screens & User Workflows
- [x] **4.1** Screen 1: role tabs, depositor fields, image browse (`GetOpenFileNameA`), cashier fields, status line. **Verify:** switching tabs swaps field sets; password boxes mask text; browse fills the read-only path box.
- [x] **4.2** Screen 2 (registration) and the full register pipeline (validation, unique username, account number, GDI+ convert, build vault image, atomic write to `Vault_Images\<user>.bmp`, append to `users.dat`, rollback on failure). **Verify:** registering `alice` creates `alice.bmp` (viewable in Windows Photos) and one 96-byte `users.dat` record `ACC-1001` once decrypted later; duplicate `Alice` is refused; the chosen cover file is unchanged.
- [x] **4.3** Depositor login pipeline (SPEC section 2 steps 1-8) and Screen 3 dashboard (details, balance display, `[Refresh Balance]`, logout wipe). **Verify:** acceptance tests 2 and 3; after logout the session buffers are zero (checked in the debugger memory window).
- [x] **4.4** Depositor transaction requests: radio selector, amount validation, withdrawal-over-balance guard, `ReqAppend`. **Verify:** acceptance test 4; request id is shown; record offsets match SPEC 4.4.
- [x] **4.5** Screen 4 cashier: hardcoded login, pending alert, requests list box, depositor list (`FindFirstFileA`), open image with Master Key, details display. **Verify:** alert text shows the correct pending count; both lists populate; selecting `alice` shows her record.
- [x] **4.6** Cashier approve / reject / manual adjust with nonce increment, atomic BMP rewrite, `UsersSetNonce`, then `ReqSetStatus`. **Verify:** acceptance tests 5 and 8; killing the process between the BMP write and the status write leaves a consistent state (request still Pending, image valid).

## Phase 5: Hardening & End-to-End Testing
- [x] **5.1** Cross-account validation, rollback guard and tamper detection exercised end to end. **Verify:** acceptance tests 3, 6 and 7 pass with the exact messages from SPEC.
- [x] **5.2** Resource audit: every `CreateFileA` / `FindFirstFileA` / `HeapAlloc` / GDI+ image has a matching release on all exit paths; secrets wiped on every exit; run 50 login/logout cycles and watch handle and private-bytes counts stay flat. **Verify:** Task Manager / Process Explorer counts flat; no failure paths skip cleanup (code review checklist in `PROGRESS.md`).
- [x] **5.3** Full manual transaction loop with three depositors, mixed deposits/withdrawals/rejections, repeated restarts of the program. **Verify:** balances in each image match a hand-calculated ledger after every step; `requests.dat` statuses are correct.
- [x] **5.4** Demo and viva pack: final `build.bat` from a clean folder, a sample vault set, a one-page architecture summary derived from `SPEC.md`. **Verify:** clean build with 0 errors; demo script (register, login, cross-account failure, request, approve, tamper failure) runs start to finish without a crash.

## Phase 6: Post-Delivery Bug Fixes
- [x] **6.1** Fix control-handle loss in `BuildScreens` (70 labels/edits/statics registered with `EAX` clobbered by `SendMessageA`), garbled header subtitles, `&` mnemonic in owner-draw button text, resizable/maximisable window with re-centring, removal of F1-F4 debug screen switching, edit length limits. **Verify:** `build.bat` 0 errors; register `Full Name` under 63 chars succeeds and returns to Login; Cashier tab shows only cashier controls; window maximises on title-bar double-click.
- [x] **6.2** `users.dat` repair prompt and diagnostics; tolerant file sharing.
- [x] **6.3** Cashier account creation (`cashier.dat`, `Create Cashier Account` button).
- [x] **6.4** Cashier locked-vault workflow: preview, decrypt popup, no default admin, cover downscale, overlap fix. **Verify:** rebuild; register a depositor with a large JPG (no freeze); cashier login shows "(locked)" data; Open Vault Image shows the 1 s popup then data; approve needs the matching image.
- [x] **6.6** Remove default sample accounts/data; fix ODT_STATIC (5) so vault preview box draws; specific cashier open-image errors with code. **Verify:** rebuild; run `reset_data.bat`; fresh register -> cashier insert image.
- [x] **6.7** Vault dialogs BMP-only; specific cashier open errors with code.
- [x] **6.8** GUI redesign + themed popups + cashier details/update chooser. **Verify:** rebuild; login as cashier; unlock a vault image -> choose popup -> only chosen panel shows; trigger a wrong login -> centred popup.

