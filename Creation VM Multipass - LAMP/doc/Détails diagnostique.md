# Guide détaillé — Script de diagnostic

Ce document explique en détail le fonctionnement du script `diagnostique.sh` qui permet de diagnostiquer et dépanner les environnements de développement VM.

## 🚀 Utilisation

```bash
# Diagnostic général
./diagnostique.sh

# Diagnostic VM spécifique
./diagnostique.sh webvm

# Diagnostic avec projet
./diagnostique.sh webvm projet1

# Diagnostic complet avec virtual host
./diagnostique.sh webvm projet1 projet1.local
```

## 🔍 Ce qu'il vérifie

### **Architecture web** 🏗️
- **Détection automatique** de l'architecture (directe vs MVC)
- **Vérification des dossiers** : projet principal et dossier `public` si MVC
- **Permissions** : `ubuntu:www-data` et droits `775`
- **Cohérence** : architecture détectée vs configuration Apache

### **Virtual Host Apache** 🌐
- Fichier de configuration existe et est correct
- Site activé dans Apache
- **DocumentRoot adaptatif** : pointe vers le bon répertoire selon l'architecture
- Virtual Host répond aux requêtes HTTP
- **Logs séparés** et configurations avancées

### **Configuration SSH** 🔐
- Entrée Host existe pour la VM dans `~/.ssh/config`
- IP correspond à la VM actuelle
- Clés SSH correctes et permissions
- Fichier config correctement formaté

### **Tests fonctionnels** ✅
- Serveur web répond (HTTP 200)
- **Répertoire projet accessible** selon l'architecture
- phpMyAdmin fonctionne
- **URL de test adaptée** : Virtual Host pour MVC, IP directe sinon
- Base de données accessible

## 💡 Features bonus

- **Couleurs** pour faciliter la lecture (vert=OK, jaune=warning, rouge=erreur)
- **Tests de connexion** automatiques avec timeout
- **Recommandations de correction** spécifiques à l'architecture détectée
- **Mode interactif** si pas d'arguments
- **Informations d'architecture** dans le résumé final
- **Suggestions contextuelles** pour réparer permissions selon l'architecture

## 🎯 Exemples de sortie

### Architecture MVC détectée
```
✅ Architecture MVC détectée (dossier public)
✅ Permissions projet OK: 775 (ubuntu:www-data)
✅ Permissions répertoire web OK: 775 (ubuntu:www-data)
✅ DocumentRoot pointe vers le bon répertoire (MVC)
✅ Projet accessible via Virtual Host (architecture MVC): http://projet.local/
```

### Architecture directe détectée
```
✅ Architecture directe détectée
✅ Permissions projet OK: 775 (ubuntu:www-data)
✅ DocumentRoot pointe vers le bon répertoire (direct)
✅ Projet accessible via IP directe: http://192.168.64.10/projet/
```

### Recommandations de correction
```bash
# Architecture MVC - Permissions dossier public :
multipass exec webvm -- sudo chown ubuntu:www-data /var/www/html/projet/public
multipass exec webvm -- sudo chmod 775 /var/www/html/projet/public
```

## 🛠️ Installation

```bash
chmod +x diagnostique.sh
```

Tu peux même l'ajouter à ton PATH pour l'utiliser de partout ! C'est un vrai **couteau suisse** pour débugger tes environnements de dev. 🔧