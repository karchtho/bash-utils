#!/bin/bash
# Script de diagnostic complet pour VM de développement
# Usage: ./diagnostique.sh [VM_NAME] [PROJECT_NAME] [VHOST_DOMAIN]

set -euo pipefail

# -------------------------------
# COULEURS POUR L'AFFICHAGE
# -------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# -------------------------------
# VARIABLES
# -------------------------------
VM_NAME=${1:-}
PROJECT_NAME=${2:-}
VHOST_DOMAIN=${3:-}
VM_IP=""

# -------------------------------
# FONCTIONS D'AFFICHAGE
# -------------------------------
print_section() {
    echo -e "\n${BLUE}======= $1 =======${NC}"
}

print_ok() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# -------------------------------
# FONCTIONS UTILITAIRES
# -------------------------------
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

vm_exists() {
    multipass list | grep -qw "$1" 2>/dev/null
}

get_vm_ip() {
    multipass info "$1" 2>/dev/null | grep IPv4 | awk '{print $2}' || echo ""
}

# -------------------------------
# TESTS CÔTÉ HÔTE
# -------------------------------
diagnostic_host() {
    print_section "DIAGNOSTIC CÔTÉ HÔTE"
    
    # Multipass
    if command_exists multipass; then
        print_ok "Multipass installé"
        echo "$(multipass version)"
    else
        print_error "Multipass non installé"
        return 1
    fi
    
    # VM spécifiée
    if [ -n "$VM_NAME" ]; then
        if vm_exists "$VM_NAME"; then
            VM_STATE=$(multipass info "$VM_NAME" | grep "State:" | awk '{print $2}')
            if [ "$VM_STATE" = "Running" ]; then
                print_ok "VM '$VM_NAME' en cours d'exécution"
                VM_IP=$(get_vm_ip "$VM_NAME")
                echo "  IP: $VM_IP"
            else
                print_warning "VM '$VM_NAME' existe mais n'est pas active (State: $VM_STATE)"
            fi
        else
            print_error "VM '$VM_NAME' n'existe pas"
        fi
    else
        print_warning "Aucune VM spécifiée pour les tests détaillés"
        echo "VMs disponibles:"
        multipass list | awk 'NR>1 {print "  " $1 " [" $2 "]"}'
    fi
    
    # SSH Configuration
    print_section "SSH CONFIGURATION HÔTE"
    
    SSH_DIR="$HOME/.ssh"
    if [ -d "$SSH_DIR" ]; then
        PERMS=$(stat -c "%a" "$SSH_DIR")
        if [ "$PERMS" = "700" ]; then
            print_ok "Répertoire SSH permissions OK ($PERMS)"
        else
            print_warning "Répertoire SSH permissions incorrectes ($PERMS, devrait être 700)"
        fi
        
        # Clés SSH
        if [ -f "$SSH_DIR/id_ed25519" ]; then
            KEY_PERMS=$(stat -c "%a" "$SSH_DIR/id_ed25519")
            if [ "$KEY_PERMS" = "600" ]; then
                print_ok "Clé privée permissions OK ($KEY_PERMS)"
            else
                print_warning "Clé privée permissions incorrectes ($KEY_PERMS, devrait être 600)"
            fi
        else
            print_error "Clé privée SSH non trouvée ($SSH_DIR/id_ed25519)"
        fi
        
        if [ -f "$SSH_DIR/id_ed25519.pub" ]; then
            print_ok "Clé publique SSH trouvée"
        else
            print_error "Clé publique SSH non trouvée"
        fi
        
        # Fichier config SSH pour VS Code
        if [ -f "$SSH_DIR/config" ]; then
            print_ok "Fichier ~/.ssh/config existe"
            
            if [ -n "$VM_NAME" ] && [ -n "$VM_IP" ]; then
                if grep -q "Host $VM_NAME" "$SSH_DIR/config"; then
                    print_ok "Configuration SSH pour '$VM_NAME' trouvée"
                    
                    # Vérifier l'IP dans le config
                    CONFIG_IP=$(grep -A 10 "Host $VM_NAME" "$SSH_DIR/config" | grep -m1 "HostName" | awk '{print $2}')
                    if [ "$CONFIG_IP" = "$VM_IP" ]; then
                        print_ok "IP dans ~/.ssh/config correspond ($CONFIG_IP)"
                    else
                        print_warning "IP dans ~/.ssh/config obsolète (config: $CONFIG_IP, actuelle: $VM_IP)"
                    fi
                else
                    print_warning "Aucune configuration SSH pour '$VM_NAME' dans ~/.ssh/config"
                fi
            fi
        else
            print_warning "Fichier ~/.ssh/config non trouvé"
        fi
        
        
        # Known hosts
        if [ -f "$SSH_DIR/known_hosts" ]; then
            print_ok "Fichier known_hosts existe"
            if [ -n "$VM_NAME" ] && [ -n "${VM_IP:-}" ]; then
                # Vérifier IP directe ou hachée
                if grep -q "$VM_IP" "$SSH_DIR/known_hosts" || ssh-keygen -F "$VM_IP" -f "$SSH_DIR/known_hosts" >/dev/null 2>&1; then
                    print_ok "VM IP présente dans known_hosts"
                else
                    print_warning "VM IP absente de known_hosts (peut être normal si clés hachées)"
                fi
            fi
        else
            print_warning "Fichier known_hosts non trouvé"
        fi
    else
        print_error "Répertoire SSH non trouvé ($SSH_DIR)"
    fi
    
    # /etc/hosts pour VHOST
    if [ -n "$VHOST_DOMAIN" ] && [ -n "$VM_IP" ]; then
        print_section "VIRTUAL HOST LOCAL"
        
        if grep -q "$VHOST_DOMAIN" /etc/hosts 2>/dev/null; then
            HOSTS_IP=$(grep "$VHOST_DOMAIN" /etc/hosts | awk '{print $1}' | head -1)
            if [ "$HOSTS_IP" = "$VM_IP" ]; then
                print_ok "/etc/hosts configuré correctement pour '$VHOST_DOMAIN' ($HOSTS_IP)"
            else
                print_warning "/etc/hosts IP obsolète pour '$VHOST_DOMAIN' (hosts: $HOSTS_IP, VM: $VM_IP)"
            fi
        else
            print_warning "'$VHOST_DOMAIN' absent de /etc/hosts"
        fi
    fi
    
    # Test de connexion
    if [ -n "$VM_NAME" ] && [ -n "$VM_IP" ]; then
        print_section "TESTS DE CONNEXION"
        
        # Ping
        if ping -c 1 -W 2 "$VM_IP" >/dev/null 2>&1; then
            print_ok "Ping vers VM OK"
        else
            print_error "Ping vers VM échoué"
        fi
        
        # SSH
        if ssh -o ConnectTimeout=5 -o BatchMode=yes ubuntu@"$VM_IP" exit >/dev/null 2>&1; then
            print_ok "Connexion SSH sans password OK"
        else
            print_error "Connexion SSH échouée"
        fi
    fi
}

