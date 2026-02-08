# DrawSesh
**Overview**
DrawSesh is a mac app for timed drawing sessions, using your own references from a designated local folder. I made this for my own figure-drawing sessions, but since you can set what images are used, you can use it to practice drawing whatever you want: portraits, animals, fabrics, etc.

**Features**
- Configure session time and pose count (i.e. 1 min gestures x 10 images) — img 1
- Spotlights a random image from your folder; controllable via keyboard navigation — img 2
- History log to reference past sessions and how often/long you draw — img 3
- Weighted randomization to favour images you don't seen often

<img width="300" src="https://github.com/user-attachments/assets/c1ea5ce8-0de1-461b-8b39-d186d4c37e1a"/>
<img width="300" src="https://github.com/user-attachments/assets/0cd3de59-60b5-4cb8-b2ce-b37fe13a26e9"/>
<img width="300" src="https://github.com/user-attachments/assets/c5a879a4-d6bb-4375-99dc-4505ad492357"/>

## How to Install
*This build is unsigned/notarized which means it'll give you an error because it's not an official Mac app. It's not official because I'm not paying Apple $100/yr for a license. macOS will show a warning the first time you open it. I promise it's not a virus.*

**Requirements**
- macOS 13 or later
- Xcode 15+ or Swift 5.9 toolchain

**Instructions**
1. Download `DrawSesh.zip` from GitHub Releases.
2. Unzip and drag `DrawSesh.app` to `Applications` (optional but recommended).
3. Try to launch it **(It will give you a warning. See below)**
4. Go into System Settings → Privacy & Security → Scroll down to see "DrawSesh was blocked to protect your Mac"
5. Click Open Anyway → Open Anyway → Allow it (password/fingerprint/etc)

## How to Use
1. Create your own folder of reference images to draw from
2. Launch the app, click **Choose Folder** to select your reference image folder
4. Adjust your session settings and start your session
5. Draw, draw, draw!
6. Take a break and move onto the next session

# Artist Resources
**Where to Source Reference Images**
- www.proko.com/tools (Paid, has a built-in tool you should use, has some free downloadable resources)
- www.photo-reference-for-comic-artists.com/ (Some paid)
- www.deviantart.com/theposearchives
- Pinterest, screenshots, life, etc! Build your library every time you come across something useful

**Drawing Tips**

Proko features a lot of guests that share their own methods of figure drawing. For short poses, focus on capturing the force and movement of the image — the "gesture" of your image. As the timer increases, use straight, curved, and S-lines to create shapes that reinforce your gesture.
- Proko using seals to demonstrate simple lines that will help with your gesture: https://www.youtube.com/watch?v=2fl5LYouyoY
- Michael Hampton on how simple gestures need to be: https://www.youtube.com/watch?v=tSyGOZjTs5A
- Proko on interesting shapes and rhythms: https://www.proko.com/course-lesson/draw-any-pose-from-any-angle-rhythms
- Mike Mattesi's on dynamic poses via FORCE: https://www.youtube.com/watch?v=14yBwKaBY48

# Nerd Stuff

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


**Data & Privacy**
All data stays on your machine. The app only reads image files you select and stores session history locally.

**License**
MIT. See `LICENSE`.
