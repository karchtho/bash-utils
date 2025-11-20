# Script de création et connexion à VM multipass

## 1 - Création des fichiers executbales.

La première étape consiste en l'importation des fichiers dans le dossier de votre choix. 
Depuis ce dossier, il faudra les rendres executables en faisant 
```bash 
    chmod +x create_webvm.sh
    chmod +x connect_vm.sh
```

Puis éxecuter les fichier en faisant 
```bash
    ./create_webvm.sh
    ./connect_vm.sh #pour plus tard
```

## 2 - Création de la vm avec ./create_webvm.sh

### Fichier config

- Il est posisble d'utiliser un fichier de configuration (vide sur ce repo).
- S'il reste vide, les informations importantes seront demandées pendant l'éxecution.
- Si vous décidez de créer plusieurs fichiers de configuration, vous pourrez choisir celui que vous voulez utiliser.
- Vous pourrez choisir l'installation full interactive.

### Repo

- Si vous ne renseignez pas les informations pour github/gitlab il faudra les configurer plus tard.
- Si vous les avez renseignées et que vous souhaiter cloner un repo, il faudra mettre l'url ssh du repo, puis
ajouter la clef ssh (publique) affichée par le bash avant de continuer.

### Travail distant

- Si vous utilisez VSCode, vous pouvez choisir l'option qui modifiera un fichier config
(./ssh/config) pour y ajouter les bonnes infoes, si elles n'existent pas.
- Sinon, vous pourrez configurer un alias dans /etc/hosts.
- Sinon, pas de configuration

## 2 - Connexion à la VM avec ./connect_vm.

L'éxecution de ce fichier permet de :
- voir la liste des VM disponible
- lancer la VM choisie si elle ne l'est pas
- associer l'ip de la VM à un nom de votre choix
- copier l'url dans votre presse-papier, **<span style="color:red;font-weight:bold;">à condition d'installer xclip</span>**
- ouvrir un onglet dans le navigateur par défaut (ou chrome, je suis plus sûr)