# -------------------------------
# TESTS CÔTÉ VM
# -------------------------------
diagnostic_vm() {
    if [ -z "$VM_NAME" ]; then
        print_warning "Aucune VM spécifiée, diagnostic VM ignoré"
        return
    fi
    
    if ! vm_exists "$VM_NAME"; then
        print_error "VM '$VM_NAME' n'existe pas"
        return
    fi
    
    print_section "DIAGNOSTIC CÔTÉ VM ($VM_NAME)"
    
    # Test de connexion à la VM
    if ! multipass exec "$VM_NAME" -- echo "test" >/dev/null 2>&1; then
        print_error "Impossible de se connecter à la VM"
        return
    fi
    
    # Services système
    print_section "SERVICES SYSTÈME"
    
    SERVICES=("apache2" "mariadb" "ssh")

    # Détecter la version PHP-FPM installée
    PHP_FPM_SERVICE=""
    for php_version in "php8.3-fpm" "php8.2-fpm" "php8.1-fpm" "php8.0-fpm"; do
        if multipass exec "$VM_NAME" -- sudo systemctl list-unit-files | grep -q "$php_version"; then
            PHP_FPM_SERVICE="$php_version"
            break
        fi
    done

    if [ -n "$PHP_FPM_SERVICE" ]; then
        SERVICES+=("$PHP_FPM_SERVICE")
    fi

    for service in "${SERVICES[@]}"; do
        if multipass exec "$VM_NAME" -- sudo systemctl is-active "$service" >/dev/null 2>&1; then
            print_ok "$service actif"
        else
            print_error "$service inactif"
        fi
        
        if multipass exec "$VM_NAME" -- sudo systemctl is-enabled "$service" >/dev/null 2>&1; then
            print_ok "$service enabled"
        else
            print_warning "$service non enabled"
        fi
    done
    
    # Ports réseau
    print_section "PORTS RÉSEAU"
    
    PORTS=("80" "22" "3306")
    PORT_NAMES=("HTTP" "SSH" "MySQL")
    
    for i in "${!PORTS[@]}"; do
        PORT="${PORTS[$i]}"
        NAME="${PORT_NAMES[$i]}"
        
        if multipass exec "$VM_NAME" -- sudo ss -tlnp | grep -q ":$PORT "; then
            print_ok "Port $PORT ($NAME) ouvert"
        else
            print_error "Port $PORT ($NAME) fermé"
        fi
    done
    
    # Structure web
    print_section "STRUCTURE WEB"
    
    if multipass exec "$VM_NAME" -- test -d /var/www/html; then
        print_ok "Répertoire /var/www/html existe"
        
        # Permissions du répertoire web principal - CORRIGÉ
        WEB_PERMS=$(multipass exec "$VM_NAME" -- stat -c "%a" /var/www/html)
        WEB_OWNER=$(multipass exec "$VM_NAME" -- stat -c "%U:%G" /var/www/html)
        
        if [ "$WEB_OWNER" = "ubuntu:www-data" ] && [ "$WEB_PERMS" = "775" ]; then
            print_ok "Permissions /var/www/html OK: $WEB_PERMS ($WEB_OWNER)"
        else
            print_warning "Permissions /var/www/html: $WEB_PERMS ($WEB_OWNER) - Recommandé: 775 (ubuntu:www-data)"
        fi
        
        if [ -n "$PROJECT_NAME" ]; then
            PROJECT_PATH="/var/www/html/$PROJECT_NAME"
            PUBLIC_PATH="/var/www/html/$PROJECT_NAME/public"

            if multipass exec "$VM_NAME" -- test -d "$PROJECT_PATH"; then
                print_ok "Projet '$PROJECT_NAME' existe"

                # Détecter l'architecture
                if multipass exec "$VM_NAME" -- test -d "$PUBLIC_PATH"; then
                    print_ok "Architecture MVC détectée (dossier public)"
                    WEB_ROOT_PATH="$PUBLIC_PATH"
                    ARCHITECTURE="MVC"
                else
                    print_ok "Architecture directe détectée"
                    WEB_ROOT_PATH="$PROJECT_PATH"
                    ARCHITECTURE="direct"
                fi

                # Vérifier les permissions du projet
                PROJECT_PERMS=$(multipass exec "$VM_NAME" -- stat -c "%a" "$PROJECT_PATH")
                PROJECT_OWNER=$(multipass exec "$VM_NAME" -- stat -c "%U:%G" "$PROJECT_PATH")

                if [ "$PROJECT_PERMS" = "775" ] && [ "$PROJECT_OWNER" = "ubuntu:www-data" ]; then
                    print_ok "Permissions projet OK: $PROJECT_PERMS ($PROJECT_OWNER)"
                else
                    print_warning "Permissions projet: $PROJECT_PERMS ($PROJECT_OWNER) - Recommandé: 775 (ubuntu:www-data)"
                fi

                # Vérifier les permissions du répertoire web
                if [ "$ARCHITECTURE" = "MVC" ]; then
                    WEB_PERMS=$(multipass exec "$VM_NAME" -- stat -c "%a" "$WEB_ROOT_PATH")
                    WEB_OWNER=$(multipass exec "$VM_NAME" -- stat -c "%U:%G" "$WEB_ROOT_PATH")

                    if [ "$WEB_PERMS" = "775" ] && [ "$WEB_OWNER" = "ubuntu:www-data" ]; then
                        print_ok "Permissions répertoire web OK: $WEB_PERMS ($WEB_OWNER)"
                    else
                        print_warning "Permissions répertoire web: $WEB_PERMS ($WEB_OWNER) - Recommandé: 775 (ubuntu:www-data)"
                    fi
                fi
            else
                print_warning "Projet '$PROJECT_NAME' n'existe pas dans /var/www/html"
            fi
        fi
    else
        print_error "Répertoire /var/www/html n'existe pas"
    fi
    
    # Configuration Apache
    print_section "CONFIGURATION APACHE"
    
    # Configuration PHP-FPM
    if multipass exec "$VM_NAME" -- sudo systemctl is-active php8.3-fpm >/dev/null 2>&1; then
        print_ok "PHP-FPM actif"
    elif multipass exec "$VM_NAME" -- sudo systemctl is-active php8.2-fpm >/dev/null 2>&1; then
        print_ok "PHP-FPM actif (PHP 8.2)"
    elif multipass exec "$VM_NAME" -- sudo systemctl is-active php8.1-fpm >/dev/null 2>&1; then
        print_ok "PHP-FPM actif (PHP 8.1)"
    else
        print_error "PHP-FPM non actif"
    fi

    # Vérifier proxy_fcgi pour Apache-FPM
    if multipass exec "$VM_NAME" -- apache2ctl -M | grep -q proxy_fcgi; then
        print_ok "Module proxy_fcgi chargé (requis pour PHP-FPM)"
    else
        print_warning "Module proxy_fcgi non chargé"
    fi
    
    # Sites Apache
    DEFAULT_SITE="/etc/apache2/sites-available/000-default.conf"
    if multipass exec "$VM_NAME" -- test -f "$DEFAULT_SITE"; then
        print_ok "Site par défaut Apache existe"
    fi
    
    # Virtual Host personnalisé
    if [ -n "$VHOST_DOMAIN" ]; then
        VHOST_FILE="/etc/apache2/sites-available/$VHOST_DOMAIN.conf"
        if multipass exec "$VM_NAME" -- test -f "$VHOST_FILE"; then
            print_ok "Virtual Host '$VHOST_DOMAIN' configuré"
            
            if multipass exec "$VM_NAME" -- test -L "/etc/apache2/sites-enabled/$VHOST_DOMAIN.conf"; then
                print_ok "Virtual Host '$VHOST_DOMAIN' activé"
            else
                print_warning "Virtual Host '$VHOST_DOMAIN' non activé"
            fi
            
            # Vérifier DocumentRoot
            if [ -n "$PROJECT_NAME" ] && [ -n "${WEB_ROOT_PATH:-}" ]; then
                if multipass exec "$VM_NAME" -- grep -q "$WEB_ROOT_PATH" "$VHOST_FILE"; then
                    print_ok "DocumentRoot pointe vers le bon répertoire ($ARCHITECTURE)"
                else
                    ACTUAL_ROOT=$(multipass exec "$VM_NAME" -- grep "DocumentRoot" "$VHOST_FILE" | awk '{print $2}' | head -1)
                    print_warning "DocumentRoot actuel: $ACTUAL_ROOT - Attendu: $WEB_ROOT_PATH ($ARCHITECTURE)"
                fi
            fi
        else
            print_warning "Virtual Host '$VHOST_DOMAIN' non configuré"
        fi
    fi
    
    # Configuration SSH VM
    print_section "SSH CONFIGURATION VM"
    
    SSH_DIR_VM="/home/ubuntu/.ssh"
    if multipass exec "$VM_NAME" -- test -d "$SSH_DIR_VM"; then
        SSH_PERMS_VM=$(multipass exec "$VM_NAME" -- stat -c "%a" "$SSH_DIR_VM")
        if [ "$SSH_PERMS_VM" = "700" ]; then
            print_ok "Répertoire SSH VM permissions OK ($SSH_PERMS_VM)"
        else
            print_warning "Répertoire SSH VM permissions incorrectes ($SSH_PERMS_VM)"
        fi
        
        # Authorized keys
        AUTH_KEYS="$SSH_DIR_VM/authorized_keys"
        if multipass exec "$VM_NAME" -- test -f "$AUTH_KEYS"; then
            AUTH_PERMS=$(multipass exec "$VM_NAME" -- stat -c "%a" "$AUTH_KEYS")
            if [ "$AUTH_PERMS" = "600" ]; then
                print_ok "Authorized keys permissions OK ($AUTH_PERMS)"
            else
                print_warning "Authorized keys permissions incorrectes ($AUTH_PERMS)"
            fi
            
            KEY_COUNT=$(multipass exec "$VM_NAME" -- bash -c "wc -l < $AUTH_KEYS")
            print_ok "$KEY_COUNT clé(s) autorisée(s)"
        else
            print_error "Fichier authorized_keys non trouvé"
        fi
        
        # Clé SSH pour Git
        if multipass exec "$VM_NAME" -- test -f "$SSH_DIR_VM/id_ed25519"; then
            print_ok "Clé SSH VM pour Git existe"
        else
            print_warning "Clé SSH VM pour Git non trouvée"
        fi
    else
        print_error "Répertoire SSH VM non trouvé"
    fi
    
    # Configuration Git
    print_section "CONFIGURATION GIT"
    
    GIT_USER=$(multipass exec "$VM_NAME" -- git config --global user.name 2>/dev/null || echo "")
    GIT_EMAIL=$(multipass exec "$VM_NAME" -- git config --global user.email 2>/dev/null || echo "")
    
    if [ -n "$GIT_USER" ]; then
        print_ok "Git user configuré: $GIT_USER"
    else
        print_warning "Git user non configuré"
    fi
    
    if [ -n "$GIT_EMAIL" ]; then
        print_ok "Git email configuré: $GIT_EMAIL"
    else
        print_warning "Git email non configuré"
    fi
    
    # Base de données
    print_section "BASE DE DONNÉES"
    
    if multipass exec "$VM_NAME" -- sudo mysqladmin ping >/dev/null 2>&1; then
        print_ok "MySQL/MariaDB répond"
        
        # Bases de données
        if [ -n "$PROJECT_NAME" ]; then
            DB_NAME="${PROJECT_NAME}_db"
            if multipass exec "$VM_NAME" -- mysql -e "USE \`$DB_NAME\`;" >/dev/null 2>&1; then
                print_ok "Base de données '$DB_NAME' existe"
            else
                print_warning "Base de données '$DB_NAME' n'existe pas"
            fi
        fi
    else
        print_error "MySQL/MariaDB ne répond pas"
    fi
    
    # phpMyAdmin
    if multipass exec "$VM_NAME" -- test -d /usr/share/phpmyadmin; then
        print_ok "phpMyAdmin installé"
        
        if multipass exec "$VM_NAME" -- test -f /etc/apache2/conf-enabled/phpmyadmin.conf; then
            print_ok "phpMyAdmin configuré dans Apache"
        else
            print_warning "phpMyAdmin non configuré dans Apache"
        fi
    else
        print_warning "phpMyAdmin non installé"
    fi
    
    # Tests PHP
    print_section "CONFIGURATION PHP"
    
    PHP_VERSION=$(multipass exec "$VM_NAME" -- php -v | head -1 | awk '{print $2}' 2>/dev/null || echo "")
    if [ -n "$PHP_VERSION" ]; then
        print_ok "PHP installé: $PHP_VERSION"
    else
        print_error "PHP non installé"
    fi
    
    PHP_MODULES=("mysql" "curl" "zip" "mbstring")
    for module in "${PHP_MODULES[@]}"; do
        if multipass exec "$VM_NAME" -- php -m | grep -q "$module"; then
            print_ok "Module PHP $module chargé"
        else
            print_warning "Module PHP $module manquant"
        fi
    done
}

