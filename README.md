# TiviMate E2 Online Update

This repository provides the verified online update manifest and installation packages for TiviMate E2.

The plugin reads `update.json` securely over HTTPS. It selects the IPK package on systems using `opkg` and the DEB package on DreamOS systems using `dpkg`, verifies the SHA-256 checksum, and asks the user before installation.
