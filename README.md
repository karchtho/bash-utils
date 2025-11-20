# Scripts Bash - Collection d'Automatisation

> Une collection de scripts bash pour automatiser des tâches de développement, apprentissage et déploiement. Réunis à partir de différents projets et expériences d'apprentissage.

## 📦 Contenu

Ce dépôt contient plusieurs groupes de scripts, chacun résolvant des problèmes spécifiques :

### 1. **Config Projets MVC PHP** (`Config Projets MVC PHP/`)
Scripts pour scaffolding et gestion de projets MVC PHP.

| Script | Description |
|--------|-------------|
| `config.sh` | Configuration centralisée du projet (variables globales) |
| `creation-arborescence.sh` | Génère l'arborescence complète d'un projet MVC PHP |
| `modele_tickets.sh` | Crée les templates GitLab pour issues/tickets |

**Cas d'usage** : Initialiser rapidement une nouvelle structure de projet MVC avec dossiers standards et documentation de base.

### 2. **Creation VM Multipass - LAMP** (`Creation VM Multipass - LAMP/`)
Suite complète pour créer et gérer des VMs de développement avec stack LAMP.

| Script | Description |
|--------|-------------|
| `create_webvm.sh` | Crée et configure une VM Ubuntu avec Apache, MySQL, PHP |
| `connect_project.sh` | Connecte un projet à la VM, gère les vhosts et domaines locaux |
| `cleanup.sh` | Nettoie les VMs, configurations SSH et entrées `/etc/hosts` |
| `diagnostique.sh` | Diagnostic complet de la VM et du projet |
| `mount_vmRan.sh` | Monte un répertoire du host dans la VM |

**Cas d'usage** : Créer rapidement des environnements de développement PHP isolés avec configuration automatique.

**Documentation** : Voir [Creation VM Multipass - LAMP/README.md](./Creation%20VM%20Multipass%20-%20LAMP/README.md)

### 3. **React** (`React/`)
Outils pour scaffolding de composants React.

| Script | Description |
|--------|-------------|
| `create-component.sh` | Génère un composant React avec structure standard |

**Cas d'usage** : Accélérer la création de composants React avec structure cohérente.

---

## 🎯 Objectif du Dépôt

Ce dépôt sert de **collection centralisée** et **référence** pour :

- ✅ **Automatiser** des tâches répétitives de développement
- 📚 **Documenter** les processus et bonnes pratiques bash
- 🧪 **Apprendre** et expérimenter avec bash, automation, et DevOps
- 🔄 **Réutiliser** du code testé dans différents projets
- 📖 **Consulter** des exemples de scripts bien structurés

---

## ⚡ Démarrage Rapide

### Prérequis
- Bash 4.0+
- Outils spécifiques selon le script (Multipass, Git, etc.)
- Accès sudo pour certaines opérations

### Installation

```bash
# Cloner le dépôt
git clone <repo-url> scripts-bash
cd scripts-bash

# Rendre les scripts exécutables
chmod +x **/*.sh

# Utiliser directement dans le dossier approprié
cd "Creation VM Multipass - LAMP"
./create_webvm.sh
```

---

## 📋 Structure du Projet

```
scripts-bash/
├── README.md                          # Ce fichier
│
├── Config Projets MVC PHP/
│   ├── config.sh                      # Configuration centralisée
│   ├── creation-arborescence.sh       # Scaffolding MVC
│   ├── modele_tickets.sh              # Templates GitLab
│   └── README.md
│
├── Creation VM Multipass - LAMP/
│   ├── create_webvm.sh                # Création VM
│   ├── connect_project.sh             # Gestion projets
│   ├── cleanup.sh                     # Nettoyage
│   ├── diagnostique.sh                # Diagnostics
│   ├── mount_vmRan.sh                 # Montage disques
│   ├── README.md                      # Documentation complète
│   ├── CHANGELOG.md                   # Historique des versions
│   ├── config/                        # Fichiers de configuration
│   │   ├── example.conf
│   │   └── environments/
│   │       ├── development.env
│   │       ├── test.env
│   │       └── production.env
│   └── doc/                           # Documentation détaillée
│
└── React/
    ├── create-component.sh            # Générateur de composants
    └── README.md
```

---

## 🛠️ Utilisation par Cas d'Usage

### Créer une nouvelle structure MVC PHP
```bash
cd "Config Projets MVC PHP"
./creation-arborescence.sh
```

### Créer une VM de développement LAMP
```bash
cd "Creation VM Multipass - LAMP"
./create_webvm.sh
```

### Générer un composant React
```bash
cd React
./create-component.sh mon-composant
```

---

## 📚 Documentation

Chaque dossier contient sa propre documentation :

- **[Creation VM Multipass - LAMP/README.md](./Creation%20VM%20Multipass%20-%20LAMP/README.md)** - Guide complet avec exemples
- **[Creation VM Multipass - LAMP/CHANGELOG.md](./Creation%20VM%20Multipass%20-%20LAMP/CHANGELOG.md)** - Historique des versions
- **[Creation VM Multipass - LAMP/doc/](./Creation%20VM%20Multipass%20-%20LAMP/doc/)** - Guides détaillés par script

---

## ✅ Qualité du Code

Tous les scripts sont validés avec :
- **ShellCheck** - Analyse statique bash
- **set -euo pipefail** - Gestion stricte des erreurs
- **Proper quoting** - Prévention des injection
- **Error handling** - Gestion des cas d'erreur

---

## 🤝 Contributing & Améliorations

Ce dépôt accepte les contributions pour :
- Corriger les bugs
- Améliorer la documentation
- Ajouter de nouveaux scripts utiles
- Optimiser les scripts existants

**Processus** :
1. Fork le dépôt
2. Créer une branche (`git checkout -b feature/improvement`)
3. Tester vos changements
4. Commit avec message clair
5. Push et créer une Pull Request

---

## 📝 Bonnes Pratiques Appliquées

✨ **Dans ce dépôt, vous trouverez des exemples de** :

- ✅ Variables correctement quotées
- ✅ Gestion d'erreurs robuste
- ✅ Fonctions bien structurées
- ✅ Messages d'erreur explicites
- ✅ Support des paramètres
- ✅ Documentation inline
- ✅ Mode dry-run/test
- ✅ Validation d'entrées
- ✅ ShellCheck compliance

---

## 📄 License

Ces scripts sont fournis **à titre d'exemple et d'apprentissage**.
Libre d'utilisation, modification et redistribution.

---

## 📞 Support

Pour des questions sur l'utilisation spécifique :
- Consultez la **documentation du dossier** correspondant
- Vérifiez les **exemples de configuration**
- Utilisez les **scripts de diagnostic** fournis
- Reportez les **bugs** avec contexte

---

## 🎓 Apprentissage

Ce dépôt est conçu pour :
- **Débutants** : Voir des exemples de bash bien structuré
- **Intermédiaires** : Comprendre l'automatisation et DevOps
- **Avancés** : Référence et bonnes pratiques

Chaque script contient des commentaires pour expliquer la logique.

---

**Dernière mise à jour** : 2025-11-20
**Version du dépôt** : 2.0.1+ (avec corrections bash)
