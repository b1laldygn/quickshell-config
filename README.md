# 🖥️ Hyprland & Quickshell Dotfiles

Personal Linux dotfiles featuring a fully custom-built **Quickshell** desktop shell and a modular **Hyprland** window manager configuration.

> 🇹🇷 Türkçe dokümantasyon için: [README.tr.md](README.tr.md)

---

## ✨ Features

### 🔧 Top Bar
- **Workspace Indicator** — active, occupied and empty workspaces visually differentiated
- **System Monitor** — real-time CPU / RAM / Disk / GPU usage; click icon → detail panel
- **Media Controls** — MPRIS playback controls (play/pause/prev/next) with cover art
- **Weather Widget** — current weather and temperature; click for a detailed panel
- **Battery Indicator** — charge percentage and status icon
- **Notification Bell** — unread notification count; right-click to toggle Do Not Disturb
- **System Tray** — icons for background applications
- **Clock** — 12/24-hour format, optional seconds display, configurable height & opacity
- **Quick Toggles** — Audio, Bluetooth, Network, Clipboard, Wallpaper picker

---

### 🖱️ Desktop Widgets
All widgets scale automatically with the **GUI scale factor**. Corner position is configurable per widget.

| Widget | Description |
|---|---|
| **DeskCard** | Main card container with adjustable opacity |
| **ClockWidget** | Analog or digital clock, pinned to a desktop corner |
| **SystemWidget** | Live CPU, RAM, Disk graphs |
| **MediaWidget** | Now playing: cover art, title, progress bar |
| **CalendarWidget** | Monthly calendar view |

---

### 🗂️ Overview (Mission Control)
- Grid view of all windows across up to 10 workspaces
- Live window previews via ScreencopyView
- Drag & drop window movement between workspaces
- Hover animations, active workspace highlight
- Option to hide empty workspaces
- Right-click context menu (Move, Close)
- Keyboard shortcuts: `[1–0]` select workspace · `[Enter]` switch · `[Esc]` close · `[Drag]` move
- **True rounded corners** — wallpaper and all content clipped via `OpacityMask`

---

### 🔔 Notifications
- **Popup Notifications** — urgency color strip (low / normal / critical), app name badge, quick mute button
- **Notification Center** — history, live search bar, per-app filter pills, bulk clear
- **Do Not Disturb (DND)** — toggle from the bell icon (right-click) or Settings; allow critical override
- **Sound Effects** — system sounds played via `pw-play` / `paplay` based on notification type
- **App Muting** — notifications from specific apps are silenced (still stored in history)
- **App Blocking** — notifications from specific apps are blocked entirely

---

### 🚀 App Launcher
- Search and launch installed applications
- Live filtering, full keyboard navigation

---

### 🔊 Audio Mixer
- Individual volume control for every active audio stream
- Input / output device selection

---

### 📋 Clipboard Manager
- Clipboard history with one-click paste

---

### 🌐 Network Manager
- Wi-Fi network list, connect / disconnect

---

### 🔵 Bluetooth Manager
- Paired and discovered devices, connect / disconnect

---

### 💡 OSD (On-Screen Display)
- Animated volume, brightness and microphone indicator overlays

---

### ⌨️ Alt-Tab Switcher
- Visual window switcher, `Alt+Tab` / `Alt+Shift+Tab`

---

### ⌨️ Keybind Viewer
- Overlay list of all defined keyboard shortcuts

---

### 🖼️ Wallpaper Picker
- Browse images from a configured directory with thumbnail previews
- Transition animations: `outer`, `fade`, `wipe`, and more

---

### 🌦️ Weather Panel
- City-based weather details, icons, daily forecast

---

### 📊 System Monitor Panel
- Live CPU / RAM / Disk / Network / GPU statistics
- Click the bar icon → panel anchors near the click position

---

### ⚙️ Settings Panel
Full visual settings UI. All settings are automatically persisted to `settings.json`.

| Tab | Settings |
|---|---|
| **Appearance** | Dynamic theme, accent color, background color |
| **Bar** | Height, opacity, which elements to show |
| **GUI Scale** | Scale the entire UI from 70 % to 160 % |
| **Clock & Date** | 12/24 h, seconds, date format, week start day |
| **Widgets** | Enable/disable each widget, corner position |
| **Notifications** | DND, critical override, sound effects, muted & blocked apps |
| **Overview** | Workspace count, columns, live preview, hide empty |
| **Wallpaper** | Directory, transition type, transition duration |
| **Weather** | Refresh interval |
| **Language** | Turkish / English (entire UI) |

---

## 📂 Project Structure

