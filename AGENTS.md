# AGENTS.md — Project Rules & Constraints

## 1. Target Environment & Toolchain (STRICT)
- **Architecture/Platform:** x86 32-bit (IA-32). Never 64-bit.
- **Target OS / Runtime:** Windows 10/11 (Win32 API, GUI subsystem). No C runtime.
- **Language/Syntax:** MASM 32-bit (`.586`, `.model flat, stdcall`, `option casemap:none`). `.586` is required because `rdtsc` is used for salts and DEK generation.
- **Editor / Build host:** Visual Studio Code, terminal = "x86 Native Tools Command Prompt for VS" (provides `ml.exe`, `link.exe`, Windows SDK libs).
- **Standard Libs/Dependencies:** `kernel32.lib`, `user32.lib`, `gdi32.lib`, `comdlg32.lib`, `gdiplus.lib`. Nothing else. GDI+ is used through its flat C API (`GdiplusStartup`, `GdipCreateBitmapFromFile`, `GdipBitmapLockBits`, ...).
- **Source layout (project root):**
  `constants.inc` (all EQUs), `structs.inc` (STRUCT definitions), `protos.inc` (every PROTO and EXTERN),
  `main.asm` (entry, window class, WndProc, message loop, screen switching),
  `gui.asm` (control creation, fonts, brushes, owner-draw, validation of form fields),
  `crypto.asm` (SV-Hash256, key derivation, DEK wrap/unwrap, stream cipher, PRNG, FNV-32),
  `stego.asm` (GDI+ load/convert, BMP parsing, LSB embed/extract, vault image read/write),
  `fileio.asm` (`Vault_Images\`, `users.dat`, `requests.dat`, atomic file replace, directory scan),
  `build.bat`, `PLAN.md`, `PROGRESS.md`, `SPEC.md`.
- **Build Command (`build.bat`):**
  ```bat
  ml /c /coff /Cx /Zd /Zi /W3 main.asm crypto.asm stego.asm fileio.asm gui.asm
  link /SUBSYSTEM:WINDOWS /ENTRY:start /DEBUG main.obj crypto.obj stego.obj fileio.obj gui.obj kernel32.lib user32.lib gdi32.lib comdlg32.lib gdiplus.lib
  ```
  Success criterion: both commands exit with code 0 and `ml` prints 0 errors. Warnings A6004 (unused PROC argument) are tolerated; every other warning must be fixed.
- **Test Command:** `main.exe` (run it, then follow the "Verify" line of the task in `PLAN.md`). Observable checks: on-screen result, `OutputDebugStringA` traces (DebugView or WinDbg), and a hex editor on `Vault_Images\*.bmp`, `users.dat`, `requests.dat`.
- **Syntax pre-check (optional, when the agent has a Linux sandbox without `ml.exe`):** a MASM-compatible assembler (UASM) may be used to catch syntax errors, but a clean UASM run never replaces the `ml.exe` build on the user's machine.

## 2. Coding Rules
- **Conventions:**
  - `stdcall` for every procedure. Arguments on the stack, return value in `EAX`, callee cleans the stack (use `PROC ... USES ... arg:DWORD` so MASM emits `ret N`).
  - `EBX`, `ESI`, `EDI`, `EBP` are preserved by every procedure; `EAX`, `ECX`, `EDX` are scratch. Internal leaf helpers that use a custom register contract must say so in their header.
  - Explicit `PROTO` for every procedure in `protos.inc`; cross-module procedures and globals are `PUBLIC` in the owner and declared in `protos.inc`.
  - Procedure return convention: `EAX = 0` on success, non-zero `SV_ERR_*` code on failure, unless the header says otherwise (handles and pointers return 0 on failure).
  - Parameter and local names must be descriptive (`srcPtr`, `srcLen`, `hFile`). Avoid one- or two-letter names.
  - Palette (COLORREF, BGR order, executive banking look): Canvas `0x00F4F6F9`, Header band (navy) `0x0052331E`, Input field `0x00FFFFFF`, Text `0x002B2B2B`, Steel accent `0x007D624A`, Slate muted text `0x00897A6C`, Border `0x00D4D0CC`, Success `0x0064823C`, Error `0x003C3CB4`. No neon colours, no black "hacker" theme, no default grey Win95 look: buttons are owner-drawn.
  - Font: `Segoe UI` via `CreateFontA`, body height -14, headings -22 bold, ClearType quality (5).
- **Constants:** No magic numbers. Every window style, control ID, message, struct size, field offset, cipher parameter, LSB offset, limit and error code is an EQU in `constants.inc`. Offsets of the vault header and account record are only referenced by their EQU names.
- **Documentation:** Every procedure starts with a header comment block: `Purpose`, `Inputs` (stack args / registers), `Outputs`, `Preserved`, `Clobbered`, `Errors`.
- **Error Handling:** 100 % rigorous. Check `INVALID_HANDLE_VALUE` after every `CreateFileA`/`FindFirstFileA`, the return and byte count of every `ReadFile`/`WriteFile`, every `HeapAlloc` result, every GDI+ status (`Ok = 0`), BMP dimensions and capacity before any embed, and every numeric conversion. Always release on every exit path (`CloseHandle`, `FindClose`, `HeapFree`, `GdipDisposeImage`, `GdiplusShutdown`). Failures surface to the user with `MessageBoxA` or a status label, never silently.
- **Sensitive memory:** Passwords, KEKs, DEKs and decrypted account records are held only in `.data?` buffers or heap blocks and are zero-filled (`SvWipe`) after use and on logout.
- **Scope discipline:** Do not add features outside `SPEC.md`. If the spec is wrong or ambiguous, stop, record the question in `PROGRESS.md` under "Active Blockers", and ask the user.

## 3. Mandatory Session & Handoff Protocol (CRITICAL)

To prevent context loss across sessions or account switches:

1. **Read First:** Before writing or editing code, read `SPEC.md`, `PLAN.md`, and `PROGRESS.md`.
2. **Atomic Work:** Implement and test ONE subtask from `PLAN.md` at a time. Verify tests pass before moving on.
3. **Continuous Disk Sync:** Immediately after completing and verifying any subtask, you MUST:
   * Mark the subtask `[x]` in `PLAN.md`.
   * Append a detailed entry to `PROGRESS.md` explaining what was built, how it was implemented, and the exact next task. Update the "Current Handoff Snapshot" at the top of `PROGRESS.md` in the same step.
4. **Never Leave Unverified Code:** Do not mark a task done if the build fails, tests fail, or errors occur.
5. **Never Delete the User's Data:** Do not delete or overwrite anything in `Vault_Images\`, `users.dat` or `requests.dat` except through the application's own code paths defined in `SPEC.md`.
