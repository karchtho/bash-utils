# Création et connexion VM Multipass — Guide complet

## Vue d'ensemble

Ce dépôt contient des scripts pour automatiser la création et la gestion de machines virtuelles Multipass destinées au développement web.

### Scripts principaux

- **`create_webvm.sh`** — Création et configuration complète d'une VM avec stack LAMP
- **`connect_project.sh`** — Utilitaire de connexion et gestion des projets
- **`diagnostique.sh`** — Outil de diagnostic et dépannage

## Objectifs

### Automatisation du développement
- Création rapide d'environnements de développement isolés
- Configuration automatique du stack LAMP (Linux, Apache, MariaDB, PHP)
- Intégration avec VS Code Remote-SSH
- Gestion des projets et bases de données

### Apprentissage
- Comprendre le provisioning de VM avec Multipass
- Maîtriser la configuration SSH et les virtual hosts
- Apprendre l'automatisation de l'installation de services

## Prérequis

### Logiciels requis
- **Multipass** installé sur la machine hôte
- **SSH** avec `ssh-keygen` disponible
- **Accès sudo** pour éditer `/etc/hosts`
- **VS Code** avec l'extension Remote-SSH (optionnel)

### Outils optionnels
- `xclip` pour la copie automatique d'URL dans le presse-papier
- `google-chrome` ou `chromium` pour l'ouverture automatique du navigateur

## Résolution des problèmes courants

### Connexion SSH VS Code
Si VS Code Remote-SSH ne fonctionne pas :
1. Vérifiez le fichier `~/.ssh/config`
2. Vérifiez les permissions du dossier `~/.ssh` (doit être 700)
3. Utilisez le script de diagnostic : `./diagnostique.sh`


## Configuration

### Fichiers de configuration

Les scripts utilisent des fichiers `.conf` dans le dossier `config/` pour automatiser la configuration.

#### Exemple : `config/mon-projet.conf`

```bash
# Configuration de la VM
VM_NAME="webvm-projet"
PROJECT_NAME="mon-projet"
VHOST_DOMAIN="mon-projet.local"

# Configuration Git
GIT_USER_NAME="John Doe"
GIT_USER_EMAIL="john.doe@example.com"
GITLAB_REPO="git@gitlab.com:user/mon-projet.git"
GITHUB_REPO=""  # Laisser vide si non utilisé

# Ressources VM
CPUS=2
MEM="4G"
DISK="15G"

# Base de données
DB_USER="projet_user"
DB_PASS="mot_de_passe_securise"
DB_NAME="mon_projet_db"
PHPMYADMIN_PASS="admin_phpmyadmin"

# Options avancées
INSTALL_OHMYZSH="yes"  # Installer Oh My Zsh (optionnel)
```

### Variables disponibles

| Variable | Description | Valeur par défaut |
|----------|-------------|-------------------|
| `VM_NAME` | Nom de la VM Multipass | Demandé interactivement |
| `PROJECT_NAME` | Nom du projet web | Demandé interactivement |
| `VHOST_DOMAIN` | Domaine local (ex: projet.local) | Optionnel |
| `CPUS` | Nombre de cœurs CPU | 2 |
| `MEM` | Mémoire allouée | 4G |
| `DISK` | Espace disque | 15G |
| `DB_NAME` | Nom de la base de données | `${PROJECT_NAME}_db` |
| `INSTALL_OHMYZSH` | Installer Oh My Zsh | Demandé interactivement |

## Installation

### Ajout des scripts au PATH (Recommandé)

Pour pouvoir utiliser les scripts depuis n'importe quel répertoire :

```bash
# Pour Bash
echo 'export PATH="$PATH:/home/thomas/Documents/CDA 2025/Utilities/script-de-creation-vm-multipass"' >> ~/.bashrc
source ~/.bashrc

# Pour Zsh
echo 'export PATH="$PATH:/home/thomas/Documents/CDA 2025/Utilities/script-de-creation-vm-multipass"' >> ~/.zshrc
source ~/.zshrc
```

### Préparation des permissions

```bash
chmod +x create_webvm.sh
chmod +x connect_project.sh
chmod +x diagnostique.sh
```

## Utilisation

Une fois installé, les scripts sont disponibles depuis n'importe où :

1. **Création d'une VM**
   ```bash
   create_webvm.sh
   ```

2. **Connexion à la VM**
   ```bash
   connect_project.sh
   ```

3. **Diagnostic en cas de problème**
   ```bash
   diagnostique.sh                           # Diagnostic général
   diagnostique.sh VM_NAME                   # VM spécifique
   diagnostique.sh VM_NAME PROJECT_NAME      # + vérifications projet
   ```

### Workflow complet

1. Créer un fichier de configuration dans `config/`
2. Exécuter `create_webvm.sh` pour créer la VM
3. Ajouter la clé SSH publique de la VM sur GitLab/GitHub (si demandé)
4. Utiliser `connect_project.sh` pour accéder au projet
5. Développer avec VS Code Remote-SSH

### Nouvelles fonctionnalités

- **Interface colorée** : Sélection de fichiers de configuration avec couleurs pour améliorer la lisibilité
- **Exécution globale** : Scripts disponibles depuis n'importe quel répertoire après ajout au PATH
- **Diagnostic amélioré** : Interface colorée avec statuts des VMs en couleur selon leur état

## Ressources créées

### Dans la VM
- **Système** : Ubuntu 24.04 avec stack LAMP
- **Web** : Apache2 avec virtual host optionnel
- **Base de données** : MariaDB + phpMyAdmin
- **Développement** : Git, SSH, Oh My Zsh (optionnel)
- **Projets** : Dossier `/var/www/html/PROJECT_NAME`

### Sur l'hôte
- **Configuration SSH** : `~/.ssh/config` mis à jour pour VS Code
- **Virtual hosts** : `/etc/hosts` configuré pour domaines locaux
- **Clés SSH** : Génération et configuration automatique
