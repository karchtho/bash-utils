# Guide d'Installation LAMP

Guide complet pour installer et configurer une stack LAMP (Linux, Apache2, MariaDB/MySQL, PHP-FPM) sur un serveur Ubuntu frais en utilisant l'installateur automatisé.

---

## Démarrage Rapide

```bash
# Sur un serveur Ubuntu frais
cd ~/projects/scripts-bash

# Installer LAMP Stack avec environnement développement
./bin/vm setup lamp development

# Ou avec environnement de test
./bin/vm setup lamp test

# Ou avec environnement production
./bin/vm setup lamp production
```

---

## Prérequis

### Configuration Système
- **OS**: Ubuntu 18.04 LTS ou plus récent
- **RAM**: Minimum 2GB (4GB+ recommandé)
- **Stockage**: Minimum 10GB d'espace libre
- **Processeur**: 2 cores minimum

### Prérequis d'Installation
- Accès `sudo` ou `root` (obligatoire pour installer les packages)
- Connexion internet (pour télécharger les packages)
- Bash 4.0+

### Configuration Réseau (pour VM VirtualBox)
- Adaptateur réseau configuré (Bridged ou NAT)
- Port 80 (Apache HTTP) accessible
- Port 443 (Apache HTTPS) accessible
- Port 3306 (MySQL) accessible depuis localhost

---

## Étapes d'Installation

### 1. Préparer le Serveur Ubuntu

```bash
# Mettre à jour les packages système
sudo apt-get update
sudo apt-get upgrade -y

# Installer git si absent
sudo apt-get install -y git

# Cloner le dépôt scripts-bash
cd ~/projects
git clone https://github.com/YOUR_USERNAME/scripts-bash.git
cd scripts-bash
```

### 2. Choisir l'Environnement

Sélectionnez l'environnement adapté à votre cas d'usage :

#### Environnement Développement
```bash
./bin/vm setup lamp development
```

**Configuration** :
- Erreurs PHP: Affichées dans le navigateur
- Mémoire PHP: 512MB
- Temps d'exécution max: 300 secondes
- Logging MySQL: Activé
- Xdebug: Activé (pour debugging)
- Apache: Token serveur visible, logging info-level

**Utiliser pour**: Développement local, debugging, apprentissage

#### Environnement Test
```bash
./bin/vm setup lamp test
```

**Configuration** :
- Erreurs PHP: Loggées mais non affichées
- Mémoire PHP: 256MB
- Temps d'exécution max: 60 secondes
- MySQL: Logging désactivé, optimisé pour tests
- Apache: Information minimale, logging warning-level
- Opcache: Activé

**Utiliser pour**: Tests automatisés, pipelines CI/CD, staging

#### Environnement Production
```bash
./bin/vm setup lamp production
```

**Configuration** :
- Erreurs PHP: Seulement erreurs critiques loggées
- Mémoire PHP: 128MB
- Temps d'exécution max: 30 secondes
- MySQL: Paramètres optimisés pour performance
- Apache: Headers de sécurité, information minimale, logging critique
- Opcache: Activé avec long revalidation
- Headers de sécurité: Frame options, content-type options, protection XSS

**Utiliser pour**: Serveurs en production, applications publiques

### 3. Lancer l'Installation

Exécutez la commande setup avec votre environnement choisi :

```bash
# Développement (plus courant pour VMs locales)
sudo ./bin/vm setup lamp development

# Test
sudo ./bin/vm setup lamp test

# Production
sudo ./bin/vm setup lamp production
```

L'installateur va :
1. Mettre à jour les listes de packages
2. Installer Apache2 avec les modules requis
3. Installer le serveur MariaDB/MySQL
4. Installer PHP-FPM et les extensions requises
5. Configurer les paramètres spécifiques à l'environnement
6. Installer et configurer phpMyAdmin
7. Créer l'utilisateur de base de données (superadmin/superpass)
8. Redémarrer tous les services
9. Afficher un résumé d'installation

---

## Accès et Sortie d'Installation

### Résumé à la Fin de l'Installation

Vous verrez un résumé comme ceci :

```
╔═══════════════════════════════════════════════════════════╗
║       Installation stack LAMP terminée                    ║
╚═══════════════════════════════════════════════════════════╝

État des Services:
  Apache2:  active
  MySQL:    active
  PHP-FPM:  active
  PHP:      PHP 8.1.2 (cli) (built: Feb 1 2022 06:48:52)

Accès Base de Données:
  Utilisateur: superadmin
  Mot de passe: superpass

phpMyAdmin:
  URL:      http://localhost/phpmyadmin
  User:     superadmin
  Password: superpass
```

### Accéder à phpMyAdmin

