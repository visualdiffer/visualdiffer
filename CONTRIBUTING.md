## 🛠️ Build

### Requirements

- **Xcode 26 or later.** The project is stored in the Xcode 26 format (`objectVersion = 90`) and uses
  file system synchronized groups, so earlier versions of Xcode cannot open it.
- [Homebrew](https://brew.sh), used to install the tools below.
- The app targets macOS 13.5 and later.

Install the tools needed to configure and lint the project:

```bash
brew install gnu-getopt \
 swiftformat \
 swiftlint
```

`gnu-getopt` is required by `./scripts/setup-local-env.sh`: the BSD `getopt` shipped with macOS does not
support long options.

### Get the sources

Clone the repository and generate the local configuration files:

```bash
git clone https://github.com/visualdiffer/visualdiffer.git

cd visualdiffer
./scripts/setup-local-env.sh
```

The script copies the `*-Template.xcconfig` files to the `*.local.xcconfig` ones that the build expects.
It never overwrites an existing file, so it is safe to run again.

Open `VisualDiffer.xcworkspace` in Xcode, not `VisualDiffer.xcodeproj`.

The workspace is the container that pins the Swift Package Manager dependencies, and it is the one
the release is built from. Opening the project instead resolves the package versions freely, so you
may end up building against a different Sparkle version than the one that ships.

### Run the tests

Press ⌘U in Xcode, or from the shell:

```bash
xcodebuild -workspace VisualDiffer.xcworkspace -scheme VisualDiffer test
```

The shared scheme already runs the tests under the `DebugNoSandbox` configuration, which grants the
file system permissions the file and folder comparison tests need.

## 👥 Contributing

Contributions, issues, and feature requests are welcome!

1. Fork the repository
2. Create a new branch (`feat/xyz` or `fix/abc`)
3. Apply your modifications
4. Run `./scripts/lint.sh` to apply `swiftformat` and `swiftlint`
5. Commit your changes with clear messages
6. Open a pull request describing your update

`./scripts/lint.sh` only formats the files you changed. Pass `a` to format the whole project, or `p` to
run [periphery](https://github.com/peripheryapp/periphery) instead and look for unused code.

⚠️ Please follow the existing code style and include tests or examples when possible.

## Deployment

For internal use only — contributors can skip this section.

### 1. Prerequisites

Deployment relies on [fastlane](https://fastlane.tools/), which in turn uses
[xcbeautify](https://github.com/cpisciotta/xcbeautify). `./scripts/build.sh` uses
[fzf](https://github.com/junegunn/fzf) to pick the build profile.

```
cd visualdiffer
brew install fastlane xcbeautify fzf
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

    ./scripts/setup-local-env.sh -m admin /absolute/path/to/visualdiffer-private/

### 3. Build

#### Automatic

Run `./scripts/build.sh` and select an entry from the list. Unit tests run as part of the build.
The list also offers *Create Changelog*, which only generates the release notes and exits.

#### Manual

`./scripts/build.sh` is a wrapper around the following `fastlane` command, one invocation per environment:

    bundle exec fastlane release --env <environment>

| Environment        | Purpose                                             |
|--------------------|-----------------------------------------------------|
| `local`            | Release build deployed on GitHub                    |
| `prerelease.local` | Pre-release testing build (also deployed on GitHub) |
| `sparkle.local`    | Sparkle build, does not upload the appcast          |
| `test.local`       | Build for [tart](https://tart.run/) or other VMs    |
