# 🖥️ Hyprland & Quickshell Dotfiles

Hyprland pencere yöneticisi ve tamamen özel yapım **Quickshell** masaüstü kabuğunu kullanan kişisel Linux dotfiles koleksiyonu.

---

## ✨ Özellikler

### 🔧 Top Bar
- **Çalışma Alanı (Workspace) Göstergesi** — aktif, dolu ve boş workspace'ler görsel olarak ayrıştırılmış
- **Sistem Monitörü** — CPU / RAM / Disk / GPU anlık kullanım; bar simgesine tıkla → detay panel açılır
- **Medya Kontrolleri** — MPRIS üzerinden oynatma/durdurma/ileri/geri; kapak fotoğrafı gösterimi
- **Hava Durumu** — açık hava durumu, sıcaklık; tıklayınca detay paneli açılır
- **Pil Göstergesi** — şarj yüzdesi ve durum simgesi (laptop kullanımı için)
- **Bildirim Zili** — okunmamış bildirim sayısı, sağ tık ile Rahatsız Etme (DND) modunu aç/kapat
- **Sistem Tepsisi (SysTray)** — arka planda çalışan uygulamaların simgeleri
- **Saat** — 12/24 saat formatı, saniye gösterimi, bar yüksekliği ve opaklık ayarlanabilir
- **Hızlı Geçiş Düğmeleri (QuickToggles)** — Ses, Bluetooth, Ağ, Pano, Duvar Kağıdı seçici

---

### 🖱️ Masaüstü Widgetları
Tüm widgetlar **GUI ölçek faktörüne** göre otomatik büyür/küçülür. Köşe konumları ayarlanabilir.

| Widget | Açıklama |
|---|---|
| **DeskCard** | Opaklık ayarlı ana kart kapsayıcısı |
| **ClockWidget** | Analog veya dijital saat, masaüstü köşesine sabitleme |
| **SystemWidget** | CPU, RAM, Disk canlı grafikler |
| **MediaWidget** | Şu an çalan parça; kapak fotoğrafı, ilerleme çubuğu |
| **CalendarWidget** | Aylık takvim görünümü |

---

### 🗂️ Overview (Mission Control)
- 10 workspace'in tüm pencereleri tek ekranda grid görünümü
- Canlı pencere önizlemesi (ScreencopyView)
- Sürükle-bırak ile pencere taşıma
- Hover animasyonu, aktif workspace vurgusu
- Boş workspace gizleme seçeneği
- Sağ tık bağlam menüsü (Taşı, Kapat)
- Klavye kısayolları: `[1–0]` workspace seç, `[Enter]` geç, `[Esc]` kapat, `[Drag]` taşı
- **Yuvarlak köşeler** — `OpacityMask` ile wallpaper da dahil tüm içerik kırpılır

---

### 🔔 Bildirimler
- **Bildirim Popup'ları** — urgency renkli şerit (düşük/normal/kritik), uygulama adı rozeti, hızlı sessize al
- **Bildirim Merkezi** — geçmiş, canlı arama çubuğu, uygulama filtre pill'leri, toplu temizle
- **DND (Rahatsız Etme)** — bar zili sağ tık veya ayarlardan; kritik bildirimleri izin ver seçeneği
- **Ses Efektleri** — bildirim tipine göre `pw-play` / `paplay` ile sistem sesi çalma
- **Uygulama Sessize Alma** — belirli uygulamalardan gelen bildirimler sessiz; tarihçede gösterilir
- **Uygulama Engelleme** — belirli uygulamalardan gelen bildirimler tamamen engellenir

---

### 🚀 Uygulama Başlatıcı (Launcher)
- Yüklü uygulamaları ara ve başlat
- Canlı filtreleme, klavye navigasyonu

---

### 🔊 Ses Mikseri (Audio Mixer)
- Tüm aktif ses akışlarının ayrı ayrı ses seviyesi
- Giriş/çıkış cihazı seçimi

---

### 📋 Pano Yöneticisi (Clipboard)
- Pano geçmişi, tek tık ile yapıştırma

---

### 🌐 Ağ Yöneticisi
- Wi-Fi ağ listesi, bağlan/ayır

---

### 🔵 Bluetooth Yöneticisi
- Eşleşmiş ve keşfedilen cihazlar, bağlan/ayır

---

### 💡 OSD (On-Screen Display)
- Ses seviyesi, parlaklık, mikrofon değiştiğinde animasyonlu gösterge

---

### ⌨️ Alt-Tab Geçiş
- Pencereler arası görsel geçiş, `Alt+Tab` / `Alt+Shift+Tab`

---

