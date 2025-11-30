#!/bin/bash
set -euo pipefail

# -------------------------------
# SCRIPT DE NETTOYAGE VM MULTIPASS
# -------------------------------
# Nettoie les VMs, configurations et entrées /etc/hosts

BACKUP_DIR="/tmp/hosts_backups"

# Fonctions utilitaires pour /etc/hosts
source_backup_functions() {
    # Réutilisation des fonctions du script connect_project.sh
    create_backup_dir() {
        if [ ! -d "$BACKUP_DIR" ]; then
            mkdir -p "$BACKUP_DIR"
            echo "📁 Répertoire de backup créé : $BACKUP_DIR"
        fi
    }

    backup_hosts() {
        create_backup_dir
        local timestamp
        timestamp=$(date '+%Y-%m-%d-%Hh%M')
        local backup_file="$BACKUP_DIR/hosts.backup.$timestamp"

        if cp /etc/hosts "$backup_file"; then
            echo "💾 Backup /etc/hosts créé : $backup_file"
            return 0
        else
            echo "❌ Erreur lors du backup de /etc/hosts"
            return 1
        fi
    }
}

source_backup_functions

# Afficher le menu principal
show_menu() {
    echo "🧹 === NETTOYAGE VM MULTIPASS ==="
    echo
    echo "1) 📋 Lister toutes les VMs"
    echo "2) 🗑️  Supprimer une VM spécifique"
    echo "3) 🗑️  Supprimer toutes les VMs arrêtées"
    echo "4) 🧹 Nettoyer les entrées /etc/hosts orphelines"
    echo "5) 🗑️  Nettoyer les configurations SSH orphelines"
    echo "6) 📁 Gérer les backups /etc/hosts"
    echo "7) 🔄 Nettoyage complet (tout supprimer)"
    echo "8) ❌ Quitter"
    echo
}

# Lister toutes les VMs
list_vms() {
    echo "📋 === LISTE DES VMs ==="
    multipass list
    echo
}

# Supprimer une VM spécifique
delete_specific_vm() {
    echo "🗑️ === SUPPRESSION VM SPÉCIFIQUE ==="
    echo
    multipass list
    echo
    read -r -p "➡️ Nom de la VM à supprimer (ou ENTER pour annuler) : " vm_name

    if [ -z "$vm_name" ]; then
        echo "❌ Annulé"
        return 0
    fi

    if ! multipass info "$vm_name" &>/dev/null; then
        echo "❌ VM '$vm_name' non trouvée"
        return 1
    fi

    echo "⚠️ Vous allez supprimer la VM '$vm_name'"
    read -r -p "Confirmer ? [y/N] : " confirm

    if [[ "$confirm" =~ ^[yY]$ ]]; then
        echo "🛑 Arrêt de la VM..."
        multipass stop "$vm_name" 2>/dev/null || true
        echo "🗑️ Suppression de la VM..."
        multipass delete "$vm_name"
        multipass purge
        echo "✅ VM '$vm_name' supprimée"
    else
        echo "❌ Annulé"
    fi
}

# Supprimer toutes les VMs arrêtées
delete_stopped_vms() {
    echo "🗑️ === SUPPRESSION VMs ARRÊTÉES ==="

    local stopped_vms
    stopped_vms=$(multipass list --format csv | awk -F',' 'NR>1 && $2=="Stopped" {print $1}')

    if [ -z "$stopped_vms" ]; then
        echo "ℹ️ Aucune VM arrêtée trouvée"
        return 0
    fi

    echo "VMs arrêtées trouvées :"
    echo "$stopped_vms"
    echo
    read -r -p "Supprimer toutes ces VMs ? [y/N] : " confirm

    if [[ "$confirm" =~ ^[yY]$ ]]; then
        while IFS= read -r vm; do
            echo "🗑️ Suppression de '$vm'..."
            multipass delete "$vm"
        done <<< "$stopped_vms"
        multipass purge
        echo "✅ VMs arrêtées supprimées"
    else
        echo "❌ Annulé"
    fi
}