# -------------------------------
# TESTS FONCTIONNELS
# -------------------------------
functional_tests() {
    if [ -z "$VM_IP" ]; then
        print_warning "IP VM non disponible, tests fonctionnels ignorés"
        return
    fi
    
    print_section "TESTS FONCTIONNELS"
    
    # Test HTTP
    if curl -s -I "http://$VM_IP/" | grep -q "200 OK"; then
        print_ok "Serveur web répond (HTTP 200)"
    else
        print_error "Serveur web ne répond pas"
    fi
    
    # Test projet
    if [ -n "$PROJECT_NAME" ]; then
        # Déterminer l'URL à tester selon l'architecture
        if [ "${ARCHITECTURE:-}" = "MVC" ] && [ -n "$VHOST_DOMAIN" ]; then
            TEST_URL="http://$VHOST_DOMAIN/"
            URL_TYPE="Virtual Host (architecture MVC)"
        elif [ -n "$VHOST_DOMAIN" ]; then
            TEST_URL="http://$VHOST_DOMAIN/"
            URL_TYPE="Virtual Host"
        else
            TEST_URL="http://$VM_IP/$PROJECT_NAME/"
            URL_TYPE="IP directe"
        fi

        if curl -s -I "$TEST_URL" | grep -q -E "200 OK|403 Forbidden"; then
            print_ok "Projet accessible via $URL_TYPE: $TEST_URL"
        else
            print_warning "Projet non accessible via $URL_TYPE: $TEST_URL"
        fi
    fi
    
    # Test phpMyAdmin
    if curl -s -I "http://$VM_IP/phpmyadmin/" | grep -q -E "200 OK|302"; then
        print_ok "phpMyAdmin accessible"
    else
        print_warning "phpMyAdmin non accessible"
    fi
    
    # Test VHOST
    if [ -n "$VHOST_DOMAIN" ]; then
        if curl -s -I "http://$VHOST_DOMAIN/" | grep -q "200 OK"; then
            print_ok "Virtual Host '$VHOST_DOMAIN' fonctionne"
        else
            print_warning "Virtual Host '$VHOST_DOMAIN' ne répond pas"
        fi
    fi
}

