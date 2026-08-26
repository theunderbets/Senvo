# Fix Warnings and Errors in Project

The current active file (`README.md`) does not contain any detected warnings or errors. However, a project-wide scan has revealed several warnings in core files that should be addressed to improve code quality, maintainability, and compatibility.

## Proposed Changes

### Android Manifest
#### [MODIFY] [AndroidManifest.xml](file:///home/abhi/Downloads/Senvo/app/src/main/AndroidManifest.xml)
- Set `android:required="false"` for `android.hardware.camera.flash` to allow devices without a flash to install the app (while still using it if available).

### Resources
#### [MODIFY] [strings.xml](file:///home/abhi/Downloads/Senvo/app/src/main/res/values/strings.xml)
- Add missing string resources for hardcoded text found in `MainActivity.java` and `activity_main.xml`.

#### [MODIFY] [activity_main.xml](file:///home/abhi/Downloads/Senvo/app/src/main/res/layout/activity_main.xml)
- Replace hardcoded strings with `@string` resources.

### Java Source Code
#### [MODIFY] [MainActivity.java](file:///home/abhi/Downloads/Senvo/app/src/main/java/com/raamen/sih/MainActivity.java)
- Replace statement lambdas with expression lambdas where possible.
- Replace hardcoded strings with `getString(R.string.name)`.
- Address reassigned local variable warnings.

### Build Configuration
#### [MODIFY] [app/build.gradle](file:///home/abhi/Downloads/Senvo/app/build.gradle)
- Update dependencies to their latest stable versions.
- Update `compileSdk` and `targetSdk` to 34 (or 35 if recommended) to stay current with Android standards.

## Verification Plan

### Automated Tests
- Run `gradle :app:assembleDebug` to ensure the project still builds successfully after changes.
- Run `gradle :app:lintDebug` to verify that the identified warnings have been resolved.

### Manual Verification
- Deploy the app to a device/emulator to ensure UI strings are displayed correctly.
