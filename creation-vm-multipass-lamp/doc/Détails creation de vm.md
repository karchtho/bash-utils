
# Guide détaillé — Script de création de VM

Ce document explique en détail le fonctionnement du script `create_webvm.sh` qui automatise la création et la configuration complète d'une VM de développement.

## Objectif du script

Créer et configurer automatiquement :
- VM Multipass (Ubuntu 24.04) avec ressources personnalisables
- Stack LAMP (Linux, Apache, MariaDB, PHP)
- Configuration SSH sans mot de passe
- Intégration VS Code Remote-SSH
- Base de données projet avec phpMyAdmin
- Clonage automatique de dépôts Git
- Installation optionnelle d'Oh My Zsh

---

## 1. En-tête du script

```bash
#!/bin/bash
set -euo pipefail  # Stop script si erreur ou variable non définie
```

### Sécurisation du script

- **`#!/bin/bash`** : Définit l'interpréteur bash
- **`set -euo pipefail`** : Options de sécurité
  - `-e` : Arrêt immédiat en cas d'erreur
  - `-u` : Erreur sur variables non définies
  - `-o pipefail` : Échec de pipeline si une commande échoue

### Avantages
- Détection précoce des erreurs
- Évite les comportements imprévisibles
- Facilite le débogage

---

## 2. Chargement d’un fichier de configuration (optionnel)

```bash
CONFIG_DIR="./config"
CONFIG_FILES=("$CONFIG_DIR"/*.conf)
SELECTED_CONFIG=""

if [ -e "${CONFIG_FILES[0]}" ]; then
    select CONF in "${CONFIG_FILES[@]}" "Aucune / Mode interactif"; do
        ...
    done
else
    echo "⚠️ Aucun fichier de config trouvé..."
fi
```

* Cherche des `.conf` dans `./config`.
* Si présents, propose une sélection interactive (`select`) pour `source` (exécuter) le fichier choisi — permet d’utiliser des presets.
* Sinon, le script passe en mode interactif (questions plus bas).

---

## 3. Lecture interactive des variables manquantes

```bash
[ -z "${VM_NAME:-}" ] && read -p "Nom de la VM (ex: webvm) : " VM_NAME
[ -z "${PROJECT_NAME:-}" ] && read -p "Nom du projet (ex: projet-web) : " PROJECT_NAME

# --- WEB_ROOT_TYPE ---
if [ -z "${WEB_ROOT_TYPE:-}" ]; then
    echo "📌 Choix du répertoire web pour le projet '$PROJECT_NAME' :"
    echo "1) Projet direct → /var/www/html/$PROJECT_NAME"
    echo "2) Architecture MVC → /var/www/html/$PROJECT_NAME/public"
    # ...choix interactif...
fi
```

* Chaque `read` n'intervient que si la variable n'est pas déjà définie (`${VAR:-}` évite l'erreur quand la variable n'existe pas).
* Variables principales : `VM_NAME`, `PROJECT_NAME`, `WEB_ROOT_TYPE`, `GIT_USER_NAME`, `GIT_USER_EMAIL`, `GITLAB_REPO`, `GITHUB_REPO`, `DB_USER`, `DB_PASS`.

### **Nouveauté : Architecture Web**

Le script propose maintenant le choix entre deux architectures :

* **Architecture directe** (`WEB_ROOT_TYPE="direct"`) : Le serveur web pointe vers `/var/www/html/PROJECT_NAME`
* **Architecture MVC** (`WEB_ROOT_TYPE="public"`) : Le serveur web pointe vers `/var/www/html/PROJECT_NAME/public`

Cette fonctionnalité est essentielle pour les frameworks modernes (Laravel, Symfony, CodeIgniter, etc.) qui utilisent un dossier `public` comme point d'entrée web.

---

## 4. Valeurs par défaut

```bash
CPUS=${CPUS:-2}
MEM=${MEM:-"4G"}
DISK=${DISK:-"15G"}
DB_NAME=${DB_NAME:-"${PROJECT_NAME}_db"}
PHPMYADMIN_PASS=${PHPMYADMIN_PASS:-"phpmyadmin"}
```

* Si une variable n’est pas définie, on utilise ces valeurs par défaut.
* Tu peux surcharger en exportant les variables avant d’exécuter le script ou via un `.conf`.

---

## 5. Vérification qu’une VM du même nom n’existe pas

```bash
if multipass list | grep -qw "$VM_NAME"; then
    echo "⚠️ La VM $VM_NAME existe déjà..."
    exit 1
fi
```