# -------------------------------
# AFFICHAGE DES RECOMMANDATIONS
# -------------------------------
show_recommendations() {
    print_section "RECOMMANDATIONS"
    
    echo "Pour corriger les problèmes courants:"
    echo ""
    echo "# Réparer permissions répertoire web principal:"
    echo "multipass exec $VM_NAME -- sudo chown -R ubuntu:www-data /var/www/html"
    echo "multipass exec $VM_NAME -- sudo chmod 775 /var/www/html"
    echo ""
    echo "# Réparer permissions projet spécifique:"
    if [ -n "$PROJECT_NAME" ]; then
        echo "multipass exec $VM_NAME -- sudo chown -R ubuntu:www-data /var/www/html/$PROJECT_NAME"
        echo "multipass exec $VM_NAME -- sudo chmod -R 775 /var/www/html/$PROJECT_NAME"

        if [ "${ARCHITECTURE:-}" = "MVC" ]; then
            echo "# Architecture MVC - Permissions dossier public :"
            echo "multipass exec $VM_NAME -- sudo chown ubuntu:www-data /var/www/html/$PROJECT_NAME/public"
            echo "multipass exec $VM_NAME -- sudo chmod 775 /var/www/html/$PROJECT_NAME/public"
        fi
    fi
    echo ""
    echo "# Réparer SSH VM:"
    echo "multipass exec $VM_NAME -- chmod 700 ~/.ssh"
    echo "multipass exec $VM_NAME -- chmod 600 ~/.ssh/authorized_keys"
    echo ""
    echo "# Redémarrer services:"
    echo "multipass exec $VM_NAME -- sudo systemctl restart apache2"
    echo "multipass exec $VM_NAME -- sudo systemctl restart mariadb"
    echo "multipass exec $VM_NAME -- sudo systemctl restart php8.3-fpm  # (ou php8.2-fpm selon version)"
    echo ""
    echo "# Mettre à jour /etc/hosts (si VHOST):"
    [ -n "$VHOST_DOMAIN" ] && [ -n "$VM_IP" ] && echo "echo '$VM_IP $VHOST_DOMAIN' | sudo tee -a /etc/hosts"
}