```text
myconfig/
├── shell.qml                   # Main entry point
├── settings.json               # Persisted settings (auto-generated)
├── config/
│   └── Colors.qml              # Color palette (dynamic theme support)
├── services/                   # Singleton services & state management
│   ├── SettingsState.qml       # All settings, GUI scale, persistence
│   ├── NotificationService.qml # DND, sound effects, mute/block logic
│   ├── WallpaperService.qml    # Wallpaper management
│   ├── DynamicTheme.qml        # Auto color extraction from wallpaper
│   ├── SystemInfo.qml          # CPU/RAM/Disk/GPU polling
│   ├── SystemMonitorState.qml  # System monitor panel state
│   ├── WeatherState.qml        # Weather API
│   ├── AudioMixerState.qml     # Audio mixer state
│   ├── AudioDeviceListState.qml# Audio devices
│   ├── BluetoothStatus.qml     # Bluetooth state
│   ├── BluetoothListState.qml  # Bluetooth device list
│   ├── NetworkState.qml        # Network state
│   ├── ClipboardState.qml      # Clipboard state
│   ├── CalendarState.qml       # Calendar state
│   ├── AltTabState.qml         # Alt-Tab state
│   ├── OverviewState.qml       # Overview state
│   ├── LauncherState.qml       # Launcher state
│   ├── PowerMenuState.qml      # Power menu state
│   ├── KeybindsState.qml       # Keybind list state
│   ├── OsdService.qml          # OSD trigger
│   ├── DesktopLayout.qml       # Desktop widget layout
│   ├── Battery.qml             # Battery status
│   ├── WifiStatus.qml          # Wi-Fi status
│   ├── I18n.qml                # Internationalization (TR/EN)
│   ├── TimeFormat.qml          # Time/date formatting
│   ├── TimeSettings.qml        # Time settings
│   ├── WallpaperPickerState.qml# Wallpaper picker state
│   └── WallpaperThumbs.qml     # Thumbnail generator
└── modules/                    # UI modules
    ├── bar/                    # Top bar components
    │   ├── Bar.qml
    │   ├── Workspaces.qml
    │   ├── SystemMonitor.qml
    │   ├── MediaControls.qml
    │   ├── WeatherWidget.qml
    │   ├── BatteryIndicator.qml
    │   ├── NotificationBell.qml
    │   ├── SysTray.qml
    │   ├── Clock.qml
    │   └── QuickToggles.qml
    ├── deskwidgets/            # Desktop widgets
    │   ├── DesktopWidgets.qml
    │   ├── DeskCard.qml
    │   ├── ClockWidget.qml
    │   ├── SystemWidget.qml
    │   ├── MediaWidget.qml
    │   └── CalendarWidget.qml
    ├── overview/               # Mission Control view
    │   ├── Overview.qml
    │   └── OverviewIpc.qml
    ├── notifications/          # Notification system
    │   ├── NotificationPopup.qml
    │   ├── NotificationCenter.qml
    │   └── NotificationDaemon.qml
    ├── settings/               # Settings panel
    │   ├── Settings.qml
    │   └── SettingsIpc.qml
    ├── sysmon/                 # System monitor panel
    │   └── SystemMonitorPanel.qml
    ├── launcher/               # App launcher
    │   ├── Launcher.qml
    │   └── LauncherIpc.qml
    ├── audio/                  # Audio device list
    │   ├── AudioDeviceList.qml
    │   └── AudioDeviceIpc.qml
    ├── mixer/                  # Audio mixer
    │   ├── AudioMixer.qml
    │   └── MixerIpc.qml
    ├── bluetooth/              # Bluetooth manager
    │   ├── BluetoothList.qml
    │   └── BluetoothIpc.qml
    ├── network/                # Network manager
    │   ├── NetworkList.qml
    │   └── NetworkIpc.qml
    ├── clipboard/              # Clipboard manager
    │   ├── ClipboardPicker.qml
    │   └── ClipboardIpc.qml
    ├── wallpaper/              # Wallpaper picker
    │   ├── WallpaperPicker.qml
    │   └── WallpaperIpc.qml
    ├── weather/                # Weather panel
    │   └── WeatherPanel.qml
    ├── calendar/               # Calendar
    │   └── Calendar.qml
    ├── osd/                    # On-Screen Display
    │   └── Osd.qml
    ├── alttab/                 # Alt-Tab switcher
    │   ├── AltTabOverlay.qml
    │   └── AltTabIpc.qml
    ├── keybinds/               # Keybind viewer
    │   ├── KeybindsOverlay.qml
    │   └── KeybindsIpc.qml
    ├── powermenu/              # Power menu
    │   ├── PowerMenu.qml
    │   └── PowerMenuIpc.qml
    └── common/
        └── PopupFx.qml         # Shared popup animation component
```

---

## 🚀 Getting Started

### Prerequisites

```bash
# Required
hyprland
quickshell          # QML-based desktop shell toolkit
hyprpaper           # Wallpaper daemon
hyprlock            # Screen locker
hypridle            # Idle manager

# Audio (for notification sounds)
pipewire            # provides pw-play
# or
pulseaudio          # provides paplay

# Fonts
# Any Nerd Font (JetBrainsMono Nerd Font recommended)
```

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/YOUR_USER/YOUR_REPO.git ~/.config/quickshell/myconfig

# 2. Place Hyprland configuration
# Copy contents to ~/.config/hypr/

# 3. Launch Quickshell
quickshell -c ~/.config/quickshell/myconfig/shell.qml

# 4. Or reload a running instance
qs reload
```

---

## 🛠️ Customization

### Colors & Theme
- **Dynamic Theme:** Automatic color extraction from the current wallpaper (`services/DynamicTheme.qml`)
- **Fixed Theme:** Edit `fixedAccentColor` / `fixedBackgroundColor` in `settings.json`
- **Color Palette:** Directly edit `config/Colors.qml`

### GUI Scale
The entire UI scales via `SettingsState.scaleFactor` (70 %–160 % from the Settings panel).  
When adding new pixel values: `Math.round(N * SettingsState.scaleFactor)`

### Internationalization (i18n)
Add keys to both `tr` and `en` blocks in `services/I18n.qml`.  
Use in QML: `I18n.t("keyName")`

### Notification Sounds
Sounds from `/usr/share/sounds/freedesktop/stereo/` are played via `pw-play` with a fallback to `paplay`.

---

## ⌨️ Default Keybindings

> May differ depending on your Hyprland keybind configuration.

| Shortcut | Action |
|---|---|
| `Super + Tab` | Toggle Overview (Mission Control) |
| `Alt + Tab` | Alt-Tab window switcher |
| `Super + D` | App launcher |
| `Super + Shift + E` | Power menu |
| `Super + N` | Notification center |
| `Super + S` | Settings panel |

---

## 📄 License

Distributed under the MIT License. Use, fork, and contribute freely.
