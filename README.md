# SpaceLabel

A lightweight floating overlay for naming macOS Spaces (virtual desktops).

![macOS 12.0+](https://img.shields.io/badge/macOS-12.0%2B-blue)
![License: MIT](https://img.shields.io/badge/License-MIT-green)

## Features

- **Custom Space Names**: Double-click or click the pencil icon to name your spaces
- **Visual Indicators**: Green background for labeled spaces, red for unlabeled
- **Persistent Labels**: Names are saved and persist across app restarts
- **Always Visible**: Floats above all windows and follows you across spaces
- **Native macOS Look**: Uses system vibrancy for a polished appearance
- **Lightweight**: Single-file Swift app with no dependencies

## Installation

### Homebrew

```bash
brew tap drpedapati/spacelabel
brew install spacelabel
ln -sf $(brew --prefix)/opt/spacelabel/SpaceLabel.app /Applications/
```

### Manual

```bash
git clone https://github.com/drpedapati/spacelabel.git
cd spacelabel
make
make install  # Copies to /Applications
```

## Usage

1. Launch SpaceLabel from Applications or Spotlight
2. The overlay appears in the bottom-left corner showing your current space
3. **To name a space**: Double-click the label or click the pencil icon
4. **To clear a name**: Click the X button
5. **To move the overlay**: Drag it anywhere on screen

### Keyboard Shortcuts

- **Enter**: Save the current name
- **Escape**: Cancel editing
- **Cmd+Q**: Quit the app

## Auto-Start at Login

1. Open **System Preferences** → **Users & Groups** → **Login Items**
2. Click **+** and select SpaceLabel.app

## Requirements

- macOS 12.0 (Monterey) or later
- Xcode Command Line Tools (for building from source)

## Limitations

- Uses private macOS APIs for space detection (not App Store compatible)
- Space IDs may change after system restarts

## License

MIT License - see [LICENSE](LICENSE) for details.