# -------------------------------
# FONCTION PRINCIPALE
# -------------------------------
main() {
    echo "🔍 DIAGNOSTIC VM DEVELOPMENT ENVIRONMENT"
    echo "========================================"
    
    if [ -n "$VM_NAME" ]; then
        echo "VM: $VM_NAME"
        VM_IP=$(get_vm_ip "$VM_NAME")
    fi
    if [ -n "$PROJECT_NAME" ]; then
        echo "Projet: $PROJECT_NAME"
        [ -n "${ARCHITECTURE:-}" ] && echo "Architecture: $ARCHITECTURE"
        [ -n "${WEB_ROOT_PATH:-}" ] && echo "Répertoire web: $WEB_ROOT_PATH"
    fi
    [ -n "$VHOST_DOMAIN" ] && echo "VHost: $VHOST_DOMAIN"
    
    diagnostic_host
    diagnostic_vm
    functional_tests
    show_recommendations
    
    print_section "DIAGNOSTIC TERMINÉ"
    echo "Utilisez les commandes de correction ci-dessus si nécessaire."
}

# -------------------------------
# VÉRIFICATION DES ARGUMENTS
# -------------------------------
if [ $# -eq 0 ]; then
    echo -e "${BLUE}Usage:${NC} diagnostique.sh ${YELLOW}[VM_NAME] [PROJECT_NAME] [VHOST_DOMAIN]${NC}"
    echo ""
    echo -e "${GREEN}Exemples:${NC}"
    echo -e "  ${BLUE}diagnostique.sh${NC}                                    ${YELLOW}# Diagnostic général${NC}"
    echo -e "  ${BLUE}diagnostique.sh${NC} ${GREEN}webvm${NC}                             ${YELLOW}# Diagnostic VM spécifique${NC}"
    echo -e "  ${BLUE}diagnostique.sh${NC} ${GREEN}webvm${NC} ${GREEN}projet1${NC}                     ${YELLOW}# + vérifications projet${NC}"
    echo -e "  ${BLUE}diagnostique.sh${NC} ${GREEN}webvm${NC} ${GREEN}projet1${NC} ${GREEN}projet1.local${NC}       ${YELLOW}# + vérifications vhost${NC}"
    echo ""
    echo -e "${GREEN}VMs disponibles:${NC}"
    if command_exists multipass; then
        multipass list | awk -v green="$GREEN" -v red="$RED" -v yellow="$YELLOW" -v nc="$NC" 'NR>1 {
            state_color = ""
            if ($2 == "Running") state_color = green
            else if ($2 == "Stopped") state_color = red
            else state_color = yellow
            printf "  %s%s%s [%s%s%s]\n", green, $1, nc, state_color, $2, nc
        }'
    else
        echo -e "  ${RED}Multipass non installé${NC}"
    fi
    echo ""
    echo -e -n "${YELLOW}Continuer le diagnostic général ? (y/N)${NC} "
    read -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
fi

main