* Empêche d’écraser une VM existante portant le même nom.

---

## 6. Création de la VM

```bash
multipass launch -n "$VM_NAME" --cpus $CPUS --memory $MEM --disk $DISK "24.04"
```

* Lance une VM Ubuntu 24.04 avec les ressources indiquées.
* Multipass télécharge l’image si nécessaire.

---

## 7. Configuration SSH automatique (hôte ↔ VM)

Ce bloc assure que la machine hôte pourra se connecter sans prompt (gestion `known_hosts`, permissions, etc.) :

```bash
USER_HOME=${SUDO_USER:+/home/$SUDO_USER}
USER_HOME=${USER_HOME:-$HOME}
SSH_DIR="$USER_HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"
SSH_KNOWN="$SSH_DIR/known_hosts"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
touch "$SSH_CONFIG" "$SSH_KNOWN"
chmod 600 "$SSH_CONFIG" "$SSH_KNOWN"

IP=$(multipass info "$VM_NAME" | grep IPv4 | awk '{print $2}')

ssh-keygen -R "$IP" -f "$SSH_KNOWN" 2>/dev/null || true

until nc -z -w5 "$IP" 22 >/dev/null 2>&1; do
    sleep 2
done

KEYSCAN=$(ssh-keyscan -H "$IP" 2>/dev/null)
if ! grep -q "$IP" "$SSH_KNOWN"; then
    echo "$KEYSCAN" >> "$SSH_KNOWN"
fi
chmod 600 "$SSH_KNOWN"
```

### Détails et explications

* **`USER_HOME`** : si le script est lancé avec `sudo`, `SUDO_USER` pointe vers l’utilisateur qui a lancé `sudo`. On écrit donc dans `/home/$SUDO_USER/.ssh` au lieu de `/root/.ssh`. Si pas `sudo`, on utilise `$HOME`.
* **Perms** : `chmod 700 ~/.ssh` et `chmod 600` sur `config` et `known_hosts` — SSH est strict sur ça.
* **`multipass info`** : récupère l’IP de la VM.
* **`ssh-keygen -R "$IP"`** : supprime l’ancienne entrée pour l’IP (utile si tu recrées la VM — evite *HOST IDENTIFICATION HAS CHANGED*).
* **Attente que SSH soit opérationnel** : `until nc -z -w5 "$IP" 22` teste le port 22 (nécessite netcat).
* **`ssh-keyscan -H`** : récupère la clé publique du serveur. `-H` permet d’ajouter la clé en mode hashé.
* Ajout dans `known_hosts` si l’IP n’existe pas déjà (évite doublons).

### Pièges courants

* Si `nc` n’est pas installé, la boucle ne fonctionnera pas. Alternative : tester avec `ssh -o ConnectTimeout=2` en mode essai.
* Si tu lances le script via `sudo` mais que `SUDO_USER` n’existe pas, tu peux écrire dans `/root/.ssh` par erreur (et VS Code ne lira pas ce fichier pour ton user).
* Si malgré tout tu as encore le prompt, vérifie les permissions et que le `known_hosts` utilisé est bien celui de ton utilisateur.

---

## 8. Mise à jour de `~/.ssh/config` (pour VS Code Remote-SSH)

```bash
if grep -q "Host $VM_NAME" "$SSH_CONFIG"; then
    sed -i "/Host $VM_NAME/,/ForwardAgent/ s/HostName .*/HostName $IP/" "$SSH_CONFIG"
else
    cat <<EOL >> "$SSH_CONFIG"

Host $VM_NAME
    HostName $IP
    User ubuntu
    IdentityFile $SSH_DIR/id_ed25519
    ForwardAgent yes
EOL
fi
```

* Si un `Host $VM_NAME` existe, on **remplace seulement la ligne `HostName`** (donc mise à jour de l’IP).
* Sinon, on ajoute un nouveau bloc `Host`.
* `IdentityFile` pointe vers la clé locale qui sera utilisée par VS Code Remote.

---

## 9. Ajout de la clé SSH locale dans la VM (autoriser l’accès)