1. Ouvrir le navigateur et aller à: `http://localhost/phpmyadmin`
2. Se connecter avec:
   - **Utilisateur**: `superadmin`
   - **Mot de passe**: `superpass`
3. Créer des bases de données et gérer les tables

### Connexion à MySQL/MariaDB

```bash
# Depuis la ligne de commande
mysql -u superadmin -p
# Quand demandé, entrez le mot de passe: superpass

# Créer une base de données de test
CREATE DATABASE myapp_dev;
CREATE TABLE myapp_dev.users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100),
  email VARCHAR(100)
);
```

---

## Détails de Configuration PHP

### Environnement Développement

Fichier: `/etc/php/*/mods-available/development-settings.ini`

```ini
error_reporting = E_ALL
display_errors = On
display_startup_errors = On
log_errors = On
error_log = /var/log/php_errors.log
memory_limit = 512M
max_execution_time = 300
max_input_time = 300
post_max_size = 64M
upload_max_filesize = 64M
opcache.enable = 0
opcache.enable_cli = 0
```

**Pourquoi**: Visibilité complète des erreurs pour debugging. Support Xdebug pour step debugging.

### Environnement Test

Fichier: `/etc/php/*/mods-available/test-settings.ini`

```ini
error_reporting = E_ALL
display_errors = Off
log_errors = On
error_log = /var/log/php_errors.log
memory_limit = 256M
max_execution_time = 60
post_max_size = 32M
upload_max_filesize = 32M
opcache.enable = 1
opcache.enable_cli = 1
```

**Pourquoi**: Erreurs loggées pour inspection mais non affichées aux utilisateurs. Opcache pour performance.

### Environnement Production

Fichier: `/etc/php/*/mods-available/production-settings.ini`

```ini
error_reporting = E_CRITICAL | E_ERROR
display_errors = Off
display_startup_errors = Off
log_errors = On
error_log = /var/log/php_errors.log
memory_limit = 128M
max_execution_time = 30
post_max_size = 16M
upload_max_filesize = 16M
opcache.enable = 1
opcache.enable_cli = 0
opcache.revalidate_freq = 3600
```

**Pourquoi**: Affichage erreurs minimal pour sécurité. Caching agressif pour performance. Limites de ressources basses.

---

## Configuration Apache

### Environnement Développement

Fichier: `/etc/apache2/conf-available/development.conf`

```apache
ServerTokens Full
ServerSignature On
LogLevel info
<FilesMatch \.php$>
    SetHandler "proxy:unix:/run/php/php-fpm.sock|fcgi://localhost"
</FilesMatch>
```

**Ce qu'il fait**:
- Révèle la version complète du serveur et les modules
- Affiche la signature Apache (pour apprentissage)
- Logue toutes les connexions (niveau info)

### Environnement Production

Fichier: `/etc/apache2/conf-available/production.conf`

```apache
ServerTokens Prod
ServerSignature Off
LogLevel crit
TraceEnable Off
Header always append X-Frame-Options SAMEORIGIN
Header always set X-Content-Type-Options "nosniff"
Header always set X-XSS-Protection "1; mode=block"
<FilesMatch \.php$>
    SetHandler "proxy:unix:/run/php/php-fpm.sock|fcgi://localhost"
</FilesMatch>
```

**Headers de sécurité**:
- `X-Frame-Options`: Empêche le clickjacking
- `X-Content-Type-Options`: Empêche le MIME-sniffing
- `X-XSS-Protection`: Filtrage XSS navigateur

---

## Configuration MySQL/MariaDB

### Environnement Développement

Ajouté à `/etc/mysql/mariadb.conf.d/50-server.cnf`:

```ini
# Paramètres environnement développement
general_log = 1
general_log_file = /var/log/mysql/query.log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 1
log_queries_not_using_indexes = 1
```

**Objectif**: Logger TOUTES les requêtes pour analyser performance et comportement.

### Environnement Production

```ini
# Paramètres environnement production
general_log = 0
slow_query_log = 0
skip-name-resolve = 1
max_connections = 100
max_allowed_packet = 64M
innodb_buffer_pool_size = 1G
query_cache_type = 1
query_cache_size = 16M
```

**Optimisations**:
- Logging requêtes désactivé (impact performance)
- Skip résolution DNS (vitesse)
- Limites de connexions plus hautes
- Larger buffer pool pour caching
- Query caching activé

---

## Vérification et Test

### Vérifier l'Installation

```bash
# Vérifier Apache
sudo systemctl status apache2

# Vérifier MySQL
sudo systemctl status mysql

# Vérifier PHP-FPM
sudo systemctl status php*-fpm

# Vérifier les modules Apache
apache2ctl -M | grep php

# Vérifier PHP version et modules
php -v
php -m
php -i | grep php.ini
```

