# Guide détaillé — Script de connexion VM

Ce document explique en détail le fonctionnement du script `connect_project.sh` qui permet de se connecter facilement aux VMs Multipass et de gérer les projets.

## Vue d'ensemble

Le script `connect_project.sh` automatise :
- La sélection et le démarrage de VMs existantes
- La gestion des projets dans `/var/www/html/`
- **Le choix de l'architecture web (directe ou MVC)**
- La configuration SSH et des virtual hosts avec DocumentRoot adapté
- L'ouverture automatique du navigateur
- La gestion automatique des backups `/etc/hosts`

## 1. En-tête du script

```bash
#!/bin/bash
```

* Indique que le script doit être exécuté avec `bash`.
* C’est la première instruction d’un script shell pour choisir l’interpréteur.

---

## 2. Sélection du fichier de configuration

```bash
CONFIG_FILES=(./config/*.conf)

if [ ! -e "${CONFIG_FILES[0]}" ]; then
    echo "⚠️ Aucun fichier .conf trouvé dans ./config/, passage en mode interactif."
else
    echo "📌 Sélectionne un fichier de configuration :"
    select CONFIG_FILE in "${CONFIG_FILES[@]}" "Aucune / Mode interactif"; do
        if [ "$CONFIG_FILE" == "Aucune / Mode interactif" ]; then
            echo "⚠️ Mode interactif choisi."
            break
        elif [ -n "$CONFIG_FILE" ]; then
            echo "✅ Fichier choisi : $CONFIG_FILE"
            source "$CONFIG_FILE"
            break
        fi
    done
fi
```

* `CONFIG_FILES=(./config/*.conf)` : crée un tableau des fichiers `.conf` présents dans `./config/`.
* `if [ ! -e "${CONFIG_FILES[0]}" ]` : teste si au moins un fichier existe.
* Si aucun fichier, on affiche un message et on bascule en mode interactif.
* Sinon, on affiche un menu `select` listant les fichiers et une option "Aucune / Mode interactif".
* Quand l’utilisateur choisit un fichier, `source "$CONFIG_FILE"` charge les variables définies dans ce fichier (ex. `VM_NAME`, `PROJECT_NAME`, `VHOST_DOMAIN`).

---

## 3. Sélection de la VM

```bash
if [ -z "${VM_NAME:-}" ]; then
    echo "📌 Liste des VMs disponibles :"
    multipass list | awk 'NR>1 {print NR-1 ") " $1 " [" $2 "]"}'

    echo
    read -p "➡️ Choisis le numéro de la VM ou entre un nom manuellement : " CHOICE
    if [[ "$CHOICE" =~ ^[0-9]+$ ]]; then
        VM_NAME=$(multipass list | awk "NR==$((CHOICE+1)){print \$1}")
    else
        VM_NAME="$CHOICE"
    fi
fi
```

* `if [ -z "${VM_NAME:-}" ]` : si `VM_NAME` n’a pas été défini par le `.conf`.
* `multipass list` : liste les VM ; le `awk` formate la sortie pour afficher une liste numérotée (sans en-tête).
* On demande à l’utilisateur de choisir soit par numéro soit en tapant un nom.
* Si l’entrée est un nombre, le script récupère le nom de la VM correspondant ; sinon il prend la valeur saisie comme nom de VM.

---

## 4) Vérification que la VM existe

```bash
if ! multipass info "$VM_NAME" &>/dev/null; then
    echo "❌ La VM '$VM_NAME' n'existe pas !"
    exit 1
fi
```

* `multipass info "$VM_NAME"` : vérifie l’existence de la VM.
* Si la commande échoue, le script termine avec un message d’erreur.

---

## 5) Choix / création du projet sur la VM et sélection d'architecture

### 5a) Sélection du projet