### ⌨️ Keybind Görüntüleyici
- Tanımlı tüm kısayolların overlay listesi

---

### 🖼️ Duvar Kağıdı Seçici
- Dizinden resim seç, geçiş animasyonları (`outer`, `fade`, `wipe` vb.)
- Küçük resim (thumbnail) önizleme

---

### 🌦️ Hava Durumu Paneli
- Şehir bazlı hava durumu detayları, ikonlar, günlük tahmin

---

### 📊 Sistem Monitörü Paneli
- CPU / RAM / Disk / Ağ / GPU canlı istatistikler
- Bar simgesine tıkla → konuma sabitlenmiş açılır panel

---

### ⚙️ Ayarlar Paneli
Kapsamlı görsel ayar arayüzü. Tüm ayarlar `settings.json` dosyasına otomatik kalıcı olarak kaydedilir.

| Sekme | Ayarlar |
|---|---|
| **Görünüm** | Dinamik tema, accent rengi, arka plan rengi |
| **Bar** | Yükseklik, opaklık, hangi elemanların gösterileceği |
| **GUI Ölçeği** | %70 – %160 aralığında tüm arayüzü büyüt/küçült |
| **Saat & Tarih** | 12/24 saat, saniye, tarih formatı, haftanın başlangıcı |
| **Widget'lar** | Her widget için aç/kapat, köşe konumu |
| **Bildirimler** | DND, kritik izni, ses efektleri, sessize alınan & engellenen uygulamalar |
| **Overview** | Workspace sayısı, sütun sayısı, canlı önizleme, boş gizle |
| **Duvar Kağıdı** | Dizin, geçiş tipi, geçiş süresi |
| **Hava Durumu** | Yenileme aralığı |
| **Dil** | Türkçe / İngilizce (tüm arayüz) |

---

## 📂 Proje Yapısı

```text
myconfig/
├── shell.qml                   # Ana giriş noktası
├── settings.json               # Kalıcı ayarlar (otomatik oluşturulur)
├── config/
│   └── Colors.qml              # Renk paleti (dinamik tema desteği)
├── services/                   # Singleton servisler & state yönetimi
│   ├── SettingsState.qml       # Tüm ayarlar, GUI ölçeği, persist
│   ├── NotificationService.qml # DND, ses efektleri, engelleme/sessize alma
│   ├── WallpaperService.qml    # Duvar kağıdı yönetimi
│   ├── DynamicTheme.qml        # Duvar kağıdından otomatik renk çıkarma
│   ├── SystemInfo.qml          # CPU/RAM/Disk/GPU polling
│   ├── SystemMonitorState.qml  # Sistem monitörü panel state
│   ├── WeatherState.qml        # Hava durumu API
│   ├── AudioMixerState.qml     # Ses mikseri state
│   ├── AudioDeviceListState.qml# Ses cihazları
│   ├── BluetoothStatus.qml     # Bluetooth state
│   ├── BluetoothListState.qml  # Bluetooth cihaz listesi
│   ├── NetworkState.qml        # Ağ state
│   ├── ClipboardState.qml      # Pano state
│   ├── CalendarState.qml       # Takvim state
│   ├── AltTabState.qml         # Alt-Tab state
│   ├── OverviewState.qml       # Overview state
│   ├── LauncherState.qml       # Başlatıcı state
│   ├── PowerMenuState.qml      # Güç menüsü state
│   ├── KeybindsState.qml       # Keybind listesi state
│   ├── OsdService.qml          # OSD tetikleyici
│   ├── DesktopLayout.qml       # Masaüstü widget düzeni
│   ├── Battery.qml             # Pil durumu
│   ├── WifiStatus.qml          # Wi-Fi durum
│   ├── I18n.qml                # Çoklu dil (TR/EN)
│   ├── TimeFormat.qml          # Saat/tarih formatlama
│   ├── TimeSettings.qml        # Zaman ayarları
│   ├── WallpaperPickerState.qml# Duvar kağıdı seçici state
│   └── WallpaperThumbs.qml     # Küçük resim üretici
└── modules/                    # UI modülleri
    ├── bar/                    # Top bar elemanları
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
    ├── deskwidgets/            # Masaüstü widgetları
    │   ├── DesktopWidgets.qml
    │   ├── DeskCard.qml
    │   ├── ClockWidget.qml
    │   ├── SystemWidget.qml
    │   ├── MediaWidget.qml
    │   └── CalendarWidget.qml
    ├── overview/               # Mission Control görünümü
    │   ├── Overview.qml
    │   └── OverviewIpc.qml
    ├── notifications/          # Bildirim sistemi
    │   ├── NotificationPopup.qml
    │   ├── NotificationCenter.qml
    │   └── NotificationDaemon.qml
    ├── settings/               # Ayarlar paneli
    │   ├── Settings.qml
    │   └── SettingsIpc.qml
    ├── sysmon/                 # Sistem monitörü paneli
    │   └── SystemMonitorPanel.qml
    ├── launcher/               # Uygulama başlatıcı
    │   ├── Launcher.qml
    │   └── LauncherIpc.qml
    ├── audio/                  # Ses cihaz listesi
    │   ├── AudioDeviceList.qml
    │   └── AudioDeviceIpc.qml
    ├── mixer/                  # Ses mikseri
    │   ├── AudioMixer.qml
    │   └── MixerIpc.qml
    ├── bluetooth/              # Bluetooth yöneticisi
    │   ├── BluetoothList.qml
    │   └── BluetoothIpc.qml
    ├── network/                # Ağ yöneticisi
    │   ├── NetworkList.qml
    │   └── NetworkIpc.qml
    ├── clipboard/              # Pano yöneticisi
    │   ├── ClipboardPicker.qml
    │   └── ClipboardIpc.qml
    ├── wallpaper/              # Duvar kağıdı seçici
    │   ├── WallpaperPicker.qml
    │   └── WallpaperIpc.qml
    ├── weather/                # Hava durumu paneli
    │   └── WeatherPanel.qml
    ├── calendar/               # Takvim
    │   └── Calendar.qml
    ├── osd/                    # On-Screen Display
    │   └── Osd.qml
    ├── alttab/                 # Alt-Tab geçişi
    │   ├── AltTabOverlay.qml
    │   └── AltTabIpc.qml
    ├── keybinds/               # Keybind görüntüleyici
    │   ├── KeybindsOverlay.qml
    │   └── KeybindsIpc.qml
    ├── powermenu/              # Güç menüsü
    │   ├── PowerMenu.qml
    │   └── PowerMenuIpc.qml
    └── common/
        └── PopupFx.qml         # Paylaşımlı popup animasyonu
```