# Nettoyer les configurations SSH orphelines
cleanup_orphaned_ssh() {
    echo "🗑️ === NETTOYAGE CONFIGURATIONS SSH ==="

    local ssh_config="$HOME/.ssh/config"
    local ssh_known_hosts="$HOME/.ssh/known_hosts"

    if [ ! -f "$ssh_config" ]; then
        echo "ℹ️ Aucun fichier ~/.ssh/config trouvé"
        return 0
    fi

    # Sauvegarder les fichiers SSH
    cp "$ssh_config" "$ssh_config.backup.$(date '+%Y-%m-%d-%Hh%M')"
    [ -f "$ssh_known_hosts" ] && cp "$ssh_known_hosts" "$ssh_known_hosts.backup.$(date '+%Y-%m-%d-%Hh%M')"
    echo "💾 Backup des configurations SSH créé"

    # Lister les VMs actives
    local active_vms
    active_vms=$(multipass list --format csv | awk -F',' 'NR>1 {print $1}')

    echo "🔍 Recherche de configurations SSH orphelines..."

    # Extraire les hosts définis dans ~/.ssh/config
    local ssh_hosts
    ssh_hosts=$(grep "^Host " "$ssh_config" | awk '{print $2}' | grep -v "\*")

    local orphaned_hosts=""
    while IFS= read -r host; do
        # Vérifier si le host correspond à une VM active
        if ! echo "$active_vms" | grep -q "^$host$"; then
            # Vérifier si c'est potentiellement une VM (exclure localhost, github.com, etc.)
            if [[ ! "$host" =~ \. ]] && [[ "$host" != "localhost" ]] && [[ "$host" != "github.com" ]] && [[ "$host" != "gitlab.com" ]]; then
                orphaned_hosts="$orphaned_hosts $host"
            fi
        fi
    done <<< "$ssh_hosts"

    if [ -z "$orphaned_hosts" ]; then
        echo "✅ Aucune configuration SSH orpheline trouvée"
        return 0
    fi

    echo "Configurations SSH potentiellement orphelines :"
    for host in $orphaned_hosts; do
        echo "  - $host"
    done
    echo
    read -r -p "Supprimer ces configurations ? [y/N] : " confirm

    if [[ "$confirm" =~ ^[yY]$ ]]; then
        for host in $orphaned_hosts; do
            # Supprimer le bloc Host du fichier config
            sed -i "/^Host $host$/,/^$/d" "$ssh_config"

            # Supprimer les entrées du known_hosts si elles existent
            if [ -f "$ssh_known_hosts" ]; then
                # Essayer de récupérer l'IP du host depuis l'ancien config
                local host_ip
                host_ip=$(grep -A 10 "^Host $host$" "$ssh_config.backup."* 2>/dev/null | grep "HostName" | awk '{print $2}' | head -1)
                if [ -n "$host_ip" ]; then
                    ssh-keygen -R "$host_ip" -f "$ssh_known_hosts" 2>/dev/null || true
                fi
            fi

            echo "🗑️ Supprimé : $host"
        done
        echo "✅ Configurations SSH orphelines supprimées"
    else
        echo "❌ Annulé"
    fi
}

# Nettoyer les entrées /etc/hosts orphelines
cleanup_orphaned_hosts() {
    echo "🧹 === NETTOYAGE /etc/hosts ORPHELIN ==="

    backup_hosts

    # Lister les IPs des VMs actives
    local active_ips
    active_ips=$(multipass list --format csv | awk -F',' 'NR>1 && $2=="Running" {print $3}')

    if [ -z "$active_ips" ]; then
        echo "ℹ️ Aucune VM active, impossible de déterminer les entrées orphelines"
        return 0
    fi

    echo "🔍 Recherche d'entrées orphelines dans /etc/hosts..."

    # Chercher les entrées qui contiennent des IPs de la plage Multipass (172.x ou 10.x généralement)
    local orphaned_entries
    orphaned_entries=$(grep -E '^(172\.|10\.|192\.168\.)' /etc/hosts | while IFS= read -r line; do
        local ip
        ip=$(echo "$line" | awk '{print $1}')
        if ! echo "$active_ips" | grep -q "$ip"; then
            echo "$line"
        fi
    done)

    if [ -z "$orphaned_entries" ]; then
        echo "✅ Aucune entrée orpheline trouvée"
        return 0
    fi

    echo "Entrées potentiellement orphelines :"
    echo "$orphaned_entries"
    echo
    read -r -p "Supprimer ces entrées ? [y/N] : " confirm

    if [[ "$confirm" =~ ^[yY]$ ]]; then
        # Supprimer les entrées orphelines
        while IFS= read -r line; do
            local ip
            ip=$(echo "$line" | awk '{print $1}')
            local domain
            domain=$(echo "$line" | awk '{print $2}')
            sudo sed -i "\|^${ip}[[:space:]]*${domain}|d" /etc/hosts
            echo "🗑️ Supprimé : $ip $domain"
        done <<< "$orphaned_entries"
        echo "✅ Entrées orphelines supprimées"
    else
        echo "❌ Annulé"
    fi
}

