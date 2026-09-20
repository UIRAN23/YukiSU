# Auto storage test build

This fork adds one tmpfs attempt when automatically selected ext4 cannot be prepared or mounted. Forced ext4 remains forced. The backend still validates files and SELinux metadata; success requires the final mount plan to complete.

The fallback does not repair the underlying loop-device I/O failure. Verify Auto after reboot using the Kagami log, the actual ODM mounts, and the camera.

Fork Actions builds use the existing temporary CI APK signing path when production keys are unavailable. Production GPG signing requirements remain enabled outside forks. Telegram publishing is disabled for fork builds. This is a test APK, not an upstream-signed update; its certificate may differ from an installed manager.

No device flashing or on-device validation is performed by this workflow.