```bash
SSH_KEY="$SSH_DIR/id_ed25519.pub"
if [ ! -f "$SSH_DIR/id_ed25519" ]; then
    ssh-keygen -t ed25519 -f "$SSH_DIR/id_ed25519" -N ""
fi
PUB=$(cat "$SSH_KEY")

multipass exec "$VM_NAME" -- bash -c "
mkdir -p /home/ubuntu/.ssh
grep -qxF '$PUB' /home/ubuntu/.ssh/authorized_keys || echo '$PUB' >> /home/ubuntu/.ssh/authorized_keys
chmod 700 /home/ubuntu/.ssh
chmod 600 /home/ubuntu/.ssh/authorized_keys
chown -R ubuntu:ubuntu /home/ubuntu/.ssh
"
```

* Génère une clé `ed25519` locale si absente.
* Récupère la publique et l’ajoute dans `/home/ubuntu/.ssh/authorized_keys` de la VM via `multipass exec`.
* `grep -qxF` évite les doublons.
* Règle permissions et propriétaire (`ubuntu`) pour que SSH accepte.

---

## 10. Installation LAMP + outils

```bash
multipass exec "$VM_NAME" -- sudo bash -c "
export DEBIAN_FRONTEND=noninteractive
apt update -y
apt install -y apache2 mariadb-server php libapache2-mod-php php-mysql php-cli php-curl php-zip php-mbstring git curl unzip nano
systemctl enable --now apache2
"
```

* Installe Apache, MariaDB, PHP et paquets utiles.
* `DEBIAN_FRONTEND=noninteractive` évite les prompts d’installation.
* Active et démarre Apache.

---

## 11. Création de la base MySQL et création utilisateur

```bash
multipass exec "$VM_NAME" -- sudo bash -c "
mysql -e \"CREATE DATABASE IF NOT EXISTS \\\`$DB_NAME\\\`;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON \\\`$DB_NAME\\\`.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;\"
"
```

* Lance plusieurs commandes SQL via `mysql -e`.
* Les backticks et échappements sont nécessaires parce que le tout est passé dans une string évaluée par `bash -c`.
* **Sécurité** : attention aux mots de passe en clair dans le script.

---

## 12. Installation non interactive de phpMyAdmin

* Le script préremplit `debconf` avec `debconf-set-selections` pour éviter les prompts pendant l’`apt install -y phpmyadmin`.
* Recharge Apache ensuite (`systemctl reload apache2`).

---

## 13. Création du dossier projet et architecture web

```bash
multipass exec "$VM_NAME" -- sudo bash -c "
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

# Créer un fichier index.php de test dans le bon répertoire
cat > $WEB_ROOT_PATH/index.php <<EOL_INDEX
<?php
echo '<h1>✅ Projet $PROJECT_NAME</h1>';
echo '<p>Architecture: ' . ('$WEB_ROOT_TYPE' === 'public' ? 'MVC (dossier public)' : 'Directe') . '</p>';
echo '<p>Répertoire: $WEB_ROOT_PATH</p>';
echo '<p>PHP Version: ' . phpversion() . '</p>';
// ... autres infos ...
?>
EOL_INDEX
"
```

### **Fonctionnalités d'architecture**

* **Dossier projet principal** : Toujours créé dans `/var/www/html/$PROJECT_NAME`
* **Dossier public** : Créé automatiquement si `WEB_ROOT_TYPE="public"`
* **Fichier de test** : Un `index.php` est généré dans le bon répertoire selon l'architecture choisie
* **Permissions** : Configureés correctement pour `ubuntu:www-data` avec droits `775`

---

## 14. Configuration Git dans la VM

```bash
multipass exec "$VM_NAME" -- git config --global user.name "$GIT_USER_NAME"
multipass exec "$VM_NAME" -- git config --global user.email "$GIT_USER_EMAIL"
```

* Définit l’identité Git globale dans la VM pour pouvoir commit/pusher si nécessaire.

---

## 15. Clé SSH dans la VM (pour Git) — génération et affichage

```bash
multipass exec "$VM_NAME" -- bash -c '
if [ ! -f ~/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519 <<< y >/dev/null 2>&1
fi
'
multipass exec "$VM_NAME" -- cat /home/ubuntu/.ssh/id_ed25519.pub
read -p "⏸️ Ajoute la clé ci-dessus dans GitLab/GitHub, puis appuie sur Entrée pour continuer..."
```

* Génère une clé à l’intérieur de la VM si absente.
* Affiche la clé publique pour que tu la copies dans GitLab/GitHub.
* Le `read` marque une pause pour que tu ajoutes la clé côté serveur (sinon `git clone` SSH échouera).

---

## 16. Clonage des repos (si fournis)

