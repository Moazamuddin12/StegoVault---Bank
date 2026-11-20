# CLAUDE.md

Read and strictly follow all rules, toolchain constraints, and handoff protocols defined in `@AGENTS.md`.

## Session Startup & Continuity
1. Read `@SPEC.md`, `@PLAN.md`, and `@PROGRESS.md` before taking any action.
2. Resume directly from the **Next Immediate Step** listed at the top of `@PROGRESS.md`.
3. After completing and verifying every individual task via the designated test command, update `@PLAN.md` and `@PROGRESS.md` on disk immediately before starting the next task.

## Project Quick Facts (do not re-derive; they are fixed by `@SPEC.md`)
- Project: StegoVault Bank, 32-bit MASM, native Win32 GUI, built from VS Code with `build.bat`.
- Account data lives only inside 24-bit BMPs (LSB steganography) in `Vault_Images\`; `users.dat` holds salted verifiers, `requests.dat` holds the transaction queue.
- Two roles: Cashier (account created at first start from the login screen; no default admin; Master Key) and Depositors (username + password + their own BMP).
- The vault header is 108 bytes (`SVLT` magic, two wrapped DEKs, checksum, username hash, nonce); the account record is 148 bytes; both are defined in `@SPEC.md` section 4.
- Code that already exists and may be reused from the earlier StegoLock project: BMP parsing, GDI+ JPG/PNG to 24-bit BMP conversion, LSB embed/extract loops, whole-file read/write helpers, open/save dialog wrapper. Re-verify each against `@SPEC.md` before reusing it.