### Tester le Traitement PHP

Créer un fichier PHP de test:

```bash
sudo tee /var/www/html/test.php > /dev/null << 'EOF'
<?php
echo "PHP fonctionne!<br>";
echo "Version PHP: " . phpversion() . "<br>";

// Test connexion base de données
$mysqli = new mysqli("localhost", "superadmin", "superpass");
if ($mysqli->connect_error) {
    echo "Connexion base de données échouée: " . $mysqli->connect_error;
} else {
    echo "Connexion base de données réussie<br>";
    $result = $mysqli->query("SELECT VERSION()");
    $row = $result->fetch_row();
    echo "Version MySQL: " . $row[0];
}
?>
EOF
```

Visiter: `http://localhost/test.php`

### Tester la Connexion Base de Données

```bash
# Se connecter et exécuter une requête
mysql -u superadmin -psuperpass << EOF
SELECT "Test Connexion MySQL" as Status;
SHOW DATABASES;
EXIT;
EOF
```

### Tester phpMyAdmin

1. Visiter: `http://localhost/phpmyadmin`
2. Se connecter avec `superadmin` / `superpass`
3. Vérifier que vous voyez la liste des bases de données

---

## Emplacements et Fichiers Logs

### Répertoires Importants

```
/var/www/html/                     # Racine web (Apache par défaut)
/etc/apache2/                      # Configuration Apache
/etc/php/*/mods-available/         # Configuration modules PHP
/etc/mysql/                        # Configuration MySQL
/var/log/mysql/                    # Logs MySQL (environnement dev uniquement)
/var/log/php_errors.log            # Log erreurs PHP
/var/log/apache2/                  # Logs accès et erreurs Apache
/usr/share/phpmyadmin/             # Installation phpMyAdmin
```

### Fichiers Logs à Monitorer

```bash
# Erreurs PHP
tail -f /var/log/php_errors.log

# Accès Apache
tail -f /var/log/apache2/access.log

# Erreurs Apache
tail -f /var/log/apache2/error.log

# Erreurs MySQL (si dev)
tail -f /var/log/mysql/error.log

# Log requêtes MySQL (dev uniquement)
tail -f /var/log/mysql/query.log
```

---

## Tâches Courantes

### Créer une Base de Données et Utilisateur

```bash
mysql -u superadmin -psuperpass << EOF
CREATE DATABASE myproject_db;
CREATE USER 'myproject'@'localhost' IDENTIFIED BY 'mypassword';
GRANT ALL PRIVILEGES ON myproject_db.* TO 'myproject'@'localhost';
FLUSH PRIVILEGES;
EOF
```

### Changer d'Environnement

Si vous avez besoin de passer du développement à la production:

```bash
# Reconfigurer pour la production
sudo ./bin/vm setup lamp production

# Cela re-exécutera les fonctions de configuration spécifiques à l'environnement
```

### Activer HTTPS/SSL

```bash
# Générer un certificat auto-signé
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/apache-selfsigned.key \
  -out /etc/ssl/certs/apache-selfsigned.crt

# Activer la configuration SSL
sudo a2ensite default-ssl
sudo systemctl reload apache2
```

---

## Credentials Base de Données

### Credentials par Défaut

Ces credentials sont définis lors de l'installation et ne peuvent pas être changés via l'installateur (ils sont codés en dur pour développement):

- **Utilisateur**: `superadmin`
- **Mot de passe**: `superpass`
- **Accès phpMyAdmin**: Mêmes credentials (superadmin/superpass)
- **Hôte**: `localhost`
- **Port**: `3306` (port MySQL par défaut)

---

## Dépannage

### Apache ne démarre pas

```bash
# Vérifier la syntaxe
sudo apache2ctl configtest

# Vérifier les erreurs
sudo journalctl -u apache2 -n 50

# Vérifier si le port 80 est utilisé
sudo netstat -tlnp | grep :80
```

### Problèmes socket PHP-FPM

```bash
# Vérifier si le socket existe
ls -la /run/php/php-fpm.sock

# Vérifier le statut PHP-FPM
sudo systemctl status php*-fpm

# Redémarrer PHP-FPM
sudo systemctl restart php*-fpm
```

### MySQL ne se connecte pas

```bash
# Vérifier que MySQL tourne
sudo systemctl status mysql

# Tester la connexion
mysql -u superadmin -psuperpass -e "SELECT 1;"

# Vérifier les logs MySQL
sudo tail -50 /var/log/mysql/error.log
```

---

**Dernière mise à jour**: 2025-11-25
**Version**: 1.0.0
