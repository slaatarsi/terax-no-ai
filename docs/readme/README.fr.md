# Terax

**Un terminal léger avec un explorateur de dossiers et le suivi Git. Sans agents IA intégrés.**

Cette version est un fork de [crynta/terax-ai](https://github.com/crynta/terax-ai), modifié et maintenu séparément dans [slaatarsi/terax-no-ai](https://github.com/slaatarsi/terax-no-ai). Le projet original est l'œuvre de Crynta et des contributeurs en amont.

## Fonctionnalités

- Terminal natif avec onglets, panneaux divisés, recherche et intégration du shell.
- Explorateur de dossiers avec recherche, gestion des fichiers et mises à jour en direct.
- Suivi Git : état des fichiers, différences, indexation, commits, push et historique graphique.
- Éditeur, serveurs de langage facultatifs, aperçus et thèmes conservés comme outils complémentaires.

Aucun chat IA, agent, fournisseur IA, autocomplétion IA ou saisie vocale intégrés. Les programmes CLI peuvent toujours être lancés manuellement. Les anciennes données IA et les hooks externes ne sont ni chargés ni supprimés automatiquement.

## Compiler

Rust stable, Node 22+, pnpm et les [prérequis Tauri](https://tauri.app/start/prerequisites/) sont nécessaires.

```bash
git clone https://github.com/slaatarsi/terax-no-ai.git
cd terax-no-ai
pnpm install
pnpm tauri dev
# Paquet de production :
pnpm tauri build
```

**Attention :** la configuration de mise à jour pointe encore vers les versions en amont. Accepter une telle mise à jour peut remplacer ce fork par la version d'origine. Les installateurs et paquets en amont ne distribuent pas nécessairement cette version sans IA. Aucune signature propre au fork n'est garantie.

Le [README anglais](../../README.md) contient les instructions complètes et les limites de distribution. Voir aussi la [documentation](../README.md), le [guide de contribution](../../CONTRIBUTING.md) et la [politique de sécurité](../../SECURITY.md). Signalez les problèmes dans le dépôt de ce fork.

Licence [Apache-2.0](../../LICENSE). Les crédits et notices du projet original sont conservés.
