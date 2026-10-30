# Upstream und Attribution

Blitzsprecher ist das Spiegelbild einer Idee, die nicht von mir stammt.

## Vorlage

**[Blitztext](https://github.com/cmagnussen/blitztext-app)** von
[Christian Magnussen](https://github.com/cmagnussen) und dem Blackboat-Team,
MIT-lizenziert. Blitztext ist eine Menü-Bar-App für macOS, die diktieren
lässt: Shortcut halten, sprechen, loslassen, der Text landet am Cursor. Alles
lokal, kein Backend, keine Telemetrie.

Ohne Blitztext gäbe es dieses Projekt nicht. Die Architektur-Entscheidungen
(Menü-Bar, Hotkey-Service, Lesepille, Modi, Settings, History) sind dort
sauber vorgedacht.

## Was Blitzsprecher anders macht

Blitzsprecher dreht die Pipeline um:

| Blitztext | Blitzsprecher |
|---|---|
| Mikrofon → Spracherkennung → Text am Cursor | Markierter Text → optional Glättung → gesprochene Ausgabe |
| Parakeet oder Whisper, lokal | `AVSpeechSynthesizer` mit System-Stimmen, lokal |
| Fügt Text ein, Clipboard bleibt sauber | Spricht und/oder schreibt eine `.m4a` |

Vier Modi, parallel zu Blitztext:

- **Blitzsprecher** `fn + ⇧` — markierten Text vorlesen
- **Blitzsprecher+** `fn + ⌃` — Text erst glätten (Apple Intelligence), dann vorlesen
- **Blitzsprecher 🎧** `fn + ⌥` — als `.m4a` ablegen (Vault, GitHub, Website)
- **Blitzsprecher 📝** `fn + ⌘` — lange Texte zusammenfassen, dann vorlesen

## Was NICHT übernommen wird

- Die Wortmarke **„Blitztext"** und das Icon gehören zum Original (siehe
  [TRADEMARKS.md im Original-Repo](https://github.com/cmagnussen/blitztext-app/blob/main/TRADEMARKS.md)).
- Das **Blackboat-Logo** und die Blackboat-Marken.
- Jamf-/Blackboat-spezifische Verteilungs-Pfade.

## Code-Übernahme

Blitzsprecher ist **kein Git-Fork** von Blitztext. Es ist ein eigenständiges
Repository, das sich an der Blitztext-Architektur orientiert. Falls einzelne
Code-Teile später direkt übernommen werden (Hotkey-Service, Pill-Overlay),
wird das pro Datei im Header vermerkt: `// Adapted from blitztext-app`
plus Verweis auf Commit und Datei.

## Lizenz

MIT, wie das Original. Siehe [LICENSE](LICENSE).

## Kontakt mit dem Original

Verbesserungen, die auch Blitztext zugutekämen (Bugfixes im Hotkey-Service,
Pill-Overlay, Apple-Intelligence-Wrapper), fließen als Pull Request dorthin
zurück, nicht nur hierher.
