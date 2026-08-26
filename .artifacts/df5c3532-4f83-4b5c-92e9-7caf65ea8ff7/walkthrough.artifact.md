# Walkthrough - 16KB Alignment and Warning Fixes

I have successfully addressed the "16kb alignment error" and several high-priority warnings in the project.

## Changes Made

### 16KB Alignment & Android 15 Support
- **SDK Update**: Bumped `compileSdk` to **37** and `targetSdk` to **35** in [app/build.gradle](file:///home/abhi/Downloads/Senvo/app/build.gradle) to ensure compatibility with the latest Android 15 requirements.
- **Dependency Upgrades**:
    - Updated **CameraX** to `1.6.1`. This is critical because older versions often contain native libraries that aren't 16KB aligned.
    - Updated **Material Components** to `1.14.0` and **Appcompat** to `1.8.0`.
- **Packaging Adjustments**: Removed `useLegacyPackaging = true` to allow the Android Gradle Plugin to use uncompressed, 16KB-aligned native libraries.
- **Manifest Fallback**: Added `android:pageSizeCompat="enabled"` to [AndroidManifest.xml](file:///home/abhi/Downloads/Senvo/app/src/main/AndroidManifest.xml) as a compatibility bridge for Android 15 devices.

### Code Quality & Resources
- **Resource Extraction**: Moved hardcoded strings from [MainActivity.java](file:///home/abhi/Downloads/Senvo/app/src/main/java/com/raamen/sih/MainActivity.java) and [activity_main.xml](file:///home/abhi/Downloads/Senvo/app/src/main/res/layout/activity_main.xml) into [strings.xml](file:///home/abhi/Downloads/Senvo/app/src/main/res/values/strings.xml).
- **Lambda Refactoring**: Cleaned up statement lambdas in `MainActivity.java` to use more concise expression lambdas.
- **Flash Requirement**: Updated [AndroidManifest.xml](file:///home/abhi/Downloads/Senvo/app/src/main/AndroidManifest.xml) to set `android.hardware.camera.flash` as `required="false"`, improving app availability on devices without a flash.

## Verification Results

### Build Success
The project now builds successfully with the latest configurations:
```bash
./gradlew :app:assembleDebug
# Output: Build finished successfully.
```

### Lint Improvements
Multiple lint warnings regarding hardcoded strings and SDK versions have been resolved.

> [!TIP]
> The app is now ready to be tested on an Android 15 emulator with 16KB page size. The previous alignment error should no longer occur.
