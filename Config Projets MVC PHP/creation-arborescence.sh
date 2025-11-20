#!/bin/bash
# Script de création d'arborescence
# shellcheck source=./config.sh
source ./config.sh

if [ -d "$PROJECT_PATH" ]; then
    echo "❌ Le projet $PROJECT_NAME existe déjà dans $PROJECT_PATH !"
    exit 1
fi

echo "Création de l'arborescence pour $PROJECT_NAME dans $PROJECT_PATH"

mkdir "$PROJECT_PATH"

#Dossiers
mkdir -p "$PROJECT_PATH"/{app/{controllers,models,views/{home,user},core},public/assets/{css,js},uploads/{image,documents},storage/{logs,cache},config,docs/{projet,technique,utilisateur},tests,vendor,.gitlab/issue_templates,scripts}
#Fichiers
touch "$PROJECT_PATH"/{.gitignore,composer.json,package.json,README.md,LICENSE}
touch "$PROJECT_PATH"/app/controllers/{homecontroller.php,usercontroller.php}
touch "$PROJECT_PATH"/app/models/{user.php,product.php}
touch "$PROJECT_PATH"/app/views/home/index.php
touch "$PROJECT_PATH"/app/views/user/profile.php
touch "$PROJECT_PATH"/app/core/{router.php,database.php}
touch "$PROJECT_PATH"/public/{index.php,.htaccess}
touch "$PROJECT_PATH"/public/assets/css/style.css
touch "$PROJECT_PATH"/public/assets/js/main.js
touch "$PROJECT_PATH"/config/{config.php,database.php}
touch "$PROJECT_PATH"/docs/projet/planification.md
touch "$PROJECT_PATH"/docs/technique/{architecture.md,conventions.md,installations.md,api.md,diagrames.md,maintenance.md,déploiement.md}
touch "$PROJECT_PATH"/docs/utilisateur/{installation.md,manuelAdministrateur.md,manuelUtilisation.md}
touch "$PROJECT_PATH"/tests/userTest.php

echo "Ajout des templates dans les fichiers .md..."

# Fonction pour créer le template markdown
create_md_template() {
    local file_path="$1"
    local title="$2"
    local current_date
    current_date=$(date +%d/%m/%Y)

    cat > "$file_path" << EOF
---
title: $title
author: T. KARCHER
creator: Typora inc.
subject: Documentation
header:
footer: \${title} - \${author} - Page \${pageNo} / \${totalPages}
---
# $title

------

**Date de création** : $current_date - T. KARCHER
**Date de modification** : $current_date - T. KARCHER
**Sommaire :**

------

> [TOC]

<div style="page-break-after:always"></div>

## 1. Introduction

Contenu à définir.

## 2. Développement

Contenu à définir.
EOF
}

# Application du template aux fichiers de documentation
echo "  - Fichiers du projet..."
create_md_template "$PROJECT_PATH/docs/projet/planification.md" "Planification"
create_md_template "$PROJECT_PATH/README.md" "README"

echo "  - Fichiers techniques..."
create_md_template "$PROJECT_PATH/docs/technique/architecture.md" "Architecture"
create_md_template "$PROJECT_PATH/docs/technique/conventions.md" "Conventions"
create_md_template "$PROJECT_PATH/docs/technique/installations.md" "Installations"
create_md_template "$PROJECT_PATH/docs/technique/api.md" "API"
create_md_template "$PROJECT_PATH/docs/technique/diagrames.md" "Diagrammes"
create_md_template "$PROJECT_PATH/docs/technique/maintenance.md" "Maintenance"
create_md_template "$PROJECT_PATH/docs/technique/déploiement.md" "Déploiement"

echo "  - Fichiers utilisateur..."
create_md_template "$PROJECT_PATH/docs/utilisateur/installation.md" "Installation"
create_md_template "$PROJECT_PATH/docs/utilisateur/manuelAdministrateur.md" "Manuel Administrateur"
create_md_template "$PROJECT_PATH/docs/utilisateur/manuelUtilisation.md" "Manuel Utilisation"
