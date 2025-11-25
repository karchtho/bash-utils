# Guide détaillé — Script de cleanup

Ce document explique en détail le fonctionnement du script `cleanup.sh` qui permet de nettoyer et supprimer les VMs Multipass ainsi que leurs configurations associées.

## 🚀 Utilisation

```bash
# Lancer le menu interactif
./cleanup.sh

# Rendre le script exécutable si nécessaire
chmod +x cleanup.sh
```

## 🎯 Fonctionnalités du menu

### 1. 📋 Lister toutes les VMs
Affiche toutes les VMs Multipass avec leur état (Running, Stopped, etc.)

```bash
multipass list
```

### 2. 🗑️ Supprimer une VM spécifique
- Liste les VMs disponibles
- Permet de choisir une VM à supprimer
- Demande confirmation avant suppression
- Arrête la VM avant de la supprimer
- Exécute `multipass purge` pour libérer l'espace

### 3. 🗑️ Supprimer toutes les VMs arrêtées
- Identifie automatiquement les VMs avec l'état "Stopped"
- Affiche la liste des VMs concernées
- Demande confirmation globale
- Supprime toutes les VMs arrêtées en lot

### 4. 🧹 Nettoyer les entrées /etc/hosts orphelines
- **Backup automatique** de `/etc/hosts` avec timestamp
- Identifie les VMs actives via `multipass list`
- Détecte les entrées `/etc/hosts` qui pointent vers des IPs non utilisées
- Filtre les IP privées (172.x, 10.x, 192.168.x)
- Supprime les entrées orphelines après confirmation

```bash
# Exemple d'entrées détectées comme orphelines
172.28.10.15 ancien-projet.local
10.0.2.100 test-vm.local
```

### 5. 🗑️ Nettoyer les configurations SSH orphelines
**Nouvelle fonctionnalité !** Nettoie les configurations SSH dans `~/.ssh/config` :

- **Backup automatique** de `~/.ssh/config` et `~/.ssh/known_hosts`
- Détecte les hosts SSH qui ne correspondent plus à une VM active
- Filtre intelligemment (exclut github.com, gitlab.com, localhost, etc.)
- Supprime les blocs Host complets de la configuration
- Nettoie les entrées `known_hosts` correspondantes

```bash
# Exemple de configuration SSH orpheline détectée
Host ancienne-vm
    HostName 192.168.64.10
    User ubuntu
    IdentityFile ~/.ssh/id_ed25519
    ForwardAgent yes
```

### 6. 📁 Gérer les backups /etc/hosts
Menu secondaire pour la gestion des backups :

#### Restaurer un backup
- Liste tous les backups disponibles avec dates
- Permet de sélectionner un backup à restaurer
- **Crée un backup de l'état actuel** avant restauration

#### Supprimer tous les backups
- Supprime le répertoire `/tmp/hosts_backups` complet
- Demande confirmation

### 7. 🔄 Nettoyage complet (DANGER!)
**Attention : Cette option supprime TOUT !**

Confirmation requise : tapez `"SUPPRIMER"` exactement

Actions effectuées :
1. **Backup de sécurité** de `/etc/hosts` et configurations SSH
2. **Arrêt et suppression** de toutes les VMs Multipass
3. **Nettoyage `/etc/hosts`** : supprime toutes les IP privées
4. **Nettoyage SSH** : supprime tous les hosts sans domaine
5. **Suppression des backups** : vide `/tmp/hosts_backups`

### 8. ❌ Quitter
Ferme le menu proprement.

## 🛡️ Sécurité et backups

### Système de backup automatique
- **Backup `/etc/hosts`** : Avant chaque modification
- **Backup SSH** : Avant chaque nettoyage
- **Conservation** : 10 backups maximum, nettoyage automatique
- **Emplacement** : `/tmp/hosts_backups/`
- **Format** : `hosts.backup.YYYY-MM-DD-HHhMM`

### Stratégie de backup SSH
```bash
# Exemples de fichiers de backup
~/.ssh/config.backup.2024-01-15-14h30
~/.ssh/known_hosts.backup.2024-01-15-14h30
~/.ssh/config.full-cleanup-backup.2024-01-15-15h00
```

## 🎯 Cas d'usage typiques

### Développeur qui change souvent de projets
```bash
# Nettoyer les VMs arrêtées régulièrement
./cleanup.sh → Option 3

# Nettoyer /etc/hosts une fois par semaine
./cleanup.sh → Option 4
```

### Problème de configuration SSH VS Code
```bash
# Nettoyer les configurations SSH orphelines
./cleanup.sh → Option 5
```

### Reset complet de l'environnement
```bash
# ATTENTION : Supprime tout !
./cleanup.sh → Option 7 → Taper "SUPPRIMER"
```

### Récupération après erreur
```bash
# Restaurer un backup de /etc/hosts
./cleanup.sh → Option 6 → Option 1
```

## 🔧 Fonctionnement technique

### Détection des VMs actives
```bash
# Récupère la liste des VMs en cours d'exécution
multipass list --format csv | awk -F',' 'NR>1 && $2=="Running" {print $1}'
```

### Filtrage des configurations SSH
```bash
# Identifie les hosts sans domaine (potentiellement des VMs)
grep "^Host " ~/.ssh/config | awk '{print $2}' | grep -v "\*" | grep -v "\."
```

### Gestion des entrées /etc/hosts
```bash
# Supprime les entrées contenant une IP spécifique
sudo sed -i "\|^192\.168\.64\.10|d" /etc/hosts
```

## ⚠️ Avertissements

1. **Backups** : Toujours créés automatiquement, mais vérifiez-les !
2. **Nettoyage complet** : Irréversible, utilisez avec précaution
3. **Permissions** : Le script demande `sudo` pour modifier `/etc/hosts`
4. **VS Code Remote-SSH** : Redémarrez VS Code après nettoyage SSH

## 🎨 Interface utilisateur

- **Couleurs** pour faciliter la navigation
- **Emojis** pour identifier rapidement les actions
- **Confirmations** multiples pour les actions destructives
- **Messages informatifs** détaillés
- **Progress feedback** pour les opérations longues

## 💡 Tips & astuces

### Utilisation régulière recommandée
```bash
# Hebdomadaire : nettoyer les VMs arrêtées
./cleanup.sh → Option 3

# Mensuel : nettoyer /etc/hosts et SSH
./cleanup.sh → Option 4 puis Option 5
```

### Avant une démonstration
```bash
# S'assurer d'un environnement propre
./cleanup.sh → Option 4 → Option 5
```

### En cas de problème réseau/SSH
```bash
# Reset des configurations SSH
./cleanup.sh → Option 5
```

Le script `cleanup.sh` est l'outil parfait pour maintenir un environnement de développement propre et organisé ! 🧹✨