# 🖥️ Hyprland & Quickshell Dotfiles

Personal Linux dotfiles featuring a custom-built **Quickshell** desktop shell and a modular **Hyprland** window manager configuration.

---

## ✨ Features

- **Custom Quickshell Desktop Environment:**
  - Dynamic top bar with workspaces, system monitor, media controls, system tray, and weather widgets.
  - Interactive widgets for desktop cards, calendar, clock, and media playback.
  - Polished OSD (On-Screen Display), App Launcher, Power Menu, Alt-Tab switcher, and Notification Center.
  - Audio mixer, Bluetooth, network, and clipboard managers.
- **Modular Hyprland Setup:**
  - Clean Lua-based configuration structure for rules, keybinds, environments, and execs.
  - Automated wallpaper management and color extraction scripts.
  - Custom `hyprlock` screen locker and `hypridle` configurations.

---

## 📂 Project Structure

```text
├── quickshell/              # Custom QML Desktop Shell
│   ├── config/              # Global configuration (Colors)
│   ├── modules/             # UI Modules (Bar, Launcher, Osd, Audio, etc.)
│   ├── services/            # State management and system services
│   └── shell.qml            # Main shell entry point
│
└── hypr/                    # Hyprland Window Manager Configs
    ├── custom/              # User overrides and custom scripts
    ├── hyprland/            # Core configuration modules & Lua scripts
    ├── hyprlock/            # Lock screen layouts and scripts
    └── scripts/             # Utility scripts (color extraction, wallpapers)

🚀 Getting Started
Prerequisites
```
Make sure you have the following packages installed on your Linux system:

    Hyprland

    Quickshell (QML-based desktop shell toolkit)

    hyprlock, hypridle, hyprpaper

    Required fonts and icon packs.

Installation

    Clone the repository to your local config directory:
    Bash

    git clone [https://github.com/KULLANICI_ADIN/REPO_ADIN.git](https://github.com/KULLANICI_ADIN/REPO_ADIN.git) ~/.config/hypr

    Symlink or move the Quickshell configuration to its respective path if necessary.

    Restart your Hyprland session or reload your configuration.

🛠️ Customization

    Colors & Themes: Modify quickshell/config/Colors.qml or use the extraction scripts in hypr/scripts/ to generate dynamic color schemes.

    Keybinds: Adjust shortcuts inside hypr/hyprland/keybinds.lua or your custom/ overrides.

📄 License

Distributed under the MIT License.
