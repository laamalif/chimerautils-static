# chimerautils static binaries

This project provides statically linked binaries of core userland utilities from [Chimera Linux](https://chimera-linux.org/) — known as [`chimerautils`](https://github.com/chimera-linux/chimerautils) — for the following platforms:

- **linux/amd64**
- **linux/arm64**

Ideal for minimal containers, embedded systems, and scripting workflows where portability and predictability matter most.

---

## 📦 Included Utilities

This package includes statically linked versions of the following tools:

- `awk`  
- `diffutils`  
- `fetch`  
- `findutils`  
- `grep`  
- `gzip`  
- `nc`  
- `patch`  
- `sed`  
- `sh`  
- `telnet`  
- `xargs`  

---

## Why FreeBSD-style `find`?
A key feature of the FreeBSD `find` utility is its built-in `-s` flag, which ensures lexicographically sorted output by default. This eliminates the need to pipe results through `sort` — a common practice with GNU `findutils` that can introduce inconsistencies due to locale settings, filename quirks, or whitespace issues. By handling sorting internally, FreeBSD `find` ensures deterministic and reliable output — making it ideal for scripting, automation, and reproducible builds.

---

## Why FreeBSD-style `fetch`?
The FreeBSD `fetch` utility is a lightweight, native alternative to tools like curl or wget, designed with simplicity and scriptability in mind. It supports both HTTP and FTP protocols out of the box, along with proxy handling, TLS, and resume functionality. Unlike heavier GNU alternatives, `fetch` has minimal dependencies and consistent behavior across systems, making it ideal for static environments, initramfs setups, or containerized workflows where reliability and size matter. 

---

## Why BSD-style `nc`?
The BSD implementation of nc (netcat) is feature-rich yet minimal, making it ideal for scripting and troubleshooting. It supports critical options like `-k` (keep open for multiple connections), `-X` for proxy types, and built-in TLS support — often missing or inconsistently implemented across GNU/Linux distros.

---
## Why BSD-style `sh`?
The `sh` provided by BSD systems—often based on `ash`—is lightweight, fast, and strictly adheres to POSIX standards. This makes it an excellent default shell for scripting and system-level automation, especially in constrained or embedded environments. Unlike `bash`, which adds numerous extensions and behavioral quirks, or `dash`, which sacrifices some usability for speed, the BSD-style `sh` strikes a clean balance between simplicity and functionality. It provides predictable behavior across platforms, making scripts more portable and easier to debug.

---
## Why FreeBSD-style `xargs`?
FreeBSD’s `xargs` offers safer and more predictable behavior compared to its GNU counterpart. Most notably, it includes support for the `-X` flag, which prevents command execution if the generated argument list exceeds system limits—this is invaluable for scripting, where silent failures can lead to data loss or skipped operations. 

---

## About Chimera Linux and `chimerautils`

These static binaries are built from [Chimera Linux](https://chimera-linux.org/), a distribution that replaces traditional GNU userland tools with streamlined, **FreeBSD-based** alternatives. At its core is [`chimerautils`](https://github.com/chimera-linux/chimerautils), a unified package that ports essential FreeBSD utilities and provides a lightweight compatibility layer for seamless integration and static linking.

It serves as a drop-in replacement for:

- `coreutils`, `findutils`, `diffutils`, `sed`, `grep`, `gzip`, `patch`, `awk`
- Portions of `util-linux` and BusyBox
- Additional tools such as `fetch`, `telnet`, `jot`, `xargs`, and more

Unlike fragmented GNU replacements, `chimerautils` consolidates dozens of essential tools into a single, portable, Meson-based package. It’s designed to be minimal, consistent, and easy to audit — with no gnulib, fewer dependencies, and strong support for hardening techniques like Control Flow Integrity (CFI).


