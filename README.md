<p align="center">
    <img src="https://avatars.githubusercontent.com/u/1219826?s=400&u=264b78c259d3d6b452071a71c5150a7ff5acc85e&v=4"
        height="130">
</p>
<p align="center">
        <img src="https://img.shields.io/badge/License-GPL3-blue?style=flat" />
        <img src="https://img.shields.io/badge/macOS-13.5+-orange?logo=apple&style=flat" />
        <img src="https://img.shields.io/badge/Swift-6.2-orange?logo=swift&logoColor=white&style=flat" />
        <img src="https://img.shields.io/github/downloads/Visualdiffer/visualdiffer/latest/total.svg" />
        <img src="https://img.shields.io/github/downloads/visualdiffer/visualdiffer/total" />
</p>

# VisualDiffer

## Overview  
**VisualDiffer** is a macOS application designed to **visually compare folders and files** with clarity and speed.  
It lets you instantly see what has changed between two directories — new, modified, or missing files — through a clean side-by-side interface.  
The app helps developers, designers, and anyone managing multiple versions of projects to easily identify differences, filter unwanted files, and synchronize content more efficiently.

### Key Features  
- 🟩 **Side-by-side folder comparison** — instantly highlights differences between directories (added, removed, or modified files).  
- 🧩 **File-level diff view** — inspect detailed content changes line-by-line (for supported file types).  
- 🧹 **Powerful filters** — exclude version control, backup, or temporary files (e.g., `.git`, `.svn`, `.zip`, `.DS_Store`).  
- 🖱️ **Drag & drop support** — compare folders by simply dragging them into the app window.  
- 📦 **Export and automation** — integrate comparisons into scripts or workflows using CLI tools (if available).  
- ⚡ **Fast comparison engine** — optimized to handle large folder structures efficiently.  

For more information, visit the [VisualDiffer Wiki](https://wiki.visualdiffer.com/).

<p align="center">
    <img src="https://visualdiffer.com/vd/folders.png">
</p>

---

## ⚡ Caveats

> [!WARNING]
> This is a port of the original project written in Objective-C.
> The Swift code was rewritten from scratch without using conversions made by AI models.
> Maximum care was taken in rewriting the code, but regressions or new bugs are possible.
> 
---

## 📦  Installation  

> [!NOTE]
> The installed application:
> 
> - is notarized
> - is sandboxed
> 
> **Notarization** is Apple's automated security check for macOS apps.
> 
> **Sandboxing** restricts what an app can access on your Mac, for example the application can only access files/folders the user explicitly grants access to.

### From Homebrew

You can install visualdiffer using homebrew with this command:

```bash
brew install visualdiffer
```

### From GitHub Releases

Download from [releases](https://github.com/visualdiffer/visualdiffer/releases/latest), unzip, and drag the app to Applications folder

## 🛠️ Build  

See [Contributing](CONTRIBUTING.md)

---

## License  

Released under the **GPL3 License**.  
See [`LICENSE`](./LICENSE) for details.

---

## Acknowledgments  

VisualDiffer was inspired by the need for a fast, reliable, and elegant folder comparison tool for macOS.  
Thanks to all contributors, testers, and users who continue to improve the project.
