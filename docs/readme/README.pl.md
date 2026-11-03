# Terax

**Lekki terminal z eksploratorem folderów i śledzeniem zmian Git. Bez wbudowanych agentów AI.**

Ta wersja jest zmodyfikowanym forkiem [crynta/terax-ai](https://github.com/crynta/terax-ai), utrzymywanym osobno w [slaatarsi/terax-no-ai](https://github.com/slaatarsi/terax-no-ai). Autorami oryginalnego projektu są Crynta i współtwórcy upstream.

## Funkcje

- Natywny terminal z kartami, podziałem paneli, wyszukiwaniem i integracją powłoki.
- Eksplorator folderów z wyszukiwaniem, zarządzaniem plikami i aktualizacjami na żywo.
- Status Git, różnice, staging, commity, push i graficzna historia.
- Edytor, opcjonalne serwery językowe, podglądy i motywy pozostają narzędziami pomocniczymi.

Brak wbudowanego czatu AI, agentów, dostawców AI, uzupełniania kodu przez AI i wprowadzania głosowego. Programy CLI można nadal uruchamiać ręcznie. Stare dane AI i zewnętrzne hooki nie są ładowane ani automatycznie usuwane.

## Budowanie

Wymagane: stabilny Rust, Node 22+, pnpm i [wymagania Tauri](https://tauri.app/start/prerequisites/).

```bash
git clone https://github.com/slaatarsi/terax-no-ai.git
cd terax-no-ai
pnpm install
pnpm tauri dev
# Pakiet produkcyjny:
pnpm tauri build
```

**Uwaga:** konfiguracja aktualizacji nadal wskazuje wydania upstream. Przyjęcie takiej aktualizacji może zastąpić ten fork oryginalną wersją. Instalatory i pakiety upstream nie są tą wersją bez AI. Nie gwarantujemy podpisów właściwych dla tego forka.

Pełne instrukcje i ograniczenia dystrybucji opisuje [angielski README](../../README.md). Zobacz też [dokumentację](../README.md), [zasady współtworzenia](../../CONTRIBUTING.md) i [bezpieczeństwo](../../SECURITY.md). Problemy zgłaszaj w repozytorium tego forka.

Licencja [Apache-2.0](../../LICENSE). Oryginalne informacje o autorach i licencjach pozostają zachowane.
