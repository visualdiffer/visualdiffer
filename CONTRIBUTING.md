## 🛠️ Build  

Clone the repository and build the app:

```bash
git clone https://github.com/visualdiffer/visualdiffer.git

cd visualdiffer
./scripts/setup-local-env.sh

```

Open in Xcode

## 👥Contributing  

Contributions, issues, and feature requests are welcome!  
To contribute:

1. Install [swiftformat](https://github.com/nicklockwood/SwiftFormat) and [swiftlint](https://github.com/realm/SwiftLint)
2. Fork the repository  
2. Create a new branch (`feat/xyz` or `fix/abc`)  
3. Run `./scripts/lint.sh` to apply `swiftformat` and `swiftlint`
3. Commit your changes with clear messages  
4. Open a pull request describing your update  

⚠️ Please follow the existing code style and include tests or examples when possible.

## Deploy

Build the release version to deploy on GitHub

    bundle exec fastlane release --env local

Build the version used for pre-release test

    bundle exec fastlane release --env test.local
