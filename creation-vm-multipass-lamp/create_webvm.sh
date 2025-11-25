#!/bin/bash
set -euo pipefail  # Stop script si erreur ou variable non définie

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
            echo ""
            echo "ENVIRONMENTS SUPPORTÉS :"
            echo "  development      Configuration avec Xdebug, erreurs affichées, outils dev"
            echo "  test            Configuration optimisée pour les tests, pas de debug"
            echo "  production      Configuration sécurisée et optimisée, pas d'outils debug"
            echo ""
            echo "CONFIGURATION :"
            echo "  Placez vos fichiers .conf dans ./config/"
            echo "  Définissez ENVIRONMENT dans votre .conf ou laissez vide pour choisir"
            echo "  Voir config/example_with_environment.conf pour un exemple complet"
            exit 0
            ;;
    esac
done

# Wrapper pour les commandes critiques en mode dry-run
dry_run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        echo "🔍 [DRY-RUN] $*"
        return 0
    else
        "$@"
    fi
}

# Wrapper spécial pour multipass (retourne des valeurs factices en dry-run)
dry_run_multipass() {
    if [ "$DRY_RUN" = true ]; then
        echo "🔍 [DRY-RUN] multipass $*"
        # Simuler quelques réponses typiques pour multipass
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
                # Pour multipass exec, juste afficher la commande
                echo "🔍 [DRY-RUN] Exécution dans la VM: ${*:3}"
                ;;
        esac
        return 0
    else
        multipass "$@"
    fi
}

# Wrapper spécial pour les commandes système critiques
dry_run_ssh_keygen() {
    if [ "$DRY_RUN" = true ]; then
        echo "🔍 [DRY-RUN] ssh-keygen $*"
        return 0
    else
        ssh-keygen "$@"
    fi
}