---

## 🚀 Kurulum

### Gereksinimler

```bash
# Zorunlu
hyprland
quickshell          # QML tabanlı masaüstü kabuğu
hyprpaper           # Duvar kağıdı
hyprlock            # Ekran kilidi
hypridle            # Boşta kalma yönetimi

# Ses (bildirim sesleri için)
pipewire            # pw-play komutu
# veya
pulseaudio          # paplay komutu

# Fontlar
ttf-jetbrains-mono-nerd   # veya herhangi bir Nerd Font
```

### Kurulum Adımları

```bash
# 1. Repoyu klonla
git clone https://github.com/KULLANICI/REPO.git ~/.config/quickshell/myconfig

# 2. Hyprland yapılandırmasını yerleştir
# ~/.config/hypr/ klasörüne kopyala

# 3. Quickshell'i başlat
quickshell -c ~/.config/quickshell/myconfig/shell.qml

# 4. Hyprland oturumunu yeniden başlat veya
qs reload
```

---

## 🛠️ Özelleştirme

### Renkler & Tema
- **Dinamik Tema:** Duvar kağıdından otomatik renk çıkarma (`services/DynamicTheme.qml`)
- **Sabit Tema:** `settings.json` → `fixedAccentColor` / `fixedBackgroundColor`
- **Renk Paleti:** `config/Colors.qml` dosyasını doğrudan düzenle

### GUI Ölçeği
Tüm arayüz `SettingsState.scaleFactor` ile ölçeklenir (ayarlar panelinden %70–%160).  
Yeni bir piksel değeri eklerken: `Math.round(N * SettingsState.scaleFactor)`

### Dil (i18n)
`services/I18n.qml` → `tr` ve `en` bloklarına anahtar ekle.  
QML dosyalarında: `I18n.t("anahtarAdı")`

### Bildirim Sesleri
`/usr/share/sounds/freedesktop/stereo/` dizinindeki `.oga` dosyaları kullanılır.  
`pw-play` yoksa `paplay` ile fallback yapılır.

---

## ⌨️ Varsayılan Kısayollar

> Hyprland keybind'lerinize göre farklılık gösterebilir.

| Kısayol | Eylem |
|---|---|
| `Super + Tab` | Overview (Mission Control) aç/kapat |
| `Alt + Tab` | Alt-Tab pencere geçişi |
| `Super + D` | Uygulama başlatıcı |
| `Super + Shift + E` | Güç menüsü |
| `Super + N` | Bildirim merkezi |
| `Super + S` | Ayarlar paneli |

---

## 📄 Lisans

MIT License — dilediğiniz gibi kullanın, katkı ekleyin.
