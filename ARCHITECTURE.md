# StegoVault Bank — Architecture Summary & Viva Guide

## 1. Executive Summary & Design Philosophy
**StegoVault Bank** is a secure, native 32-bit Win32 banking application implemented entirely in pure MASM assembly (`.586`, `.model flat, stdcall`).
- **Zero C Runtime Dependency:** Directly invokes raw Win32 APIs (`kernel32`, `user32`, `gdi32`, `comdlg32`, `gdiplus`).
- **Zero Database Server:** Operates without SQL or external databases; ledger state is secured through steganographic storage.
- **Zero Plaintext Customer Data on Disk:** Customer account numbers, names, balances, and PII are never stored in plaintext on disk or in files. Sensitive data exists only as 148-byte records encrypted via a custom 2-pass stream cipher embedded inside personal 24-bit uncompressed BMP images (`Vault_Images\<username>.bmp`) via LSB steganography.
- **Zero Password Storage:** Passwords are never saved anywhere. Authentication relies on a 32-byte cryptographic verifier derived using a 16-byte random salt and `SvHash256`.
- **Zero Sensitive Residual Memory:** All plaintext buffers, temporary cryptographic keys, and DEKs are actively overwritten with zeros (`SvWipe`) on every function return and session logout.

---

## 2. System Architecture & Modular Layout

```
                              +--------------------------------------------------+
                              |                    main.asm                      |
                              |  Entry Point (start), WndProc, WM_PAINT Header,  |
                              |  Owner-Draw Button Dispatcher, Screen Switching  |
                              +--------------------------------------------------+
                                        |                             |
                 +----------------------+                             +----------------------+
                 v                                                                           v
+-----------------------------------+                                     +-----------------------------------+
|              gui.asm              |                                     |            fileio.asm             |
| - Screen 1: Login Portal          |                                     | - InitStorage                     |
| - Screen 2: Registration Form     |                                     | - ReadWholeFile / WriteWholeFile  |
| - Screen 3: Depositor Dashboard   |                                     | - AtomicWriteFile (.tmp staging)  |
| - Screen 4: Cashier Center        |                                     | - users.dat (96 B/rec engine)     |
| - Custom palette, owner-draw btns |                                     | - requests.dat (64 B/rec engine)  |
| - Status line & field validators  |                                     | - ScanVault (*.bmp directory)     |
+-----------------------------------+                                     +-----------------------------------+
                 |                                                                           |
                 +----------------------+                             +----------------------+
                                        v                             v
                              +--------------------------------------------------+
                              |                    stego.asm                     |
                              | - LoadImageAsBmp (GDI+ any-format decoder)       |
                              | - ParseBmp (24bpp validation, capacity check)    |
                              | - EmbedBytes / ExtractBytes (LSB Stego Engine)   |
                              | - BuildVaultImage / OpenVaultImage (Dual-wrap)   |
                              +--------------------------------------------------+
                                                       |
                                                       v
                                      +----------------------------------+
                                      |            crypto.asm            |
                                      | - SvHash256 (256-bit hash)       |
                                      | - SvDeriveKeys (Verifier, KEK)   |
                                      | - SvCipher (2-pass stream cipher)|
                                      | - SvWrapDek / SvUnwrapDek        |
                                      | - SvFnv32 (FNV-1a 32-bit)        |
                                      | - SvRandom (rdtsc xorshift)      |
                                      | - SvWipe (Zeroization)           |
                                      +----------------------------------+
```

---

## 3. Cryptographic & Steganographic Engine

### 3.1 Vault Stream Structure (256 Bytes Embedded via LSB)
Inside each depositor's BMP pixel array starting at byte offset 54 (`bfOffBits`), 2,048 pixel bytes encode 256 bytes into their least significant bits (1 bit per byte, 8 pixels per byte):

| Offset | Length | Field | Purpose |
| :--- | :--- | :--- | :--- |
| `0x00` | 4 B | `Magic` | Must equal `'SVLT'` (`0x544C5653`). Rejects non-stego images. |
| `0x04` | 32 B | `UserWrappedDEK` | Depositor Data Encryption Key wrapped via `KEK_user`. |
| `0x24` | 32 B | `CashierWrappedDEK` | Same DEK wrapped via `KEK_cashier` (`"SV-MASTER-KEY-2026"`). |
| `0x44` | 4 B | `Checksum` | `SvFnv32(PlaintextRecord) XOR DEK[0..3]`. Tamper detection. |
| `0x48` | 32 B | `UsernameHash` | `SvHash256(lowercase username)`. Rejects cross-account images. |
| `0x68` | 4 B | `Nonce` | Transaction sequence counter. Monotonically increasing rollback guard. |
| `0x6C` | 148 B | `EncryptedRecord` | `ACCOUNT_RECORD` encrypted via `SvCipher(record, DEK, Nonce)`. |

### 3.2 Dual-Key Architecture
- **Depositor Path:** Depositor inputs password -> derives `KEK_user` -> unwraps `UserWrappedDEK` -> decrypts record.
- **Cashier Path:** Cashier uses hardcoded Master Key `"SV-MASTER-KEY-2026"` -> derives `KEK_cashier` -> unwraps `CashierWrappedDEK` -> decrypts record without needing depositor password.