```bash
if [ -z "${PROJECT_NAME:-}" ]; then
    echo "📌 Recherche des projets dans la VM ($VM_NAME)..."
    PROJECTS=$(multipass exec "$VM_NAME" -- bash -c "ls /var/www/html/ 2>/dev/null || true")
    # ...logique de sélection/création de projet...
fi
```

### 5b) **Nouveauté : Choix de l'architecture web**

```bash
# --- WEB_ROOT_TYPE ---
if [ -z "${WEB_ROOT_TYPE:-}" ]; then
    echo "📌 Choix du répertoire web pour le projet '$PROJECT_NAME' :"
    echo "1) Projet direct → /var/www/html/$PROJECT_NAME"
    echo "2) Architecture MVC → /var/www/html/$PROJECT_NAME/public"

    while true; do
        read -p "➡️ Choix (1 ou 2) [1] : " WEB_ROOT_CHOICE
        WEB_ROOT_CHOICE=${WEB_ROOT_CHOICE:-1}

        case $WEB_ROOT_CHOICE in
            1) WEB_ROOT_TYPE="direct" ; break ;;
            2) WEB_ROOT_TYPE="public" ; break ;;
            *) echo "❌ Choix invalide. Veuillez entrer 1 ou 2." ;;
        esac
    done
fi

# Définir WEB_ROOT_PATH selon le type choisi
if [ "$WEB_ROOT_TYPE" = "public" ]; then
    WEB_ROOT_PATH="/var/www/html/$PROJECT_NAME/public"
    echo "✅ Répertoire web : $WEB_ROOT_PATH (architecture MVC)"

    # Vérifier si le dossier public existe, sinon le créer
    if ! multipass exec "$VM_NAME" -- test -d "$WEB_ROOT_PATH"; then
        echo "📁 Création du dossier public..."
        multipass exec "$VM_NAME" -- sudo mkdir -p "$WEB_ROOT_PATH"
        multipass exec "$VM_NAME" -- sudo chown ubuntu:www-data "$WEB_ROOT_PATH"
        multipass exec "$VM_NAME" -- sudo chmod 775 "$WEB_ROOT_PATH"
        echo "✅ Dossier public créé"
    fi
else
    WEB_ROOT_PATH="/var/www/html/$PROJECT_NAME"
    echo "✅ Répertoire web : $WEB_ROOT_PATH (projet direct)"
fi
```

### **Fonctionnalités d'architecture**

* **Architecture directe** : Le serveur web pointe directement vers le dossier projet
* **Architecture MVC** : Le serveur web pointe vers le sous-dossier `public/`
* **Création automatique** : Le dossier `public` est créé si nécessaire avec les bonnes permissions
* **Configuration dans les fichiers .conf** : Peut être prédéfini via `WEB_ROOT_TYPE="public"`

Cette fonctionnalité est essentielle pour les frameworks PHP modernes (Laravel, Symfony, CodeIgniter, etc.) qui utilisent une architecture MVC avec un dossier `public` comme point d'entrée web.

---

## 6) Saisie du domaine VHOST avec détection automatique

```bash
if [ -z "${VHOST_DOMAIN:-}" ]; then
    # Recherche d'un virtual host existant pour ce projet
    echo "🔍 Recherche d'un virtual host existant pour le projet '$PROJECT_NAME'..."
    EXISTING_VHOST=$(multipass exec "$VM_NAME" -- bash -c "
        for conf in /etc/apache2/sites-available/*.conf; do
            if [ -f \"\$conf\" ] && grep -q \"DocumentRoot ${WEB_ROOT_PATH}\" \"\$conf\" 2>/dev/null; then
                grep 'ServerName' \"\$conf\" | awk '{print \$2}' | head -1
            fi
        done
    ")

    if [ -n "$EXISTING_VHOST" ]; then
        echo "✅ Virtual host trouvé : $EXISTING_VHOST"
        read -p "Utiliser ce vhost existant ? [Y/n] : " USE_EXISTING
        if [ "${USE_EXISTING:-Y}" = "Y" ] || [ "${USE_EXISTING:-Y}" = "y" ]; then
            VHOST_DOMAIN="$EXISTING_VHOST"
        else
            read -p "Nom de domaine du vhost (laisser vide si non utilisé) : " VHOST_DOMAIN
        fi
    else
        read -p "Nom de domaine du vhost (laisser vide si non utilisé) : " VHOST_DOMAIN
    fi
fi
```

