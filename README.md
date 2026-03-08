# 🎵 MusicPlayer — iOS Swift App

Приложение-плеер на SwiftUI. Нажимаешь кнопку — играет музыка.

---

## 📁 Структура проекта

```
MusicPlayer/
├── MusicPlayer.xcodeproj/        ← файл проекта Xcode
│   └── project.pbxproj
└── MusicPlayer/
    ├── MusicPlayerApp.swift      ← точка входа (@main)
    ├── ContentView.swift         ← весь UI (SwiftUI)
    ├── Track.swift               ← модель трека + список песен
    ├── AudioPlayerViewModel.swift← логика воспроизведения (AVFoundation)
    └── Assets.xcassets/          ← иконки и цвета
```

---

## 🖥️ ШАГ 1 — Настройка виртуальной машины macOS

### Что нужно установить на ВМ

**Требования к ВМ:**
- RAM: минимум 8 ГБ (рекомендую 16 ГБ)
- Диск: минимум 60 ГБ свободно
- CPU: 4+ ядра

### Программы для создания macOS ВМ на Windows:

| Программа | Цена | Удобство |
|-----------|------|----------|
| **VMware Workstation Pro** | Бесплатно (с 2024) | ⭐⭐⭐⭐⭐ |
| VirtualBox | Бесплатно | ⭐⭐⭐ (медленнее) |
| QEMU | Бесплатно | ⭐⭐ (сложно) |

### Как поставить macOS на VMware:

1. Скачай **VMware Workstation Pro 17** (теперь бесплатен для личного использования)
2. Скачай образ macOS Sonoma (14) или Ventura (13) — ищи `.iso` или `.cdr`
3. Установи плагин **"Unlocker"** для VMware чтобы macOS была доступна как гостевая ОС:
   - GitHub: `paolo-projects/unlocker` — скачай и запусти `win-install.cmd` от администратора
4. Создай новую ВМ → выбери **"Apple Mac OS X"** → **"macOS 14"**
5. Установи macOS как обычно

### После установки macOS в ВМ:
```
Настройки системы → Общий доступ → включи "Общий экран" (для удобства)
```

---

## 🔨 ШАГ 2 — Установка Xcode

В macOS на ВМ:

1. Открой **App Store**
2. Найди **Xcode** (бесплатно, ~15 ГБ)
3. Установи и запусти хотя бы раз — он доставит дополнительные компоненты
4. Запусти в Терминале:
```bash
xcode-select --install
sudo xcodebuild -license accept
```

---

## 📲 ШАГ 3 — Открыть проект

1. Скопируй папку `MusicPlayer/` в macOS (через общую папку VMware или USB)
2. Дважды кликни на **`MusicPlayer.xcodeproj`** — откроется Xcode
3. В левом верхнем углу выбери симулятор: **iPhone 15** (или любой)
4. Нажми ▶️ **Run** (Cmd+R) — приложение запустится в симуляторе

---

## 🎵 ШАГ 4 — Добавить музыку

По умолчанию треки в списке есть, но аудио-файлов нет (приложение работает, просто без звука).

Чтобы добавить реальные MP3:

1. Возьми любые MP3 файлы и переименуй их:
   - `midnight_glow.mp3`
   - `neon_dreams.mp3`
   - `golden_hour.mp3`
   - `electric_soul.mp3`
   - `rainy_days.mp3`

2. В Xcode: перетащи файлы в папку **MusicPlayer** в левой панели
3. В появившемся окне **обязательно поставь галку** "Add to target: MusicPlayer"
4. Нажми Finish

Или добавь свои песни в `Track.swift` — там всё подписано комментариями.

---

## 📦 ШАГ 5 — Собрать IPA файл

### Вариант А: для себя (без Apple Developer аккаунта)

Это позволит поставить приложение на **свой** iPhone через кабель.

1. Подключи iPhone к Mac/ВМ через USB
2. В Xcode вверху выбери своё устройство вместо симулятора
3. Xcode попросит войти в Apple ID — войди в **Xcode → Settings → Accounts**
4. Выбери Team: свой Apple ID (бесплатный)
5. Нажми ▶️ Run — приложение установится на телефон

⚠️ Бесплатный аккаунт: приложение работает **7 дней**, потом нужно переустановить.

---

### Вариант Б: IPA файл (для распространения / AltStore)

Нужен Apple Developer аккаунт ($99/год) **ИЛИ** можно использовать бесплатный способ через AltStore.

#### С Developer аккаунтом ($99/год):

```
Xcode → меню Product → Archive
```
После архивации откроется **Organizer** → нажми **Distribute App** → выбери метод → на выходе получишь `.ipa`

#### Бесплатно через командную строку (без подписи):

```bash
# В Xcode сначала сделай Build для симулятора:
# Product → Build (Cmd+B)

# Найди собранный .app:
find ~/Library/Developer/Xcode/DerivedData -name "MusicPlayer.app" -type d

# Создай папку Payload и упакуй в IPA:
mkdir Payload
cp -r /путь/до/MusicPlayer.app Payload/
zip -r MusicPlayer.ipa Payload/
```

Такой IPA можно установить через **AltStore** или **Sideloadly** (они сами подпишут).

---

### Вариант В: Sideloadly (самый простой способ)

1. На Windows скачай **Sideloadly** (sideloadly.io)
2. Собери IPA командой выше
3. Подключи iPhone к Windows по USB
4. Открой Sideloadly, вставь IPA, введи Apple ID → Install
5. На телефоне: Настройки → Основные → VPN и управление устройством → доверяй своему Apple ID

---

## 🛠️ Что делает каждый файл

### `MusicPlayerApp.swift`
Точка входа. `@main` говорит Swift что это старт приложения. Просто показывает `ContentView`.

### `Track.swift`
Модель данных. Структура `Track` описывает одну песню: название, исполнитель, имя файла, эмодзи. Здесь же массив `sampleTracks` — редактируй его чтобы добавить свои треки.

### `AudioPlayerViewModel.swift`
Вся логика воспроизведения. Использует **AVFoundation** — стандартный Apple фреймворк для аудио. `@Published` переменные автоматически обновляют UI при изменении.

### `ContentView.swift`
Весь интерфейс на **SwiftUI**. Разбит на маленькие компоненты: `NowPlayingCard`, `ControlsView`, `TrackListView` и т.д. — так удобнее редактировать.

---

## ❓ Частые проблемы

**"No account for team"** → Xcode → Settings → Accounts → добавь Apple ID

**"Could not launch app"** → на iPhone: Настройки → Основные → VPN и управление устройством → нажми на своё имя → Доверять

**Нет звука** → MP3 файлы не добавлены в проект (см. Шаг 4)

**ВМ тормозит** → выдели больше RAM и CPU ядер в настройках VMware
