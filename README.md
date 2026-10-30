<h1 align="center">Blitzsprecher</h1>

<p align="center">
  <b>Text. Hören. Fertig.</b><br>
  Dein Mac liest dir vor, was unter dem Cursor steht.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14%2B-111111?logo=apple" alt="macOS 14 oder neuer">
  <img src="https://img.shields.io/badge/license-MIT-2563EB" alt="MIT License">
  <img src="https://img.shields.io/badge/status-Konzept-c37a4a" alt="Konzept-Phase">
</p>

<p align="center">
  <a href="UPSTREAM.md"><b>Vorlage: Blitztext</b></a> ·
  <a href="docs/mockup-01-menubar-und-ablage.html">Mockup</a> ·
  <a href="#modi">Modi</a> ·
  <a href="#ablage">Ablage</a>
</p>

---

Blitzsprecher ist das Spiegelbild von
[Blitztext](https://github.com/cmagnussen/blitztext-app). Blitztext hört zu und
schreibt. Blitzsprecher nimmt den markierten Text unter deinem Cursor und
liest ihn vor. Menü-Bar, nativ, lokal. Kein Konto, kein Backend, nichts
verlässt das Gerät.

## Status

**Grundgerüst.** Das Xcode-Projekt baut, die Menü-Bar-App startet und spricht
einen Beispielsatz. Lesepille, Hotkeys und Selection-Reader sind als Stubs
angelegt; die reale Pipeline folgt in kleinen Schritten.

- [Mockup 01 — Menü-Bar und Ablage](docs/mockup-01-menubar-und-ablage.html) (Meridian-Design)
- [Attribution und Vorlage](UPSTREAM.md)

### Selbst bauen

```bash
brew install xcodegen
git clone https://github.com/sykfar/blitzsprecher.git
cd blitzsprecher
./build.sh --run
```

Braucht Xcode 16 oder neuer und macOS 14. `build.sh` erzeugt eine ad-hoc
signierte Debug-App und startet sie optional. Veröffentlichung braucht eine
eigene Developer-ID-Signierung und Notarisierung.

```text
BlitzsprecherMac/
  App/            BlitzsprecherApp, AppState
  Features/       MenuBar, Settings
  Services/       SpeechService, SelectionReader, HotkeyService
  Resources/      Info.plist, Entitlements, Assets.xcassets
  Tests/          Unit-Tests
BlitzsprecherShared/
  Design/         MeridianTokens (Farben, Typografie, Spacing)
project.yml       xcodegen-Spec
build.sh          lokaler Build
```

## Idee

1. Text in irgendeiner App markieren (Mail, Safari, Obsidian, Notes).
2. Shortcut halten, zum Beispiel `fn + ⇧`.
3. Blitzsprecher liest den markierten Text vor, in einer System-Stimme deiner
   Wahl. Eine lila Pille unten im Bildschirm zeigt den Fortschritt.
4. Loslassen oder in die Pille klicken stoppt die Wiedergabe.

Alles läuft auf deinem Mac. `AVSpeechSynthesizer` nutzt die System-Stimmen,
inklusive der neuen Siri-Stimmen und optional Personal Voice.

## Modi

| Modus | Shortcut | Was passiert |
|---|---|---|
| **Blitzsprecher** | `fn + ⇧` | Markierten Text wortgenau vorlesen |
| **Blitzsprecher+** | `fn + ⌃` | Text erst mit Apple Intelligence glätten, dann vorlesen |
| **Blitzsprecher 🎧** | `fn + ⌥` | Als `.m4a`-Datei ablegen (Vault, GitHub oder Website) |
| **Blitzsprecher 📝** | `fn + ⌘` | Lange Texte zusammenfassen, dann vorlesen |

## Ablage

Der 🎧-Modus kann die Hörfassung an drei Ziele legen:

- **Vault:** als Anhang zur Quellnote in einem Obsidian-Vault, mit Wikilink.
- **GitHub:** als Release-Asset oder Issue-Anhang in einem gewählten Repo.
- **Website:** als Audio-Block in einem Ghost-Post, zum Beispiel für die
  Hörfassung eines Essays.

Für Version 1 steht der Vault im Mittelpunkt. GitHub und Website folgen.

## Design — Meridian

Farben, Schriften und Formen stammen aus **Interview Studio** (einer anderen
Apple-App aus dem gleichen Haus). Das Design heißt dort *Meridian* und ist
eine bewusste Ausnahme vom Hausdesign: Fraunces für das Vorgelesene und
Überschriften, Public Sans für die Bedienung, IBM Plex Mono für Pfade.
Paper als Fläche, Fathom-Blau als Lesen-Signal, Sienna als Warnung.

Die Design-Tokens leben in
[`BlitzsprecherShared/Design/MeridianTokens.swift`](BlitzsprecherShared/Design/MeridianTokens.swift).

## Vorlage und Dank

Blitzsprecher baut auf der Idee, dem Design und der Architektur von
**[Blitztext](https://github.com/cmagnussen/blitztext-app)** von
[Christian Magnussen](https://github.com/cmagnussen) auf. Details in
[UPSTREAM.md](UPSTREAM.md).

Der Produktname „Blitztext" und das Icon gehören zum Original; sie werden
hier nicht verwendet.

## Lizenz

MIT. Siehe [LICENSE](LICENSE).
