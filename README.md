# ExerScroll

A cross-platform app that blocks selected apps until you earn time by performing exercises (pushups, pull-ups) with on-device pose detection via BlazePose.

## Features

- **App Blocking**: Block selected apps until sufficient exercise time is earned
- **Exercise Detection**: Pushups and pull-ups counted via camera + BlazePose (MediaPipe)
- **Time Bank**: Earn minutes per rep; deduct as you use blocked apps
- **Dashboard**: Track progress, banked time, and exercise stats

## Quick Start

```bash
# First-time setup (adds Gradle wrapper, platform files)
flutter create .

# Install dependencies and run
flutter pub get
flutter run
```

Or use the scripts (from project root):
```bash
scripts\setup.bat   # Install dependencies
scripts\run.bat     # Run the app
```

## Recommended Emulator

For **ExerScroll** (camera + BlazePose), use an emulator with:

### Best options

1. **Pixel 7 API 34** (recommended)
   - Good camera emulation
   - Modern API level
   - Create: **Device Manager → Create Device → Pixel 7 → API 34 (UpsideDownCake)**

2. **Pixel 6 API 33**
   - Stable, widely used
   - Create: **Device Manager → Create Device → Pixel 6 → API 33 (Tiramisu)**

3. **For flip phone layout** (Oppo Find N3 Flip–style)
   - Create: **Device Manager → Create Device → Fold-in → API 34**
   - Or use a **phone profile** with narrow width (e.g. 360×640) for cover screen testing

### Create emulator via CLI

```bash
# List available system images
flutter emulators

# Create Pixel 7 emulator (example)
flutter emulators --create --name pixel_7_api34

# Or via Android SDK:
# sdkmanager "system-images;android-34;google_apis;x86_64"
# avdmanager create avd -n ExerScroll_Test -k "system-images;android-34;google_apis;x86_64" -d pixel_7
```

### Camera on emulator

- Use **Virtual scene camera** (emulated back camera)
- Or **Webcam** as camera source in emulator settings
- BlazePose needs a view of your upper body for rep counting

### Run on emulator

```bash
# Start emulator first, then:
flutter run

# Or specify device:
flutter devices
flutter run -d <device_id>
```

## Permissions

- **Camera**: For exercise pose detection (requested at launch)
- **Usage Access** (Android): To detect when blocked apps are opened (grant manually in Settings)
- **Display Over Other Apps** (Android): For blocking overlay (if enabled)

## Requirements

- Flutter 3.16+
- Android API 28+
- Device/emulator with camera