### **Améliorations VHOST**

* **Détection automatique** : Recherche les virtual hosts existants qui pointent vers le bon DocumentRoot
* **Proposition intelligente** : Si un vhost est trouvé, le propose à l'utilisateur
* **Compatibilité architecture** : Prend en compte le `WEB_ROOT_PATH` selon l'architecture choisie

---

## 7) Vérification présence de la clé SSH locale

```bash
SSH_KEY="$HOME/.ssh/id_ed25519"
if [ ! -f "$SSH_KEY" ]; then
    echo "⚠️  Clé SSH non trouvée : $SSH_KEY"
    echo "👉 Génère une clé avec : ssh-keygen -t ed25519 -f $HOME/.ssh/id_ed25519"
    exit 1
fi
```

* Définit la variable `SSH_KEY` pointant vers la clé privée attendue.
* Si le fichier n’existe pas, affiche un message et quitte. (Le script attend que la clé existe avant de continuer.)

---

## 8) Vérification / démarrage de la VM (état)

```bash
VM_STATE=$(multipass info "$VM_NAME" | grep "State:" | awk '{print $2}')
if [ "$VM_STATE" != "Running" ]; then
    echo "⏯️ VM $VM_NAME arrêtée. Démarrage..."
    multipass start "$VM_NAME"
    echo "⏳ Attente que la VM soit prête..."
    sleep 5
else
    echo "ℹ️ VM $VM_NAME est déjà en cours d'exécution."
fi
```

* `multipass info` pour récupérer l’état (`State:`) de la VM.
* Si l’état n’est pas `Running`, le script lance `multipass start` puis attend 5 secondes.
* Sinon, affiche un message indiquant que la VM est déjà active.

---

## 9) Récupération de l’adresse IP de la VM

```bash
IP=$(multipass info "$VM_NAME" | grep IPv4 | awk '{print $2}')
if [ -z "$IP" ]; then
    echo "❌ Impossible de récupérer l'IP de la VM."
    exit 1
fi
```

* Extrait la colonne `IPv4` depuis la sortie de `multipass info`.
* Si aucune IP n’est trouvée, le script s’arrête.

---

## 10) Mise à jour du fichier `/etc/hosts` avec backup automatique

```bash
if [ -n "${VHOST_DOMAIN:-}" ]; then
    echo "🔄 Modification de /etc/hosts..."
    backup_hosts  # Backup automatique avant modification

    sudo sed -i "\|$VHOST_DOMAIN|d" /etc/hosts
    echo "$IP $VHOST_DOMAIN" | sudo tee -a /etc/hosts > /dev/null
    echo "✅ /etc/hosts mis à jour : $IP $VHOST_DOMAIN"
    LOCAL_HOSTNAME="$VHOST_DOMAIN"

    # Configuration du virtual host Apache avec architecture adaptée
    echo "🔧 Configuration du virtual host Apache..."
    VHOST_CONFIG="<VirtualHost *:80>
    ServerName $VHOST_DOMAIN
    DocumentRoot ${WEB_ROOT_PATH}
    <Directory ${WEB_ROOT_PATH}>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/${VHOST_DOMAIN}_error.log
    CustomLog \${APACHE_LOG_DIR}/${VHOST_DOMAIN}_access.log combined
</VirtualHost>"

    # Créer le fichier de configuration sur la VM
    multipass exec "$VM_NAME" -- bash -c "echo '$VHOST_CONFIG' | sudo tee /etc/apache2/sites-available/${VHOST_DOMAIN}.conf > /dev/null"

    # Activer le site et redémarrer Apache
    multipass exec "$VM_NAME" -- sudo a2ensite "${VHOST_DOMAIN}.conf"
    multipass exec "$VM_NAME" -- sudo systemctl reload apache2

    echo "✅ Virtual host configuré pour $VHOST_DOMAIN → ${WEB_ROOT_PATH}"
else
    echo "⚠️ Aucun VHOST_DOMAIN défini, utilisation de l'IP directe."
    LOCAL_HOSTNAME="$IP"
fi
```

