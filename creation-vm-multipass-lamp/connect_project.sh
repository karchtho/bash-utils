#!/bin/bash
set -euo pipefail

# -------------------------------
# GESTION MODE DRY-RUN
# -------------------------------
DRY_RUN=false

# Vérifier les paramètres de ligne de commande
for arg in "$@"; do
    case $arg in
        --dry-run|-n)
            DRY_RUN=true
            echo "🔍 MODE DRY-RUN ACTIVÉ - Aucune action ne sera réellement exécutée"
            echo
            ;;
        --help|-h)
            echo "Usage: $0 [--dry-run|-n] [--help|-h]"
            echo "  --dry-run, -n    Mode simulation (aucune action réelle)"
            echo "  --help, -h       Afficher cette aide"
            exit 0
            ;;
    esac
done

# -------------------------------
# WRAPPERS POUR MODE DRY-RUN
# -------------------------------

# Wrapper pour les commandes critiques
dry_run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        echo "🔍 [DRY-RUN] $*"
        return 0
    else
        "$@"
    fi
}

# Wrapper pour multipass
dry_run_multipass() {
    if [ "$DRY_RUN" = true ]; then
        echo "🔍 [DRY-RUN] multipass $*"
        # Simuler quelques réponses
        case "$1" in
            "info")
                if [ "$#" -eq 2 ]; then
                    echo "Name: $2"
                    echo "State: Running"
                    echo "IPv4: 192.168.64.10"
                fi
                ;;
            "list")
                echo "Name                    State             IPv4             Image"
                echo "test-vm                 Running           192.168.64.10    Ubuntu 24.04 LTS"
                ;;
            "exec")
                echo "🔍 [DRY-RUN] Exécution dans la VM: ${*:3}"
                ;;
        esac
        return 0
    else
        multipass "$@"
    fi
}

# Wrapper pour sudo
dry_run_sudo() {
    if [ "$DRY_RUN" = true ]; then
        echo "🔍 [DRY-RUN] sudo $*"
        return 0
    else
        sudo "$@"
    fi
}

# -------------------------------
# FONCTION CREATION INDEX.PHP
# -------------------------------

