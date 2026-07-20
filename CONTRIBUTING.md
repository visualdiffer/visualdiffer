## 🛠️ Build  

Clone the repository and build the app:

```bash
git clone https://github.com/visualdiffer/visualdiffer.git

cd visualdiffer
./scripts/setup-local-env.sh

```

Open in Xcode

## 👥 Contributing  

Contributions, issues, and feature requests are welcome!  

### Prerequisites

To contribute:

1. Install [swiftformat](https://github.com/nicklockwood/SwiftFormat), [swiftlint](https://github.com/realm/SwiftLint), and fzf
 
	```
	brew install swiftformat \
	 swiftlint \
	 fzf
	```

2. Fork the repository  
3. Create a new branch (`feat/xyz` or `fix/abc`)  
4. Apply your modifications
5. Run `./scripts/lint.sh` to apply `swiftformat` and `swiftlint`
6. Commit your changes with clear messages  
7. Open a pull request describing your update  

⚠️ Please follow the existing code style and include tests or examples when possible.

## Deployment

For internal use only — contributors can skip this section.

### 1. Prerequisites

Deployment relies on [fastlane](https://fastlane.tools/), which in turn uses [xcbeautify](https://github.com/cpisciotta/xcbeautify).

```
cd visualdiffer
brew install fastlane xcbeautify gnu-getopt
bundle install
```

#### VisualDiffer preset for `conventional-changelog`

```
git clone https://github.com/visualdiffer/conventional-changelog-visualdiffer.git
cd conventional-changelog-visualdiffer

npm install -g conventional-changelog
npm install -g $PWD
```

### 2. Setup

Run the admin script with the private config, passing its absolute path:

	./scripts/setup-local-env.sh -m admin /Users/dave/visualdiffer-admin-config/

### 3. Build

#### Automatic

Run `./scripts/build.sh` and select the environment from the list. Unit tests run as part of the build.

#### Manual

`./scripts/build.sh` is a wrapper around the following `fastlane` command, one invocation per environment:

    bundle exec fastlane release --env <environment>

| Environment        | Purpose                                             |
|--------------------|-----------------------------------------------------|
| `local`            | Release build deployed on GitHub                    |
| `prerelease.local` | Pre-release testing build (also deployed on GitHub) |
| `test.local`       | Build for [tart](https://tart.run/) or other VMs    |
