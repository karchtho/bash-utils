#!/bin/bash
set -euo pipefail

# -------------------------------
# MONTAGE DOSSIER HOST VERS VM
# -------------------------------

VM_NAME="vmCDA"
HOST_PATH="/home/thomas/Documents/Transfert_VM"
VM_MOUNT_PATH="/var/www/html/host_transfert"

# Vérifications préalables
if ! command -v multipass &> /dev/null; then
    echo "❌ Multipass n'est pas installé ou accessible"
    exit 1
fi

if [ ! -d "$HOST_PATH" ]; then
    echo "❌ Le dossier host '$HOST_PATH' n'existe pas"
    exit 1
fi

if ! multipass info "$VM_NAME" &>/dev/null; then
    echo "❌ La VM '$VM_NAME' n'existe pas ou n'est pas accessible"
    exit 1
fi

# Vérifier si déjà monté
if multipass info "$VM_NAME" | grep -q "Mounts.*$HOST_PATH"; then
    echo "ℹ️ Le dossier '$HOST_PATH' est déjà monté sur la VM '$VM_NAME'"
    exit 0
fi

echo "📁 Montage de '$HOST_PATH' vers '$VM_NAME:$VM_MOUNT_PATH'..."

# Effectuer le montage
if multipass mount "$HOST_PATH" "$VM_NAME:$VM_MOUNT_PATH"; then
    echo "✅ Montage réussi !"
    echo "➡️ Dossier host accessible dans la VM à : $VM_MOUNT_PATH"
else
    echo "❌ Échec du montage"
    exit 1
fi