# Obtenir le répertoire du script pour trouver le dossier config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/config"
CONFIG_FILES=("$CONFIG_DIR"/*.conf)
SELECTED_CONFIG=""

# -------------------------------
# CHOIX DU FICHIER DE CONFIG
# -------------------------------
if [ -e "${CONFIG_FILES[0]}" ]; then
    echo "📄 Fichiers de config trouvés dans $CONFIG_DIR :"

    # Créer un tableau avec les noms de fichiers colorés
    DISPLAY_OPTIONS=()
    COLORS=('\033[1;31m' '\033[1;32m' '\033[1;33m' '\033[1;34m' '\033[1;35m' '\033[1;36m' '\033[1;91m' '\033[1;92m' '\033[1;93m' '\033[1;94m')

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
            echo "⚠️ Mode interactif sélectionné."
            break
        elif [ -n "$CHOICE" ]; then
            # Retrouver le fichier original basé sur l'index
            SELECTED_CONFIG="${CONFIG_FILES[$((REPLY-1))]}"
            echo "🔧 Utilisation de $(basename "$SELECTED_CONFIG")"
            source "$SELECTED_CONFIG"
            break
        fi
    done
else
    echo "⚠️ Aucun fichier de config trouvé dans $CONFIG_DIR, mode interactif activé."
fi

# -------------------------------
# VALEURS INTERACTIVES SI NON DÉFINIES
# -------------------------------
[ -z "${VM_NAME:-}" ] && read -p "Nom de la VM (ex: webvm) : " VM_NAME
[ -z "${PROJECT_NAME:-}" ] && read -p "Nom du projet (ex: projet-web) : " PROJECT_NAME

# --- WEB_ROOT_TYPE ---
if [ -z "${WEB_ROOT_TYPE:-}" ]; then
    echo "📌 Choix du répertoire web pour le projet '$PROJECT_NAME' :"
    echo "1) Projet direct → /var/www/html/$PROJECT_NAME"
    echo "2) Architecture MVC → /var/www/html/$PROJECT_NAME/public"

    while true; do
        read -p "➡️ Choix (1 ou 2) [1] : " WEB_ROOT_CHOICE
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
else
    WEB_ROOT_PATH="/var/www/html/$PROJECT_NAME"
    echo "✅ Répertoire web : $WEB_ROOT_PATH (projet direct)"
fi

[ -z "${GIT_USER_NAME:-}" ] && read -p "Nom Git (user / pseudo) : " GIT_USER_NAME
[ -z "${GIT_USER_EMAIL:-}" ] && read -p "Email Git : " GIT_USER_EMAIL
[ -z "${GITLAB_REPO:-}" ] && read -p "URL GitLab ssh (laisser vide si pas utilisé) : " GITLAB_REPO
[ -z "${GITHUB_REPO:-}" ] && read -p "URL GitHub ssh (laisser vide si pas utilisé) : " GITHUB_REPO
[ -z "${DB_USER:-}" ] && read -p "Nom utilisateur MySQL du projet : " DB_USER
[ -z "${DB_PASS:-}" ] && read -p "Mot de passe MySQL du projet : " DB_PASS

# --- ENVIRONMENT SELECTION ---
if [ -z "${ENVIRONMENT:-}" ]; then
    echo "🌍 Choix de l'environnement :"
    echo "1) Development (dev tools, xdebug, error display)"
    echo "2) Test (minimal debug, optimized for testing)"
    echo "3) Production (optimized, secure, no debug)"

    while true; do
        read -p "➡️ Choix (1, 2 ou 3) [1] : " ENV_CHOICE
        ENV_CHOICE=${ENV_CHOICE:-1}

        case $ENV_CHOICE in
            1)
                ENVIRONMENT="development"
                break
                ;;
            2)
                ENVIRONMENT="test"
                break
                ;;
            3)
                ENVIRONMENT="production"
                break
                ;;
            *)
                echo "❌ Choix invalide. Veuillez entrer 1, 2 ou 3."
                ;;
        esac
    done
fi

echo "✅ Environnement sélectionné : $ENVIRONMENT"

# Charger la configuration d'environnement
ENV_CONFIG_FILE="${CONFIG_DIR}/environments/${ENVIRONMENT}.env"
if [ -f "$ENV_CONFIG_FILE" ]; then
    echo "🔧 Chargement de la configuration d'environnement : $ENV_CONFIG_FILE"
    source "$ENV_CONFIG_FILE"
else
    echo "⚠️ Fichier de configuration d'environnement non trouvé : $ENV_CONFIG_FILE"
    echo "    Utilisation des paramètres par défaut."
fi

# Valeurs par défaut
CPUS=${CPUS:-2}
MEM=${MEM:-"4G"}
DISK=${DISK:-"15G"}
DB_NAME=${DB_NAME:-"${PROJECT_NAME}"}
PHPMYADMIN_PASS=${PHPMYADMIN_PASS:-"phpmyadmin"}

# -------------------------------
# CHECK SI VM EXISTE DÉJÀ
# -------------------------------
if dry_run_multipass list | grep -qw "$VM_NAME"; then
    echo "⚠️ La VM $VM_NAME existe déjà. Supprimer ou choisir un autre nom."
    if [ "$DRY_RUN" = false ]; then
        exit 1
    fi
fi

# -------------------------------
# CREATION DE LA VM
# -------------------------------
echo "📦 Création de la VM $VM_NAME..."
dry_run_multipass launch -n "$VM_NAME" --cpus $CPUS --memory $MEM --disk $DISK "24.04"

# -------------------------------
# CONFIGURATION SSH AUTOMATIQUE (PC ↔ VM)
# -------------------------------
USER_HOME=${SUDO_USER:+/home/$SUDO_USER}
USER_HOME=${USER_HOME:-$HOME}
SSH_DIR="$USER_HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"
SSH_KNOWN="$SSH_DIR/known_hosts"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
touch "$SSH_CONFIG" "$SSH_KNOWN"
chmod 600 "$SSH_CONFIG" "$SSH_KNOWN"

IP=$(dry_run_multipass info "$VM_NAME" | grep IPv4 | awk '{print $2}')
echo "🔒 Configuration SSH pour $VM_NAME (IP : $IP)..."

# Supprime l'ancienne clé pour cette IP si elle existe
dry_run_ssh_keygen -R "$IP" -f "$SSH_KNOWN" 2>/dev/null || true

# Attente que la VM accepte le SSH
if [ "$DRY_RUN" = true ]; then
    echo "🔍 [DRY-RUN] Attente SSH de la VM simulée..."
    echo "🔍 [DRY-RUN] Ajout clé SSH au known_hosts"
else
    until nc -z -w5 "$IP" 22 >/dev/null 2>&1; do
        echo "⏳ En attente du SSH de la VM..."
        sleep 2
    done

    # Récupère et ajoute la clé dans known_hosts
    KEYSCAN=$(ssh-keyscan -H "$IP" 2>/dev/null)
    if ! grep -q "$IP" "$SSH_KNOWN"; then
        echo "$KEYSCAN" >> "$SSH_KNOWN"
    fi
    chmod 600 "$SSH_KNOWN"
fi
echo "✅ Clé SSH ajoutée à known_hosts sans prompt."

# -------------------------------
# CONFIG SSH POUR VS CODE
# -------------------------------
echo "🔧 Mise à jour de ~/.ssh/config pour VS Code..."
if grep -q "Host $VM_NAME" "$SSH_CONFIG"; then
    # Met à jour l'IP si Host existe déjà
    sed -i "/Host $VM_NAME/,/ForwardAgent/ s/HostName .*/HostName $IP/" "$SSH_CONFIG"
    echo "✅ IP mise à jour dans ~/.ssh/config pour $VM_NAME"
else
    # Ajoute un nouveau host
    cat <<EOL >> "$SSH_CONFIG"

Host $VM_NAME
    HostName $IP
    User ubuntu
    IdentityFile $SSH_DIR/id_ed25519
    ForwardAgent yes
EOL
    echo "✅ Nouveau Host ajouté dans ~/.ssh/config pour $VM_NAME"
fi

# -------------------------------
# AJOUT DE LA CLE SSH LOCALE (PC → VM)
# -------------------------------
SSH_KEY="$SSH_DIR/id_ed25519.pub"
if [ "$DRY_RUN" = true ]; then
    echo "🔍 [DRY-RUN] Vérification/génération clé SSH ed25519"
    PUB="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5FAKE_KEY_FOR_DRY_RUN user@host"
else
    if [ ! -f "$SSH_DIR/id_ed25519" ]; then
        ssh-keygen -t ed25519 -f "$SSH_DIR/id_ed25519" -N ""
    fi
    PUB=$(cat "$SSH_KEY")
fi

dry_run_multipass exec "$VM_NAME" -- bash -c "
mkdir -p /home/ubuntu/.ssh
grep -qxF '$PUB' /home/ubuntu/.ssh/authorized_keys || echo '$PUB' >> /home/ubuntu/.ssh/authorized_keys
chmod 700 /home/ubuntu/.ssh
chmod 600 /home/ubuntu/.ssh/authorized_keys
chown -R ubuntu:ubuntu /home/ubuntu/.ssh
"
echo "✅ Clé locale ajoutée à la VM."

# -------------------------------
# INSTALLATION LAMP + OUTILS + ENVIRONNEMENT
# -------------------------------
echo "💻 Installation Apache, MariaDB, PHP-FPM pour environnement $ENVIRONMENT..."
dry_run_multipass exec "$VM_NAME" -- sudo bash -c "
export DEBIAN_FRONTEND=noninteractive
apt update -y

# Installation de base LAMP
apt install -y apache2 mariadb-server php-fpm php-mysql php-cli php-curl php-zip php-mbstring git curl unzip nano

# Installation modules spécifiques à l'environnement
if [ -n '${ENVIRONMENT_PHP_MODULES:-}' ]; then
    echo '🔧 Installation des modules PHP pour $ENVIRONMENT...'
    apt install -y ${ENVIRONMENT_PHP_MODULES:-}
fi

# Installation outils spécifiques à l'environnement
if [ -n '${ENVIRONMENT_TOOLS:-}' ]; then
    echo '🛠️ Installation des outils pour $ENVIRONMENT...'
    apt install -y ${ENVIRONMENT_TOOLS:-}
fi

# Détection automatique de la version PHP
PHP_VERSION=\$(php -r 'echo PHP_MAJOR_VERSION.\".\" .PHP_MINOR_VERSION;')
systemctl enable --now apache2
systemctl enable --now php\${PHP_VERSION}-fpm

# Configuration Apache pour PHP-FPM
a2enmod proxy_fcgi setenvif
a2enconf php\${PHP_VERSION}-fpm

# Activer mod_rewrite pour TOUS les environnements
a2enmod rewrite headers

# Configuration Apache spécifique à l'environnement (SSL uniquement en production)
if [ '$ENVIRONMENT' = 'production' ]; then
    a2enmod ssl
fi

# Corriger le warning ServerName
echo 'ServerName localhost' >> /etc/apache2/apache2.conf
systemctl reload apache2
"

# -------------------------------
# CONFIGURATION PHP SPECIFIQUE À L'ENVIRONNEMENT
# -------------------------------
if [ -n "${ENVIRONMENT_PHP_CONFIG:-}" ]; then
    echo "🐘 Configuration PHP pour l'environnement $ENVIRONMENT..."
    dry_run_multipass exec "$VM_NAME" -- sudo bash -c "
        PHP_VERSION=\$(php -r 'echo PHP_MAJOR_VERSION.\".\" .PHP_MINOR_VERSION;')
        PHP_INI_PATH=\"/etc/php/\${PHP_VERSION}/fpm/php.ini\"

        # Créer un backup du php.ini original
        cp \$PHP_INI_PATH \$PHP_INI_PATH.backup.$(date +%Y%m%d_%H%M%S)

        # Appliquer les configurations spécifiques à l'environnement
        cat >> \$PHP_INI_PATH <<'EOF_PHP_CONFIG'
${ENVIRONMENT_PHP_CONFIG}
EOF_PHP_CONFIG

        # Redémarrer PHP-FPM pour appliquer les changements
        systemctl restart php\${PHP_VERSION}-fpm
    "
fi

# -------------------------------
# CONFIGURATION XDEBUG (DEVELOPMENT UNIQUEMENT)
# -------------------------------
if [ -n "${ENVIRONMENT_XDEBUG_CONFIG:-}" ] && [ "$ENVIRONMENT" = "development" ]; then
    echo "🐛 Configuration Xdebug pour l'environnement de développement..."
    dry_run_multipass exec "$VM_NAME" -- sudo bash -c "
        PHP_VERSION=\$(php -r 'echo PHP_MAJOR_VERSION.\".\" .PHP_MINOR_VERSION;')
        XDEBUG_INI_PATH=\"/etc/php/\${PHP_VERSION}/mods-available/xdebug.ini\"

        # Configuration Xdebug
        cat > \$XDEBUG_INI_PATH <<'EOF_XDEBUG_CONFIG'
${ENVIRONMENT_XDEBUG_CONFIG}
EOF_XDEBUG_CONFIG

        # Activer Xdebug
        phpenmod xdebug
        systemctl restart php\${PHP_VERSION}-fpm
    "
fi

# -------------------------------
# CREATION UTILISATEURS MYSQL ET BASE PROJET
# -------------------------------
echo "🗄️ Création de la base projet et utilisateurs MySQL..."

# Créer utilisateur superadmin pour le développement
echo "👑 Création utilisateur superadmin..."
dry_run_multipass exec "$VM_NAME" -- sudo bash -c "
mysql -e \"CREATE USER IF NOT EXISTS 'superadmin'@'localhost' IDENTIFIED BY 'superpass';
GRANT ALL PRIVILEGES ON *.* TO 'superadmin'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;\"
"

# Créer base et utilisateur spécifique au projet
echo "📊 Création base de données et utilisateur projet..."
dry_run_multipass exec "$VM_NAME" -- sudo bash -c "
mysql -e \"CREATE DATABASE IF NOT EXISTS \\\`$DB_NAME\\\`;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON \\\`$DB_NAME\\\`.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;\"
"

echo "✅ Utilisateurs MySQL créés :"
echo "   👑 superadmin / superpass (tous privilèges)"
echo "   📊 $DB_USER / $DB_PASS (base $DB_NAME uniquement)"

# -------------------------------
# CONFIGURATION MYSQL SPECIFIQUE À L'ENVIRONNEMENT
# -------------------------------
if [ -n "${ENVIRONMENT_MYSQL_CONFIG:-}" ]; then
    echo "🗄️ Configuration MySQL pour l'environnement $ENVIRONMENT..."
    dry_run_multipass exec "$VM_NAME" -- sudo bash -c "
        # Créer un backup de la configuration MySQL
        cp /etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf.backup.$(date +%Y%m%d_%H%M%S)

        # Appliquer les configurations spécifiques à l'environnement
        cat >> /etc/mysql/mariadb.conf.d/50-server.cnf <<'EOF_MYSQL_CONFIG'

# Configuration pour environnement $ENVIRONMENT
${ENVIRONMENT_MYSQL_CONFIG}
EOF_MYSQL_CONFIG

        # Redémarrer MySQL pour appliquer les changements
        systemctl restart mariadb
    "
fi

# -------------------------------
# INSTALLATION PHPMyAdmin NON INTERACTIVE
# -------------------------------
echo "💻 Installation phpMyAdmin non interactive..."
dry_run_multipass exec "$VM_NAME" -- sudo bash -c "
export DEBIAN_FRONTEND=noninteractive

if ! dpkg -s phpmyadmin >/dev/null 2>&1; then
    echo 'phpmyadmin phpmyadmin/dbconfig-install boolean true' | debconf-set-selections
    echo 'phpmyadmin phpmyadmin/app-password-confirm password $PHPMYADMIN_PASS' | debconf-set-selections
    echo 'phpmyadmin phpmyadmin/mysql/admin-pass password $DB_PASS' | debconf-set-selections
    echo 'phpmyadmin phpmyadmin/mysql/app-pass password $PHPMYADMIN_PASS' | debconf-set-selections
    echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | debconf-set-selections

    apt install -y phpmyadmin
    systemctl reload apache2
else
    echo 'phpMyAdmin déjà installé.'
fi
"

# -------------------------------
# CREATION DOSSIER PROJET
# -------------------------------
echo "📂 Création du dossier projet..."
dry_run_multipass exec "$VM_NAME" -- sudo bash -c "
# Configurer le répertoire web principal pour ubuntu
chown -R ubuntu:www-data /var/www/html
chmod 775 /var/www/html

# Créer le dossier projet avec bonnes permissions
mkdir -p /var/www/html/$PROJECT_NAME
chown -R ubuntu:www-data /var/www/html/$PROJECT_NAME
chmod -R 775 /var/www/html/$PROJECT_NAME

# Créer le dossier public si architecture MVC
if [ '$WEB_ROOT_TYPE' = 'public' ]; then
    mkdir -p $WEB_ROOT_PATH
    chown ubuntu:www-data $WEB_ROOT_PATH
    chmod 775 $WEB_ROOT_PATH
    echo '✅ Dossier public créé pour architecture MVC'
fi

# Créer un fichier index.php de test SEULEMENT si pas de repo à cloner
# (éviter les conflits lors du clonage)
if [ -z '${GITLAB_REPO:-}' ] && [ -z '${GITHUB_REPO:-}' ]; then
    echo '📄 Création du fichier index.php de test...'
    cat > $WEB_ROOT_PATH/index.php <<EOL_INDEX
<?php
echo '<h1>✅ Projet $PROJECT_NAME</h1>';
echo '<p>Architecture: ' . ('$WEB_ROOT_TYPE' === 'public' ? 'MVC (dossier public)' : 'Directe') . '</p>';
echo '<p>Répertoire: $WEB_ROOT_PATH</p>';
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
echo '<h3>🌍 Environnement configuré: $ENVIRONMENT</h3>';
if ('$ENVIRONMENT' === 'development') {
    echo '<p style=\"color: orange;\">⚠️ Mode développement - Erreurs PHP affichées</p>';
    echo '<p>🐛 Xdebug: ' . (extension_loaded('xdebug') ? 'Activé' : 'Désactivé') . '</p>';
} elseif ('$ENVIRONMENT' === 'test') {
    echo '<p style=\"color: blue;\">🧪 Mode test - Configuration optimisée pour les tests</p>';
} elseif ('$ENVIRONMENT' === 'production') {
    echo '<p style=\"color: green;\">🚀 Mode production - Configuration sécurisée</p>';
}

echo '<hr>';
echo '<h3>📊 Informations PHP</h3>';
echo '<p>Memory Limit: ' . ini_get('memory_limit') . '</p>';
echo '<p>Max Execution Time: ' . ini_get('max_execution_time') . 's</p>';
echo '<p>Error Reporting: ' . ini_get('error_reporting') . '</p>';
echo '<p>Display Errors: ' . (ini_get('display_errors') ? 'On' : 'Off') . '</p>';
echo '<p>OPcache: ' . (extension_loaded('opcache') && ini_get('opcache.enable') ? 'Activé' : 'Désactivé') . '</p>';
?>
EOL_INDEX

    chown ubuntu:www-data $WEB_ROOT_PATH/index.php
    chmod 664 $WEB_ROOT_PATH/index.php
else
    echo '⏭️ Repos GitLab/GitHub détecté - index.php de test non créé (sera remplacé par le clonage)'
fi
"

# -------------------------------
# CONFIGURATION GIT DANS LA VM
# -------------------------------
dry_run_multipass exec "$VM_NAME" -- git config --global user.name "$GIT_USER_NAME"
dry_run_multipass exec "$VM_NAME" -- git config --global user.email "$GIT_USER_EMAIL"

# -------------------------------
# CLE SSH DANS LA VM POUR GITLAB/GITHUB
# -------------------------------
dry_run_multipass exec "$VM_NAME" -- bash -c '
if [ ! -f ~/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519 <<< y >/dev/null 2>&1
fi
'
echo "📋 Voici la clé publique de la VM à ajouter dans GitLab/GitHub :"
SSH_PUBLIC_KEY=$(dry_run_multipass exec "$VM_NAME" -- cat /home/ubuntu/.ssh/id_ed25519.pub)
echo "$SSH_PUBLIC_KEY"

# Copier dans le presse-papier si possible
if command -v xclip >/dev/null 2>&1; then
    echo "$SSH_PUBLIC_KEY" | xclip -selection clipboard
    echo "✅ Clé copiée dans le presse-papier avec xclip"
elif command -v xsel >/dev/null 2>&1; then
    echo "$SSH_PUBLIC_KEY" | xsel --clipboard --input
    echo "✅ Clé copiée dans le presse-papier avec xsel"
elif command -v wl-copy >/dev/null 2>&1; then
    echo "$SSH_PUBLIC_KEY" | wl-copy
    echo "✅ Clé copiée dans le presse-papier avec wl-copy (Wayland)"
elif command -v pbcopy >/dev/null 2>&1; then
    echo "$SSH_PUBLIC_KEY" | pbcopy
    echo "✅ Clé copiée dans le presse-papier avec pbcopy (macOS)"
else
    echo "⚠️ Aucun outil de presse-papier trouvé. Copiez manuellement la clé ci-dessus."
    echo "   Installez xclip, xsel, ou wl-copy pour activer la copie automatique."
fi

read -p "⏸️ Ajoute la clé ci-dessus dans GitLab/GitHub, puis appuie sur Entrée pour continuer..."

# -------------------------------
# CLONAGE DES REPOS (SI FOURNIS)
# -------------------------------
ACTUAL_WEB_ROOT_PATH="$WEB_ROOT_PATH"  # Par défaut, utiliser le WEB_ROOT_PATH défini

if [ -n "${GITLAB_REPO:-}" ]; then
    dry_run_multipass exec "$VM_NAME" -- bash -c "
cd /var/www/html/$PROJECT_NAME
[ ! -d .git ] && git clone $GITLAB_REPO . || echo 'GitLab déjà cloné'
"
fi
if [ -n "${GITHUB_REPO:-}" ]; then
    dry_run_multipass exec "$VM_NAME" -- bash -c "
cd /var/www/html/$PROJECT_NAME
[ ! -d .git ] && git clone $GITHUB_REPO . || echo 'GitHub déjà cloné'
"
fi

# DÉTECTION AUTOMATIQUE DU RÉPERTOIRE WEB (SI REPO CLONÉ)
# Si un repo a été cloné, vérifier si le dossier public existe
if [ -n "${GITLAB_REPO:-}" ] || [ -n "${GITHUB_REPO:-}" ]; then
    echo "🔍 Détection automatique de l'architecture du projet cloné..."
    DETECTED_WEB_ROOT=$(multipass exec "$VM_NAME" -- bash -c "
if [ -d /var/www/html/$PROJECT_NAME/public ]; then
    echo '/var/www/html/$PROJECT_NAME/public'
else
    echo '/var/www/html/$PROJECT_NAME'
fi
")
    ACTUAL_WEB_ROOT_PATH="$DETECTED_WEB_ROOT"

    if [ "$ACTUAL_WEB_ROOT_PATH" = "/var/www/html/$PROJECT_NAME/public" ]; then
        echo "✅ Architecture MVC détectée (dossier public trouvé)"
    else
        echo "✅ Architecture directe détectée (pas de dossier public)"
    fi
fi

# -------------------------------
# CREATION VIRTUAL HOST (SI DÉFINI)
# -------------------------------
if [ -n "${VHOST_DOMAIN:-}" ]; then
    echo "🌐 Création du Virtual Host Apache pour $VHOST_DOMAIN..."
    multipass exec "$VM_NAME" -- sudo bash -c "
VHOST_FILE='/etc/apache2/sites-available/$VHOST_DOMAIN.conf'
if [ -f \$VHOST_FILE ]; then
    sed -i 's/^\\s*ServerName .*/ServerName $VHOST_DOMAIN/' \$VHOST_FILE
    sed -i 's|^\\s*DocumentRoot .*|DocumentRoot $ACTUAL_WEB_ROOT_PATH|' \$VHOST_FILE
    sed -i 's|^\\s*<Directory .*|<Directory $ACTUAL_WEB_ROOT_PATH>|' \$VHOST_FILE
    echo '✅ Virtual Host existant mis à jour'
else
cat > \$VHOST_FILE <<EOL
<VirtualHost *:80>
    ServerName $VHOST_DOMAIN
    DocumentRoot $ACTUAL_WEB_ROOT_PATH

    <Directory $ACTUAL_WEB_ROOT_PATH>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/$VHOST_DOMAIN-error.log
    CustomLog \${APACHE_LOG_DIR}/$VHOST_DOMAIN-access.log combined
</VirtualHost>
EOL
    a2ensite $VHOST_DOMAIN.conf
    echo '✅ Virtual Host créé'
fi
systemctl reload apache2
"
else
    echo "⚠️ Aucun VHOST_DOMAIN défini dans le .conf, configuration du vhost ignorée."
fi

# -------------------------------
# CONFIGURATION APACHE SPECIFIQUE À L'ENVIRONNEMENT
# -------------------------------
if [ -n "${ENVIRONMENT_APACHE_CONFIG:-}" ]; then
    echo "🌐 Configuration Apache pour l'environnement $ENVIRONMENT..."
    dry_run_multipass exec "$VM_NAME" -- sudo bash -c "
        # Créer un backup de la configuration Apache
        cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.backup.$(date +%Y%m%d_%H%M%S)

        # Appliquer les configurations spécifiques à l'environnement
        cat >> /etc/apache2/apache2.conf <<'EOF_APACHE_CONFIG'

# Configuration pour environnement $ENVIRONMENT
${ENVIRONMENT_APACHE_CONFIG}
EOF_APACHE_CONFIG

        # Redémarrer Apache pour appliquer les changements
        systemctl reload apache2
    "
fi

# -------------------------------
# INSTALLATION OH-MY-ZSH (OPTIONNELLE)
# -------------------------------
if [ -z "${INSTALL_OHMYZSH:-}" ]; then
    read -p "👉 Souhaites-tu installer Oh My Zsh (avec autosuggestions et syntax highlighting) ? (y/n) : " REPLY
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        INSTALL_OHMYZSH="yes"
    else
        INSTALL_OHMYZSH="no"
    fi
fi

if [ "$INSTALL_OHMYZSH" == "yes" ]; then
    echo "💻 Installation de Zsh et Oh My Zsh dans la VM..."

    # Installer zsh, curl et git
    dry_run_multipass exec "$VM_NAME" -- sudo apt install -y zsh curl git

    # Installer Oh My Zsh et plugins dans le home de ubuntu
    dry_run_multipass exec "$VM_NAME" -- bash -c "
        export HOME=/home/ubuntu

        # Cloner Oh My Zsh
        git clone https://github.com/ohmyzsh/ohmyzsh.git \$HOME/.oh-my-zsh || true

        # Cloner les plugins
        ZSH_CUSTOM=\$HOME/.oh-my-zsh/custom
        git clone https://github.com/zsh-users/zsh-autosuggestions \$ZSH_CUSTOM/plugins/zsh-autosuggestions || true
        git clone https://github.com/zsh-users/zsh-syntax-highlighting \$ZSH_CUSTOM/plugins/zsh-syntax-highlighting || true

        # Créer le .zshrc personnalisé
        cat > \$HOME/.zshrc <<'EOF'
# Path to Oh My Zsh installation
export ZSH="\$HOME/.oh-my-zsh"

# Thème (prompt coloré)
ZSH_THEME="agnoster"

# Plugins
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  sudo
  extract
)

# Charge Oh My Zsh
source \$ZSH/oh-my-zsh.sh

# Aliases utiles
alias ll='ls -lah'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --all'
alias ..='cd ..'
alias ...='cd ../..'

# Autocompletion
autoload -Uz compinit
compinit

# Couleur pour autosuggestions
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

# Syntax highlighting
source \${ZSH_CUSTOM:-\$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
EOF

        # Droits corrects
        chown ubuntu:ubuntu \$HOME/.zshrc
    "

    echo "✅ Oh My Zsh installé et .zshrc personnalisé appliqué."
    echo -e "\033[0;31m⚠️ Le shell par défaut n'a pas été changé automatiquement.\033[0m"
    echo "   Pour le changer manuellement dans la VM : multipass shell $VM_NAME puis :"
    echo -e "\033[1;33mLancez Zsh directement avec : zsh\033[0m"
else
    echo "⚠️ Installation Oh My Zsh ignorée."
fi

# -------------------------------
# AFFICHAGE FINAL
# -------------------------------
if [ "$DRY_RUN" = true ]; then
    echo
    echo "🔍 === RÉSUMÉ DU MODE DRY-RUN ==="
    echo "La VM qui SERAIT créée :"
    echo "  📦 Nom: $VM_NAME"
    echo "  💾 Ressources: $CPUS CPU, $MEM RAM, $DISK disque"
    echo "  🌐 IP simulée: 192.168.64.10"
    echo "  🗄️ Base de données: $DB_NAME (utilisateur: $DB_USER)"
    echo "  📁 Projet: /var/www/html/$PROJECT_NAME"
    echo "  🌐 Répertoire web: $WEB_ROOT_PATH"
    echo "  🌍 Environnement: $ENVIRONMENT"
    echo
    echo "Pour créer réellement la VM, relancez sans --dry-run"
    echo "======================================"
else
    echo "✅ VM prête !"
    echo "➡️ Connexion SSH : ssh ubuntu@$IP"
    echo "➡️ Projet dispo dans : /var/www/html/$PROJECT_NAME"
    echo "➡️ Répertoire web : $WEB_ROOT_PATH"
    echo "➡️ phpMyAdmin dispo : http://$IP/phpmyadmin"
    echo "🌍 Environnement configuré : $ENVIRONMENT"
fi
echo "➡️ MySQL user : $DB_USER / $DB_PASS (DB : $DB_NAME)"
[ -n "${VHOST_DOMAIN:-}" ] && echo "➡️ Virtual Host : http://$VHOST_DOMAIN"
echo "➡️ VS Code Remote-SSH : $VM_NAME"
