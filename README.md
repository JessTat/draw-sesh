# DrawSesh
**Overview**
DrawSesh is a macOS app for timed drawing sessions, using references from a local folder you can set. Initially made for figure-drawing sessions, it will spotlight random images from the selected folder for a specified duration. Use this to practice quick draws and gesture practice using your own images and without dealing with the internet.

**Features**
- Configure your session with customizable timer and image counts
- A history log to keep track of how often you've drawn
- A draw-counter on each image, used to weight the app to show images you haven't drawn often

**Requirements**
- macOS 13 or later
- Xcode 15+ or Swift 5.9 toolchain

**Run From Source**
From the repo root:

```bash
cd GestureDrawApp
swift run
```

**Build a Release .app**
From the repo root:

```bash
cd GestureDrawApp
scripts/build_app_bundle.sh
```

The app bundle will be at `GestureDrawApp/dist/DrawSesh.app`.

**Gatekeeper Warning (Unsigned Builds)**
This app is not notarized. If macOS blocks it:
1. Right‑click the app and choose **Open**.
2. Click **Open** again in the prompt.

**Data & Privacy**
All data stays on your machine. The app only reads image files you select and stores session history locally.

**License**
MIT. See `LICENSE`.