### **Améliorations /etc/hosts et VHOST**

* **Backup automatique** : Sauvegarde `/etc/hosts` avant modification avec timestamp
* **Gestion des backups** : Conservation des 10 derniers backups, nettoyage automatique
* **DocumentRoot adaptatif** : Le virtual host pointe vers le bon répertoire selon l'architecture
* **Configuration complète** : Logs séparés, support .htaccess, permissions correctes

---

## 11) Démarrage de l’agent SSH et ajout de la clé

```bash
eval "$(ssh-agent -s)"
ssh-add "$SSH_KEY"
```

* `eval "$(ssh-agent -s)"` lance un agent SSH en arrière-plan et exporte les variables d’environnement nécessaires (`SSH_AGENT_PID`, `SSH_AUTH_SOCK`).
* `ssh-add "$SSH_KEY"` ajoute la clé privée à l’agent pour permettre les connexions sans ressaisir la passphrase (si la clé en a une).

---

## 12) Construction de l’URL du projet et copie dans le presse-papier

```bash
PROJECT_URL="http://$LOCAL_HOSTNAME/"

if command -v xclip &> /dev/null; then
    echo -n "$PROJECT_URL" | xclip -selection clipboard
    CLIP_MSG=" (copié dans le presse-papier)"
else
    CLIP_MSG=""
fi
```

* `PROJECT_URL` prend soit le domaine, soit l’IP, précédé de `http://`.
* Vérifie si `xclip` est disponible (`command -v xclip`).
* Si présent, copie l’URL dans le presse-papier et définit `CLIP_MSG` pour l’affichage final.

---

## 13) Ouverture automatique du navigateur

```bash
if command -v google-chrome &> /dev/null; then
    google-chrome "$PROJECT_URL" &
elif command -v chromium &> /dev/null; then
    chromium "$PROJECT_URL" &
else
    xdg-open "$PROJECT_URL" &
fi
```

* Teste la présence de `google-chrome` puis `chromium`.
* Si l’un est présent, l’exécute en arrière-plan avec l’URL.
* Sinon, utilise `xdg-open` (ouvre l’URL avec le navigateur par défaut de l’environnement graphique).

---

## 14) Affichage final avec informations d'architecture

```bash
echo "✅ Connexion prête !"
echo "➡️ SSH : ssh ubuntu@$IP"
echo "➡️ Projet dans la VM : /var/www/html/$PROJECT_NAME"
echo "➡️ Répertoire web : ${WEB_ROOT_PATH}"
echo "🌐 URL : $PROJECT_URL$CLIP_MSG"
```

### **Informations enrichies**

* **Commande SSH** : `ssh ubuntu@<IP>` pour accéder à la VM
* **Emplacement du projet** : Dossier racine du projet (`/var/www/html/<PROJECT_NAME>`)
* **Répertoire web** : Point d'entrée web effectif (peut différer selon l'architecture)
* **URL d'accès** : Lien direct vers le projet, copié dans le presse-papier si `xclip` disponible

### **Mode dry-run**

Le script inclut un mode `--dry-run` qui simule toutes les actions sans les exécuter réellement :

```bash
./connect_project.sh --dry-run
```

Affiche un résumé complet des actions qui seraient effectuées :
- VM et projet sélectionnés
- Architecture et répertoire web
- Modifications `/etc/hosts`
- Configuration virtual host
- URL finale

---