# Gérer les backups /etc/hosts
manage_hosts_backups() {
    echo "📁 === GESTION BACKUPS /etc/hosts ==="

    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        echo "ℹ️ Aucun backup trouvé dans $BACKUP_DIR"
        return 0
    fi

    echo "Backups disponibles :"
    ls -lt "$BACKUP_DIR"/hosts.backup.* | while IFS= read -r line; do
        echo "$line"
    done
    echo

    echo "1) Restaurer un backup"
    echo "2) Supprimer tous les backups"
    echo "3) Retour au menu principal"
    echo
    read -r -p "Choix : " choice

    case $choice in
        1)
            read -r -p "Nom complet du fichier backup à restaurer : " backup_file
            if [ -f "$BACKUP_DIR/$backup_file" ]; then
                backup_hosts  # Backup avant restauration
                sudo cp "$BACKUP_DIR/$backup_file" /etc/hosts
                echo "✅ /etc/hosts restauré depuis : $backup_file"
            else
                echo "❌ Backup non trouvé : $backup_file"
            fi
            ;;
        2)
            read -r -p "Supprimer tous les backups ? [y/N] : " confirm
            if [[ "$confirm" =~ ^[yY]$ ]]; then
                rm -rf "$BACKUP_DIR"
                echo "✅ Tous les backups supprimés"
            fi
            ;;
        3)
            return 0
            ;;
        *)
            echo "❌ Choix invalide"
            ;;
    esac
}

# Nettoyage complet
full_cleanup() {
    echo "🔄 === NETTOYAGE COMPLET ==="
    echo "⚠️ ATTENTION : Ceci va :"
    echo "  - Arrêter et supprimer TOUTES les VMs"
    echo "  - Nettoyer toutes les entrées /etc/hosts suspectes"
    echo "  - Nettoyer toutes les configurations SSH orphelines"
    echo "  - Supprimer tous les backups"
    echo
    read -r -p "Êtes-vous ABSOLUMENT sûr ? Tapez 'SUPPRIMER' pour confirmer : " confirm

    if [ "$confirm" = "SUPPRIMER" ]; then
        backup_hosts

        # Supprimer toutes les VMs
        local all_vms
        all_vms=$(multipass list --format csv | awk -F',' 'NR>1 {print $1}')
        if [ -n "$all_vms" ]; then
            echo "🛑 Arrêt de toutes les VMs..."
            multipass stop --all 2>/dev/null || true
            echo "🗑️ Suppression de toutes les VMs..."
            while IFS= read -r vm; do
                multipass delete "$vm" 2>/dev/null || true
            done <<< "$all_vms"
            multipass purge
        fi

        # Nettoyer /etc/hosts (supprime toutes les IP privées)
        echo "🧹 Nettoyage /etc/hosts..."
        sudo sed -i '/^172\./d; /^10\./d; /^192\.168\./d' /etc/hosts

        # Nettoyer les configurations SSH
        echo "🗑️ Nettoyage configurations SSH..."
        local ssh_config="$HOME/.ssh/config"
        if [ -f "$ssh_config" ]; then
            # Backup avant nettoyage
            cp "$ssh_config" "$ssh_config.full-cleanup-backup.$(date '+%Y-%m-%d-%Hh%M')"

            # Supprimer tous les hosts sans domaine (potentiellement des VMs)
            local hosts_to_remove
            hosts_to_remove=$(grep "^Host " "$ssh_config" | awk '{print $2}' | grep -v "\*" | grep -v "\.")
            while IFS= read -r host; do
                if [[ "$host" != "localhost" ]]; then
                    sed -i "/^Host $host$/,/^$/d" "$ssh_config"
                fi
            done <<< "$hosts_to_remove"
        fi

        # Supprimer les backups
        rm -rf "$BACKUP_DIR"

        echo "✅ Nettoyage complet terminé"
    else
        echo "❌ Annulé (heureusement !)"
    fi
}

# Boucle principale du menu
main() {
    while true; do
        echo
        show_menu
        read -r -p "➡️ Votre choix : " choice
        echo

        case $choice in
            1) list_vms ;;
            2) delete_specific_vm ;;
            3) delete_stopped_vms ;;
            4) cleanup_orphaned_hosts ;;
            5) cleanup_orphaned_ssh ;;
            6) manage_hosts_backups ;;
            7) full_cleanup ;;
            8)
                echo "👋 Au revoir !"
                exit 0
                ;;
            *)
                echo "❌ Choix invalide. Essayez encore."
                ;;
        esac

        read -r -p "Appuyez sur ENTER pour continuer..."
    done
}

# Vérification que multipass est disponible
if ! command -v multipass &> /dev/null; then
    echo "❌ Multipass n'est pas installé ou accessible"
    exit 1
fi

# Lancement du script
main