```bash
if [ -n "${GITLAB_REPO:-}" ]; then
    multipass exec "$VM_NAME" -- bash -c "
cd /var/www/html/$PROJECT_NAME
[ ! -d .git ] && git clone $GITLAB_REPO . || echo 'GitLab déjà cloné'
"
fi
# idem pour GITHUB_REPO
```

* Clone si un repo est fourni et si le dossier n’a pas déjà un `.git`.
* Si la clé VM n’est pas ajoutée côté GitLab/GitHub, le clone échouera — d’où la pause précédente.

---

## 17. VirtualHost Apache (optionnel) avec support architecture

```bash
if [ -n "${VHOST_DOMAIN:-}" ]; then
    multipass exec "$VM_NAME" -- sudo bash -c "
VHOST_FILE='/etc/apache2/sites-available/$VHOST_DOMAIN.conf'
if [ -f \$VHOST_FILE ]; then
    sed -i 's/^\\s*ServerName .*/ServerName $VHOST_DOMAIN/' \$VHOST_FILE
else
cat > \$VHOST_FILE <<EOL
<VirtualHost *:80>
    ServerName $VHOST_DOMAIN
    DocumentRoot $WEB_ROOT_PATH

    <Directory $WEB_ROOT_PATH>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/$VHOST_DOMAIN-error.log
    CustomLog \${APACHE_LOG_DIR}/$VHOST_DOMAIN-access.log combined
</VirtualHost>
EOL
    a2ensite $VHOST_DOMAIN.conf
fi
systemctl reload apache2
"
fi
```

### **Améliorations VirtualHost**

* **DocumentRoot dynamique** : Utilise `$WEB_ROOT_PATH` qui pointe vers le bon répertoire selon l'architecture
* **Configuration Directory** : Inclut les directives nécessaires pour les frameworks modernes
* **Logs séparés** : Chaque virtual host a ses propres logs d'erreur et d'accès
* **Support .htaccess** : `AllowOverride All` pour les URL rewriting des frameworks

---

## 18. Affichage final avec informations d'architecture

Affiche les infos utiles selon l'architecture choisie :

```bash
echo "✅ VM prête !"
echo "➡️ Connexion SSH : ssh ubuntu@$IP"
echo "➡️ Projet dispo dans : /var/www/html/$PROJECT_NAME"
echo "➡️ Répertoire web : $WEB_ROOT_PATH"
echo "➡️ phpMyAdmin dispo : http://$IP/phpmyadmin"
echo "➡️ MySQL user : $DB_USER / $DB_PASS (DB : $DB_NAME)"
[ -n "${VHOST_DOMAIN:-}" ] && echo "➡️ Virtual Host : http://$VHOST_DOMAIN"
```

### **Informations d'architecture**

* **Projet** : Emplacement du code source (`/var/www/html/$PROJECT_NAME`)
* **Répertoire web** : Point d'entrée web effectif (peut être différent selon l'architecture)
* **URL d'accès** : Virtual host si configuré, sinon IP directe
* **Test automatique** : Un fichier `index.php` affiche les détails de l'architecture

---

## Dépannage & vérifications rapides

Si tu rencontres des problèmes :

* **IP VM** : `multipass info $VM_NAME | grep IPv4`
* **SSH verbose** : `ssh -vvv ubuntu@$IP` pour voir pourquoi SSH demande un fingerprint.
* **Vérifier known\_hosts** : `ssh-keygen -F $IP` / `ssh-keygen -R $IP`
* **Permissions** : `ls -ld ~/.ssh` (doit être `700`), `ls -l ~/.ssh/known_hosts` (`600`)
* **SSH sur la VM** : `multipass exec $VM_NAME -- systemctl status ssh` (ou `sshd`).
* **Logs Apache/MySQL** : `multipass exec $VM_NAME -- sudo journalctl -u apache2 -n 200`.
* **git clone** : si échec, vérifier que la clé publique de la VM est bien ajoutée à GitLab/GitHub.

---

## Résumé rapide

* Le script automatise création et configuration d’une VM Multipass + stack LAMP + gestion SSH et Git.
* Les points les plus sensibles sont la gestion de `~/.ssh` (permissions, known\_hosts, SUDO\_USER) et la nécessité d’ajouter la clé publique de la VM sur GitLab/GitHub pour que `git clone` en SSH fonctionne.
* Pour éviter le prompt du fingerprint : s’assurer d’écrire dans le bon `known_hosts`, supprimer l’ancienne clé (`ssh-keygen -R ip`) et attendre que SSH soit disponible avant `ssh-keyscan`.

---
