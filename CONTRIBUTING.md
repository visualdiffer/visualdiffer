## 🛠️ Build  

Clone the repository and build the app:

```bash
git clone https://github.com/<your-account>/visualdiffer.git
cd visualdiffer

# copy files to local usage
cp ./Signing-Template.xcconfig ./Signing.local.xcconfig
cp ./Versions-Template.xcconfig ./Versions.local.xcconfig

cp ./Signing-Template.xcconfig ./visdiff/Signing.local.xcconfig
cp ./Versions-Template.xcconfig ./visdiff/Versions.local.xcconfig

cp ./Signing-Template.xcconfig ./Tests/Signing.local.xcconfig
cp ./Versions-Template.xcconfig ./Tests/Versions.local.xcconfig

```

Open in Xcode

## 👥Contributing  

Contributions, issues, and feature requests are welcome!  
To contribute:

1. Install [swiftformat](https://github.com/nicklockwood/SwiftFormat) and [swiftlint](https://github.com/realm/SwiftLint)
2. Fork the repository  
2. Create a new branch (`feature/xyz` or `fix/abc`)  
3. Run `./scripts/lint.sh` to apply `swiftformat` and `swiftlint`
3. Commit your changes with clear messages  
4. Open a pull request describing your update  

⚠️ Please follow the existing code style and include tests or examples when possible.
