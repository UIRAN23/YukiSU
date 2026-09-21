# Image-storage test build

The previous Auto-to-tmpfs fallback is removed. This build addresses image preparation and attaches loop devices explicitly in buffered mode. It probes the backing file and loop device separately before mounting, so a loop read failure is not presented as a filesystem-format error.

Ext4 is built in a temporary file, checked for its superblock signature, synced and renamed after successful formatting. An existing invalid image is retained as mirror.img.invalid before rebuilding; an existing backup is never overwritten automatically.

EROFS is built from selected OverlayFS modules on first mount of the boot. Module attributes, whiteouts and opaque directories pass through the existing copy/relabel pipeline. Embedded pinned erofs-utils tools create an uncompressed 4 KiB-block image and verify its data before committing it. Matching tool source archives are retained as Actions artifacts. EROFS data is rebuilt after module changes on reboot.

Device evidence from 2026-09-20: EROFS failed because mirror.erofs did not exist; ext4 failed at loop49 reads before the superblock could be read. These are different failures. Whether explicit buffered loop attachment fixes this device's I/O failure still requires testing; no kernel filesystem changes or signature bypass are included.

Fork APKs use a temporary CI certificate and are not updates signed by the upstream developer. The kernel does not automatically trust that certificate. The final Manager-arm64-v8a artifact contains the repacked APK; do not substitute the intermediate Gradle artifact.

## Official manager testing

Do not uninstall the official manager to test this userspace fix. Android rejects the different APK signer, and kernel manager authorization is independent of APK installation. The storage-test artifact is a standalone ksud package with UAPI/hash checks, backup, atomic replacement and restore. See [instructions](tools/storage-test/README.md). It does not bypass manager authentication. Disable manager auto-sync during testing; reauthentication can also restore the bundled daemon. Device installation and recovery have not yet been validated.
