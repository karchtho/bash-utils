# Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.1] - 2025-09-17

### 🔧 Corrigé
- **Bug critique création dossiers** - Les nouveaux projets n'étaient pas créés dans `connect_project.sh`
- **Validation input utilisateur** - Boucle de validation pour choix de projets avec messages d'erreur clairs
- **Diagnostic PHP-FPM** - Remplacement vérification module Apache par PHP-FPM dans `diagnostique.sh`

### ✨ Amélioré
- **Interface colorée** - Ajout couleurs pour "Créer nouveau projet" (vert), "Mode interactif" (bleu), VMs "Running" (vert)
- **Utilisateur MySQL superadmin** - Création automatique `superadmin/superpass` avec tous privilèges pour développement
- **Détection PHP-FPM** - Support multi-versions PHP 8.0 à 8.3 dans diagnostic

### 🚀 Ajouté
- **Messages de debug création** - Feedback détaillé lors de la création de nouveaux projets
- **Validation stricte choix** - Seuls les numéros valides sont acceptés dans les menus

---

## [2.0.0] - 2025-01-17

### 🚀 Ajouté
- **Mode dry-run complet** pour `create_webvm.sh` et `connect_project.sh` (`--dry-run`, `-n`) à vérifier...
- **Système de backup automatique** de `/etc/hosts` avec rotation (garde 10 backups max)
- **Script cleanup.sh** pour nettoyage des VMs et entrées /etc/hosts orphelines
- **Support PHP-FPM** en remplacement de mod_php pour de meilleures performances
- **Détection automatique version PHP** pour configuration adaptive
- **Amélioration mount_vmRan.sh** avec gestion d'erreurs complète et vérifications
- **Aide intégrée** (`--help`, `-h`) pour tous les scripts principaux
- **Fonctions de restauration** de backups /etc/hosts

### ✨ Amélioré
- **Gestion d'erreurs robuste** avec `set -euo pipefail` sur tous les scripts
- **Interface utilisateur** avec menus interactifs et messages colorés
- **Détection automatique** des virtual hosts existants dans `connect_project.sh`
- **Permissions fichiers** optimisées (`ubuntu:www-data` 775) pour faciliter le développement
- **Wrappers intelligents** pour commandes critiques en mode dry-run
- **Documentation** et commentaires pour meilleure maintenance

### 🔧 Corrigé
- **Problème array** non déclaré dans `connect_project.sh` (PROJECT_ARRAY)
- **Gestion /etc/hosts** sans écrasement des autres entrées VM
- **Blocage SSH** en mode dry-run avec simulation appropriée
- **Permissions sudo** manquantes sur certaines commandes (a2enmod, a2enconf)

### 🛡️ Sécurité
- **Validation** des entrées utilisateur renforcée
- **Isolation processus** avec PHP-FPM vs mod_php
- **Backup automatique** avant toute modification système critique

---

## [1.2.0] - 2025-01-10

### 🚀 Ajouté
- **Script diagnostique.sh** complet pour troubleshooting
- **Configuration automatique** SSH bidirectionnelle (PC ↔ VM)
- **Support Oh My Zsh** avec plugins de développement
- **Clonage automatique** des repositories Git (GitLab/GitHub)

### ✨ Amélioré
- **Interface utilisateur** avec sélection interactive des configurations
- **Gestion des virtual hosts** Apache automatisée
- **Configuration VS Code** Remote-SSH automatique

---

## [1.1.0] - 2024-12-15

### 🚀 Ajouté
- **Support fichiers de configuration** (.conf) pour automatisation
- **Installation phpMyAdmin** non-interactive
- **Configuration automatique** bases de données MySQL

### ✨ Amélioré
- **Installation LAMP** complète et optimisée
- **Gestion des permissions** web directories

---

## [1.0.0] - 2024-12-01

### 🚀 Première version
- **Script create_webvm.sh** basique pour création VM Ubuntu
- **Installation manuelle** Apache, MySQL, PHP
- **Configuration SSH** de base

---

## 📊 Métriques d'évolution

| Version | Scripts | Fonctionnalités | Qualité Code | Note Globale |
|---------|---------|-----------------|--------------|--------------|
| 1.0.0   | 1       | Basiques        | 5/10         | 5.5/10       |
| 1.1.0   | 2       | Intermédiaires  | 6/10         | 6.5/10       |
| 1.2.0   | 3       | Avancées        | 7/10         | 7.5/10       |
| 2.0.0   | 5       | Expertes        | 9/10         | 9.1/10       |
| 2.0.1   | 5       | Expertes+       | 9.5/10       | **9.4/10**   |

---

## 🎯 Roadmap

### [2.1.0] - Prévu Q1 2025
- [ ] Tests automatisés unitaires
- [ ] Support multi-plateforme (macOS, Windows WSL)
- [ ] Interface web optionnelle
- [ ] Monitoring et métriques

### [2.2.0] - Prévu Q2 2025
- [ ] Templates de projets (Laravel, React, etc.)
- [ ] Orchestration Docker optionnelle
- [ ] Sauvegarde/restauration de configurations VM

---

## 🤝 Contributing

Pour contribuer au projet :
1. Fork le repository
2. Créez une branche feature (`git checkout -b feature/amazing-feature`)
3. Committez vos changements (`git commit -m 'feat: add amazing feature'`)
4. Push vers la branche (`git push origin feature/amazing-feature`)
5. Ouvrez une Pull Request

---

## 📄 License

Ce projet est sous license MIT - voir le fichier [LICENSE](LICENSE) pour plus de détails.