create_project_index_file() {
    local target_path="${WEB_ROOT_PATH:-/var/www/html/$PROJECT_NAME}"
    local web_root_type="${WEB_ROOT_TYPE:-direct}"

    echo "🔍 Vérification de l'existence d'un fichier index dans $target_path..."

    # Vérifier si un fichier index existe déjà
    local has_index
    has_index=$(dry_run_multipass exec "$VM_NAME" -- bash -c "
        if [ -f '$target_path/index.php' ] || [ -f '$target_path/index.html' ] || [ -f '$target_path/index.htm' ]; then
            echo 'exists'
        else
            echo 'none'
        fi
    ")

    if [ "$has_index" = "exists" ]; then
        echo "ℹ️ Un fichier index existe déjà, création ignorée."
        return 0
    fi

    echo "📝 Création d'un fichier index.php de démonstration..."

    # Détecter l'environnement configuré sur la VM
    local environment
    environment=$(dry_run_multipass exec "$VM_NAME" -- bash -c "
        # Essayer de détecter l'environnement via les modules/configuration PHP
        if php -m | grep -q xdebug 2>/dev/null; then
            echo 'development'
        elif php -r 'echo ini_get(\"display_errors\");' 2>/dev/null | grep -q '^1\|^On'; then
            echo 'development'
        elif php -r 'echo ini_get(\"error_reporting\");' 2>/dev/null | grep -q '^0\|^22519'; then
            echo 'production'
        else
            echo 'test'
        fi
    " 2>/dev/null || echo "unknown")

    if [ "$DRY_RUN" = true ]; then
        echo "🔍 [DRY-RUN] Création index.php avec environnement détecté: $environment"
        return 0
    fi

    # Créer le fichier index.php avec détection d'environnement
    dry_run_multipass exec "$VM_NAME" -- bash -c "cat > '$target_path/index.php' <<'EOL_INDEX'
<?php
echo '<h1>✅ Projet $PROJECT_NAME</h1>';
echo '<p>Architecture: ' . ('$web_root_type' === 'public' ? 'MVC (dossier public)' : 'Directe') . '</p>';
echo '<p>Répertoire: $target_path</p>';
echo '<p>PHP Version: ' . phpversion() . '</p>';
echo '<hr>';
echo '<h2>Informations du serveur</h2>';

// Fonction pour obtenir une valeur sécurisée du serveur
function getServerValue(\$key, \$default = 'Non disponible') {
    return isset(\$_SERVER[\$key]) && is_string(\$_SERVER[\$key]) ? \$_SERVER[\$key] : \$default;
}

echo '<p>IP Serveur: ' . getServerValue('SERVER_ADDR') . '</p>';
echo '<p>Document Root: ' . getServerValue('DOCUMENT_ROOT') . '</p>';
echo '<p>HTTP Host: ' . getServerValue('HTTP_HOST') . '</p>';
echo '<p>Server Software: ' . getServerValue('SERVER_SOFTWARE') . '</p>';
echo '<p>Script Name: ' . getServerValue('SCRIPT_NAME') . '</p>';

echo '<hr>';

// Détection automatique de l'environnement
\$environment = 'unknown';
if (extension_loaded('xdebug')) {
    \$environment = 'development';
} elseif (ini_get('display_errors')) {
    \$environment = 'development';
} elseif (ini_get('error_reporting') == 0 || ini_get('error_reporting') == 22519) {
    \$environment = 'production';
} else {
    \$environment = 'test';
}

echo '<h3>🌍 Environnement détecté: ' . \$environment . '</h3>';
if (\$environment === 'development') {
    echo '<p style=\"color: orange;\">⚠️ Mode développement - Erreurs PHP affichées</p>';
    echo '<p>🐛 Xdebug: ' . (extension_loaded('xdebug') ? 'Activé' : 'Désactivé') . '</p>';
} elseif (\$environment === 'test') {
    echo '<p style=\"color: blue;\">🧪 Mode test - Configuration optimisée pour les tests</p>';
} elseif (\$environment === 'production') {
    echo '<p style=\"color: green;\">🚀 Mode production - Configuration sécurisée</p>';
} else {
    echo '<p style=\"color: gray;\">❓ Environnement non détecté</p>';
}

echo '<hr>';
echo '<h3>📊 Informations PHP</h3>';
echo '<p>Memory Limit: ' . ini_get('memory_limit') . '</p>';
echo '<p>Max Execution Time: ' . ini_get('max_execution_time') . 's</p>';
echo '<p>Error Reporting: ' . ini_get('error_reporting') . '</p>';
echo '<p>Display Errors: ' . (ini_get('display_errors') ? 'On' : 'Off') . '</p>';
echo '<p>OPcache: ' . (extension_loaded('opcache') && ini_get('opcache.enable') ? 'Activé' : 'Désactivé') . '</p>';

echo '<hr>';
echo '<p><em>Fichier créé automatiquement par connect_project.sh</em></p>';
?>
EOL_INDEX"

    # Définir les bonnes permissions
    dry_run_multipass exec "$VM_NAME" -- sudo chown ubuntu:www-data "$target_path/index.php"
    dry_run_multipass exec "$VM_NAME" -- sudo chmod 664 "$target_path/index.php"

    echo "✅ Fichier index.php créé avec détection automatique d'environnement ($environment)"
}

# -------------------------------
# FONCTIONS DE BACKUP /etc/hosts
# -------------------------------

BACKUP_DIR="/tmp/hosts_backups"
MAX_BACKUPS=10

# Créer le répertoire de backup s'il n'existe pas
create_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        echo "📁 Répertoire de backup créé : $BACKUP_DIR"
    fi
}

# Sauvegarder /etc/hosts avec timestamp
backup_hosts() {
    if [ "$DRY_RUN" = true ]; then
        echo "🔍 [DRY-RUN] Backup de /etc/hosts vers $BACKUP_DIR/hosts.backup.$(date '+%Y-%m-%d-%Hh%M')"
        return 0
    fi

    create_backup_dir
    local timestamp
    timestamp=$(date '+%Y-%m-%d-%Hh%M')
    local backup_file="$BACKUP_DIR/hosts.backup.$timestamp"

    if cp /etc/hosts "$backup_file"; then
        echo "💾 Backup /etc/hosts créé : $backup_file"
        cleanup_old_backups
        return 0
    else
        echo "❌ Erreur lors du backup de /etc/hosts"
        return 1
    fi
}

# Nettoyer les anciens backups (garde les MAX_BACKUPS plus récents)
cleanup_old_backups() {
    local backup_count
    backup_count=$(find "$BACKUP_DIR" -maxdepth 1 -name "hosts.backup.*" -type f 2>/dev/null | wc -l)

    if [ "$backup_count" -gt "$MAX_BACKUPS" ]; then
        local to_delete=$((backup_count - MAX_BACKUPS))
        find "$BACKUP_DIR" -maxdepth 1 -name "hosts.backup.*" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | tail -n "$to_delete" | cut -d' ' -f2- | xargs rm -f
        echo "🧹 $to_delete ancien(s) backup(s) supprimé(s)"
    fi
}

# Restaurer un backup (fonction utilitaire pour plus tard)
restore_hosts_backup() {
    local backup_file="$1"
    if [ -f "$backup_file" ]; then
        backup_hosts  # Backup de l'état actuel avant restauration
        sudo cp "$backup_file" /etc/hosts
        echo "✅ /etc/hosts restauré depuis : $backup_file"
    else
        echo "❌ Backup non trouvé : $backup_file"
        return 1
    fi
}

# -------------------------------
# SELECTION DU FICHIER CONFIG
# -------------------------------
# Obtenir le répertoire du script pour trouver le dossier config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILES=("${SCRIPT_DIR}"/config/*.conf)

if [ ! -e "${CONFIG_FILES[0]}" ]; then
    echo "⚠️ Aucun fichier .conf trouvé dans ${SCRIPT_DIR}/config/, passage en mode interactif."
else
    echo "📌 Sélectionne un fichier de configuration :"

    # Créer un tableau avec les noms de fichiers colorés
    DISPLAY_OPTIONS=()
    declare -a COLORS=('\033[1;31m' '\033[1;32m' '\033[1;33m' '\033[1;34m' '\033[1;35m' '\033[1;36m' '\033[1;91m' '\033[1;92m' '\033[1;93m' '\033[1;94m')

    for i in "${!CONFIG_FILES[@]}"; do
        if [ $i -lt 10 ]; then
            filename=$(basename "${CONFIG_FILES[i]}")
            color="${COLORS[i]}"
            DISPLAY_OPTIONS+=("$(echo -e "${color}${filename}\033[0m")")
        else
            filename=$(basename "${CONFIG_FILES[i]}")
            DISPLAY_OPTIONS+=("$filename")
        fi
    done
    DISPLAY_OPTIONS+=("$(echo -e '\033[1;37mAucune / Mode interactif\033[0m')")

    select CHOICE in "${DISPLAY_OPTIONS[@]}"; do
        if [[ "$CHOICE" == *"Mode interactif"* ]]; then
            echo "⚠️ Mode interactif choisi."
            break
        elif [ -n "$CHOICE" ]; then
            # Retrouver le fichier original basé sur l'index
            CONFIG_FILE="${CONFIG_FILES[$((REPLY-1))]}"
            echo "✅ Fichier choisi : $(basename "$CONFIG_FILE")"
            # shellcheck source=/dev/null
            source "$CONFIG_FILE"
            break
        fi
    done
fi

# -------------------------------
# MODE INTERACTIF SI VARIABLES MANQUANTES
# -------------------------------

# --- VM_NAME ---
if [ -z "${VM_NAME:-}" ]; then
    echo "📌 Liste des VMs disponibles :"
    dry_run_multipass list | awk 'NR>1 {
        if ($2 == "Running")
            print NR-1 ") " $1 " [\033[1;32m" $2 "\033[0m]"
        else
            print NR-1 ") " $1 " [" $2 "]"
    }'

    echo
    read -rp "➡️ Choisis le numéro de la VM ou entre un nom manuellement : " CHOICE
    if [[ "$CHOICE" =~ ^[0-9]+$ ]]; then
        VM_NAME=$(dry_run_multipass list | awk "NR==$((CHOICE+1)){print \$1}")
    else
        VM_NAME="$CHOICE"
    fi
fi

# Vérifier que la VM existe
if ! dry_run_multipass info "$VM_NAME" &>/dev/null; then
    echo "❌ La VM '$VM_NAME' n'existe pas !"
    if [ "$DRY_RUN" = false ]; then
        exit 1
    fi
fi

# --- PROJECT_NAME ---
if [ -z "${PROJECT_NAME:-}" ]; then
    echo "📌 Recherche des projets dans la VM ($VM_NAME)..."
    PROJECTS=$(dry_run_multipass exec "$VM_NAME" -- bash -c "ls /var/www/html/ 2>/dev/null || true")

    if [ -n "$PROJECTS" ]; then
        echo "📂 Projets disponibles :"
        declare -A PROJECT_ARRAY
        i=1
        for p in $PROJECTS; do
            echo "$i) $p"
            PROJECT_ARRAY[$i]=$p
            ((i++))
        done
        echo -e "$i) \033[1;32m➕ Créer un nouveau projet\033[0m"

        while true; do
            read -rp "➡️ Choisis un projet (numéro 1-$i) : " CHOICE

            if [[ "$CHOICE" =~ ^[0-9]+$ ]] && [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le "$i" ]; then
                if [ "$CHOICE" -lt "$i" ]; then
                    PROJECT_NAME="${PROJECT_ARRAY[$CHOICE]}"
                    break
                else
                    read -rp "Nom du nouveau projet : " PROJECT_NAME
                    echo "🔧 Création du dossier /var/www/html/$PROJECT_NAME..."
                    if multipass exec "$VM_NAME" -- sudo mkdir -p "/var/www/html/$PROJECT_NAME"; then
                        echo "✅ Dossier créé"
                    else
                        echo "❌ Erreur lors de la création du dossier"
                        exit 1
                    fi

                    echo "🔧 Attribution des permissions..."
                    if multipass exec "$VM_NAME" -- sudo chown ubuntu:www-data "/var/www/html/$PROJECT_NAME"; then
                        echo "✅ Propriétaire défini"
                    else
                        echo "❌ Erreur lors du changement de propriétaire"
                    fi

                    if multipass exec "$VM_NAME" -- sudo chmod 775 "/var/www/html/$PROJECT_NAME"; then
                        echo "✅ Permissions définies"
                    else
                        echo "❌ Erreur lors du changement de permissions"
                    fi

                    echo "✅ Nouveau projet '$PROJECT_NAME' créé dans /var/www/html/"
                    break
                fi
            else
                echo "❌ Choix invalide. Veuillez entrer un numéro entre 1 et $i."
            fi
        done
    else
        echo "⚠️ Aucun projet trouvé. Création d'un nouveau projet."
        read -rp "Nom du projet : " PROJECT_NAME
        echo "🔧 Création du dossier /var/www/html/$PROJECT_NAME..."
        if multipass exec "$VM_NAME" -- sudo mkdir -p "/var/www/html/$PROJECT_NAME"; then
            echo "✅ Dossier créé"
        else
            echo "❌ Erreur lors de la création du dossier"
            exit 1
        fi

        echo "🔧 Attribution des permissions..."
        if multipass exec "$VM_NAME" -- sudo chown ubuntu:www-data "/var/www/html/$PROJECT_NAME"; then
            echo "✅ Propriétaire défini"
        else
            echo "❌ Erreur lors du changement de propriétaire"
        fi

        if multipass exec "$VM_NAME" -- sudo chmod 775 "/var/www/html/$PROJECT_NAME"; then
            echo "✅ Permissions définies"
        else
            echo "❌ Erreur lors du changement de permissions"
        fi

        echo "✅ Nouveau projet '$PROJECT_NAME' créé dans /var/www/html/"
    fi
fi

# --- WEB_ROOT_TYPE ---
if [ -z "${WEB_ROOT_TYPE:-}" ]; then
    echo "📌 Choix du répertoire web pour le projet '$PROJECT_NAME' :"
    echo "1) Projet direct → /var/www/html/$PROJECT_NAME"
    echo "2) Architecture MVC → /var/www/html/$PROJECT_NAME/public"

    while true; do
        read -rp "➡️ Choix (1 ou 2) [1] : " WEB_ROOT_CHOICE
        WEB_ROOT_CHOICE=${WEB_ROOT_CHOICE:-1}

        case $WEB_ROOT_CHOICE in
            1)
                WEB_ROOT_TYPE="direct"
                break
                ;;
            2)
                WEB_ROOT_TYPE="public"
                break
                ;;
            *)
                echo "❌ Choix invalide. Veuillez entrer 1 ou 2."
                ;;
        esac
    done
