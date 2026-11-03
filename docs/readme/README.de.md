# Terax

**Ein leichtgewichtiges Terminal mit Ordner-Explorer und Git-Statusverfolgung. Ohne integrierte KI-Agenten.**

Diese Version ist ein modifizierter Fork von [crynta/terax-ai](https://github.com/crynta/terax-ai) und wird separat unter [slaatarsi/terax-no-ai](https://github.com/slaatarsi/terax-no-ai) gepflegt. Das ursprüngliche Projekt stammt von Crynta und den Upstream-Mitwirkenden.

## Funktionen

- Natives Terminal mit Tabs, geteilten Ansichten, Suche und Shell-Integration.
- Ordner-Explorer mit Suche, Dateiverwaltung und Live-Aktualisierungen.
- Git-Status, Diffs, Staging, Commits, Push und grafischer Verlauf.
- Editor, optionale Sprachserver, Vorschauen und Themes bleiben als ergänzende Werkzeuge erhalten.

Kein integrierter KI-Chat, keine Agenten, KI-Anbieter, KI-Vervollständigung oder Spracheingabe. CLI-Programme können weiterhin manuell gestartet werden. Alte KI-Daten und externe Hooks werden weder geladen noch automatisch entfernt.

## Aus dem Quellcode bauen

Benötigt werden Rust stable, Node 22+, pnpm und die [Tauri-Voraussetzungen](https://tauri.app/start/prerequisites/).

```bash
git clone https://github.com/slaatarsi/terax-no-ai.git
cd terax-no-ai
pnpm install
pnpm tauri dev
# Produktionspaket:
pnpm tauri build
```

**Achtung:** Die Update-Konfiguration verweist weiterhin auf Upstream-Releases. Ein solches Update kann diesen Fork durch die Originalversion ersetzen. Upstream-Installer und -Pakete sind nicht als diese KI-freie Version zu betrachten. Fork-spezifische Signaturen werden nicht zugesichert.

Vollständige Anleitungen und Einschränkungen stehen im [englischen README](../../README.md). Siehe auch [Dokumentation](../README.md), [Mitwirken](../../CONTRIBUTING.md) und [Sicherheit](../../SECURITY.md). Probleme bitte im Repository dieses Forks melden.

Lizenz: [Apache-2.0](../../LICENSE). Die ursprünglichen Urheberhinweise bleiben erhalten.