### 3.3 Security Invariants
1. **Cross-Account Prevention:** Header `UsernameHash` is verified before decryption. Attempting to login with another user's image fails with `"Unauthorized Image: This vault image does not belong to your account"`.
2. **Rollback Guard:** Image `Nonce` is checked against `users.dat` `LastNonce`. Supplying an older restored image fails with `"Stale vault image: an older copy of your image was supplied."`.
3. **Tamper Detection:** If any byte of the header or encrypted record is modified or corrupted, FNV-32 checksum verification fails with `"Vault image is damaged or has been tampered with."`.
4. **Crash Consistency:** Image updates use `AtomicWriteFile` (`.tmp` write, flush, replace). If the process terminates unexpectedly, the previous valid image remains intact.

---

## 4. Pre-Populated Sample Accounts & Credentials

The repository includes a ready-to-test dataset generated via `make_sample_vaults.exe`:

| Role | Username | Password | Vault Image Path | Initial Balance | Account Number |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Depositor** | `alice` | `password123` | `Vault_Images\alice.bmp` | PKR 50,000 | `ACC-1001` |
| **Depositor** | `bob` | `password456` | `Vault_Images\bob.bmp` | PKR 30,000 | `ACC-1002` |
| **Cashier** | `admin` | `admin123` | *(None required)* | N/A | Cashier ID 1 |
| **Cover File** | — | — | `cover_sample.bmp` | — | Pristine 24bpp BMP |

---

## 5. Quick Start & Demonstration Script

### Build Instructions
Open Developer Command Prompt / PowerShell in the project directory:
```cmd
.\build.bat
```
*(Assembles all 5 modules with 0 warnings, 0 errors, and produces `main.exe`)*.

To clean build artifacts:
```cmd
.\build.bat clean
```

### Live Demonstration Workflow
1. **Launch `main.exe`:**
   Window appears sized at 960x640 with navy header band, status bar, and role selection tabs.
2. **Depositor Login:**
   - Select **Depositor** tab.
   - Username: `alice`
   - Password: `password123`
   - Image: Browse to `Vault_Images\alice.bmp`.
   - Click **[ Login ]**.
   - Depositor dashboard opens: Account `ACC-1001`, Alice Smith, Balance `PKR 50000`.
3. **Submit Transaction Request:**
   - Select **Withdrawal**, enter `5000`, click **[ Submit Request ]**.
   - Notice: Status shows `Request #3 submitted. Waiting for cashier approval.`.
   - Click **[ Logout ]**.
4. **Cashier Review & Approval:**
   - Select **Cashier** tab.
   - Username: `admin`, Password: `admin123`.
   - Click **[ Cashier Login ]**.
   - Notice pending alert: `3 pending request(s) waiting.`.
   - Select the pending request in the list box.
   - Click **[ Approve Request ]**.
   - Status updates to `Approved`, pending count decreases, and Alice's vault BMP is atomically updated on disk with Nonce 2.
   - Click **[ Logout ]**.
5. **Security Demonstration (Cross-Account Guard):**
   - On Depositor login, enter username `alice`, password `password123`.
   - Select Bob's image: `Vault_Images\bob.bmp`.
   - Click **[ Login ]**.
   - Rejected with exact message: `"Unauthorized Image: This vault image does not belong to your account"`. Zero session leakage.
6. **Automated Verification Suite:**
   Run the full end-to-end regression and acceptance suite:
   ```cmd
   .\run_demo_suite.exe
   ```
   *(Executes registration, login, cross-account failure, request, approve, and tamper failure start to finish with exit code 0)*.

---

## 6. Viva Questions & Defense Summary

- **Q: Why is LSB steganography used instead of an encrypted SQLite database?**
  *A:* Steganography conceals the very existence of financial records. A forensic scanner inspecting the drive detects only ordinary bitmap photos in `Vault_Images\`. Even if an image is extracted, dual-wrapped DEKs and 2-pass stream encryption prevent unauthorized decryption.
- **Q: How does the Cashier update an account without knowing the depositor's password?**
  *A:* The 108-byte vault header stores two independently wrapped copies of the same 32-byte DEK: `UserWrappedDEK` (wrapped via password-derived KEK) and `CashierWrappedDEK` (wrapped via Master Key KEK). The cashier unwraps the DEK using the Master Key, decrypts the record, updates the balance, increments the Nonce, and re-encrypts the record with the same DEK.
- **Q: How does the system prevent replay attacks or stale image rollbacks?**
  *A:* Every transaction increments the image's embedded 32-bit `Nonce` and updates `LastNonce` in `users.dat`. If a depositor attempts to restore an earlier image backup with an older balance, Step 7 of the login pipeline asserts `Nonce >= LastNonce` and blocks access immediately.
- **Q: What happens if the power cuts out while writing an updated vault image?**
  *A:* Write operations use `AtomicWriteFile`, which writes the updated image to a temporary file (`<image>.tmp`), calls `FlushFileBuffers` to force write-through to physical disk, and invokes `MoveFileExA` with `MOVEFILE_REPLACE_EXISTING`. The original vault image is never left half-written.