fi

# Définir WEB_ROOT_PATH selon le type choisi
if [ "$WEB_ROOT_TYPE" = "public" ]; then
    WEB_ROOT_PATH="/var/www/html/$PROJECT_NAME/public"
    echo "✅ Répertoire web : $WEB_ROOT_PATH (architecture MVC)"

    # Vérifier si le dossier public existe, sinon le créer
    echo "🔍 Vérification du dossier public..."
    if ! dry_run_multipass exec "$VM_NAME" -- test -d "$WEB_ROOT_PATH"; then
        echo "📁 Création du dossier public..."
        dry_run_multipass exec "$VM_NAME" -- sudo mkdir -p "$WEB_ROOT_PATH"
        dry_run_multipass exec "$VM_NAME" -- sudo chown ubuntu:www-data "$WEB_ROOT_PATH"
        dry_run_multipass exec "$VM_NAME" -- sudo chmod 775 "$WEB_ROOT_PATH"
        echo "✅ Dossier public créé"
        # Créer un fichier index.php si aucun fichier index n'existe
        create_project_index_file
    fi
else
    WEB_ROOT_PATH="/var/www/html/$PROJECT_NAME"
    echo "✅ Répertoire web : $WEB_ROOT_PATH (projet direct)"
fi

# DÉTECTION AUTOMATIQUE DU RÉPERTOIRE WEB
# Vérifier si le dossier /public existe et l'utiliser en priorité
echo "🔍 Détection automatique de l'architecture du projet..."
DETECTED_WEB_ROOT=$(dry_run_multipass exec "$VM_NAME" -- bash -c "
if [ -d /var/www/html/$PROJECT_NAME/public ]; then
    echo '/var/www/html/$PROJECT_NAME/public'
else
    echo '/var/www/html/$PROJECT_NAME'
fi
")

if [ "$DETECTED_WEB_ROOT" != "$WEB_ROOT_PATH" ]; then
    echo "⚠️ Architecture détectée diffère du choix initial"
    echo "  Choisi: $WEB_ROOT_PATH"
    echo "  Détecté: $DETECTED_WEB_ROOT"
    read -rp "Utiliser l'architecture détectée ? [Y/n] : " USE_DETECTED
    if [ "${USE_DETECTED:-Y}" = "Y" ] || [ "${USE_DETECTED:-Y}" = "y" ] || [ -z "$USE_DETECTED" ]; then
        WEB_ROOT_PATH="$DETECTED_WEB_ROOT"
        echo "✅ Utilisation de : $WEB_ROOT_PATH"
    fi
fi

if [ "$WEB_ROOT_PATH" = "/var/www/html/$PROJECT_NAME/public" ]; then
    echo "✅ Architecture MVC détectée (dossier public)"
else
    echo "✅ Architecture directe détectée"
fi

# --- VHOST_DOMAIN ---
if [ -z "${VHOST_DOMAIN:-}" ]; then
    # Recherche d'un virtual host existant pour ce projet
    echo "🔍 Recherche d'un virtual host existant pour le projet '$PROJECT_NAME'..."
    EXISTING_VHOST=$(dry_run_multipass exec "$VM_NAME" -- bash -c "
        for conf in /etc/apache2/sites-available/*.conf; do
            if [ -f \"\$conf\" ] && [ \"\$(basename \"\$conf\")\" != \"000-default.conf\" ] && [ \"\$(basename \"\$conf\")\" != \"default-ssl.conf\" ]; then
                if grep -q \"DocumentRoot ${WEB_ROOT_PATH:-/var/www/html/$PROJECT_NAME}\" \"\$conf\" 2>/dev/null; then
                    grep 'ServerName' \"\$conf\" | awk '{print \$2}' | head -1
                fi
            fi
        done
    ")

    if [ -n "$EXISTING_VHOST" ]; then
        echo "✅ Virtual host trouvé : $EXISTING_VHOST"
        read -rp "Utiliser ce vhost existant ? [Y/n] : " USE_EXISTING
        if [ "${USE_EXISTING:-Y}" = "Y" ] || [ "${USE_EXISTING:-Y}" = "y" ] || [ -z "$USE_EXISTING" ]; then
            VHOST_DOMAIN="$EXISTING_VHOST"
            echo "📌 Utilisation du vhost : $VHOST_DOMAIN"
        else
            read -rp "Nom de domaine du vhost (laisser vide si non utilisé) : " VHOST_DOMAIN
        fi
    else
        echo "⚠️ Aucun virtual host trouvé pour ce projet."
        read -rp "Nom de domaine du vhost (laisser vide si non utilisé) : " VHOST_DOMAIN
    fi
fi

# -------------------------------
# CLÉ SSH
# -------------------------------
SSH_KEY="$HOME/.ssh/id_ed25519"
if [ ! -f "$SSH_KEY" ]; then
    echo "⚠️  Clé SSH non trouvée : $SSH_KEY"
    echo "👉 Génère une clé avec : ssh-keygen -t ed25519 -f $HOME/.ssh/id_ed25519"
    exit 1
fi

# -------------------------------
# VÉRIFICATION VM
# -------------------------------
VM_STATE=$(dry_run_multipass info "$VM_NAME" | grep "State:" | awk '{print $2}')
if [ "$VM_STATE" != "Running" ]; then
    echo "⏯️ VM $VM_NAME arrêtée. Démarrage..."
    dry_run_multipass start "$VM_NAME"
    echo "⏳ Attente que la VM soit prête..."
    if [ "$DRY_RUN" = false ]; then
        sleep 5
    fi
else
    echo "ℹ️ VM $VM_NAME est déjà en cours d'exécution."
fi

# -------------------------------
# RÉCUPÉRATION IP
# -------------------------------
IP=$(dry_run_multipass info "$VM_NAME" | grep IPv4 | awk '{print $2}')
if [ -z "$IP" ]; then
    echo "❌ Impossible de récupérer l'IP de la VM."
    exit 1
fi

# -------------------------------
# MISE À JOUR /etc/hosts
# -------------------------------
if [ -n "${VHOST_DOMAIN:-}" ]; then
    echo "🔄 Modification de /etc/hosts..."
    backup_hosts  # Backup automatique avant modification

    if [ "$DRY_RUN" = true ]; then
        echo "🔍 [DRY-RUN] Suppression ancienne entrée : $VHOST_DOMAIN"
        echo "🔍 [DRY-RUN] Ajout nouvelle entrée : $IP $VHOST_DOMAIN"
    else
        sudo sed -i "\|$VHOST_DOMAIN|d" /etc/hosts
        echo "$IP $VHOST_DOMAIN" | sudo tee -a /etc/hosts > /dev/null
    fi
    echo "✅ /etc/hosts mis à jour : $IP $VHOST_DOMAIN"
    LOCAL_HOSTNAME="$VHOST_DOMAIN"
    
    # Configuration du virtual host Apache
    echo "🔧 Configuration du virtual host Apache..."
    VHOST_CONFIG="<VirtualHost *:80>
    ServerName $VHOST_DOMAIN
    DocumentRoot ${WEB_ROOT_PATH:-/var/www/html/$PROJECT_NAME}
    <Directory ${WEB_ROOT_PATH:-/var/www/html/$PROJECT_NAME}>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/${VHOST_DOMAIN}_error.log
    CustomLog \${APACHE_LOG_DIR}/${VHOST_DOMAIN}_access.log combined
</VirtualHost>"

    # Créer le fichier de configuration sur la VM
    dry_run_multipass exec "$VM_NAME" -- bash -c "echo '$VHOST_CONFIG' | sudo tee /etc/apache2/sites-available/${VHOST_DOMAIN}.conf > /dev/null"

    # Activer mod_rewrite et mod_headers pour tous les environnements
    echo "🔧 Activation de mod_rewrite et mod_headers..."
    dry_run_multipass exec "$VM_NAME" -- sudo a2enmod rewrite headers

    # Activer le site et redémarrer Apache
    dry_run_multipass exec "$VM_NAME" -- sudo a2ensite "${VHOST_DOMAIN}.conf"
    dry_run_multipass exec "$VM_NAME" -- sudo systemctl reload apache2
    
    echo "✅ Virtual host configuré pour $VHOST_DOMAIN → ${WEB_ROOT_PATH:-/var/www/html/$PROJECT_NAME}"
else
    echo "⚠️ Aucun VHOST_DOMAIN défini, utilisation de l'IP directe."
    LOCAL_HOSTNAME="$IP"
fi

# -------------------------------
# CREATION FICHIER INDEX SI NECESSAIRE
# -------------------------------
# Créer un fichier index.php si aucun fichier index n'existe
create_project_index_file

# -------------------------------
# AGENT SSH
# -------------------------------
eval "$(ssh-agent -s)"
ssh-add "$SSH_KEY"

# -------------------------------
# URL DU PROJET
# -------------------------------
if [ -n "${VHOST_DOMAIN:-}" ]; then
    PROJECT_URL="http://$LOCAL_HOSTNAME/"
else
    PROJECT_URL="http://$LOCAL_HOSTNAME/$PROJECT_NAME/"
fi

if command -v xclip &> /dev/null; then
    echo -n "$PROJECT_URL" | xclip -selection clipboard
    CLIP_MSG=" (copié dans le presse-papier)"
else
    CLIP_MSG=""
fi

if command -v google-chrome &> /dev/null; then
    google-chrome "$PROJECT_URL" &
elif command -v chromium &> /dev/null; then
    chromium "$PROJECT_URL" &
else
    xdg-open "$PROJECT_URL" &
fi

# -------------------------------
# MISE À JOUR DE LA VM
# -------------------------------
echo "🔄 Mise à jour de la VM en cours..."

if dry_run_multipass exec "$VM_NAME" -- sudo apt update && dry_run_multipass exec "$VM_NAME" -- sudo apt upgrade -y; then
    echo "✅ VM mise à jour avec succès !"
else
    echo "⚠️ Erreur lors de la mise à jour de la VM (non bloquant)"
fi

# -------------------------------
# AFFICHAGE FINAL
# -------------------------------
if [ "$DRY_RUN" = true ]; then
    echo
    echo "🔍 === RÉSUMÉ DU MODE DRY-RUN ==="
    echo "Actions qui SERAIENT exécutées :"
    echo "  📦 VM: $VM_NAME (IP simulée: 192.168.64.10)"
    echo "  📁 Projet: /var/www/html/$PROJECT_NAME"
    echo "  🌐 Répertoire web: ${WEB_ROOT_PATH:-/var/www/html/$PROJECT_NAME}"
    if [ -n "${VHOST_DOMAIN:-}" ]; then
        echo "  🌐 Virtual host: $VHOST_DOMAIN"
        echo "  💾 Backup /etc/hosts avant modification"
    fi
    echo "  🔗 URL: $PROJECT_URL"
    echo
    echo "Pour exécuter réellement, relancez sans --dry-run"
    echo "======================================"
else
    echo "✅ Connexion prête !"
    echo "➡️ SSH : ssh ubuntu@$IP"
    echo "➡️ Projet dans la VM : /var/www/html/$PROJECT_NAME"
    echo "➡️ Répertoire web : ${WEB_ROOT_PATH:-/var/www/html/$PROJECT_NAME}"
    echo "🌐 URL : $PROJECT_URL$CLIP_MSG"
fi
