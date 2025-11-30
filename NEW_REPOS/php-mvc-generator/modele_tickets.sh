#!/bin/bash
# shellcheck source=./config.sh
source ./config.sh

ISSUE_PATH="$PROJECT_PATH/.gitlab/issue_templates"
echo "Création des templates de tickets GitLab..."

# -------------------------------
#Feature
# -------------------------------
cat > "$ISSUE_PATH"/feature.md << EOF 
Titre: [FEATURE] Nom de la fonctionnalité

**Description :**
Décrire la fonctionnalité à développer et son objectif.

**Critères d'acceptation :**
- [ ] Critère 1
- [ ] Critère 2
- [ ] Tests unitaires ajoutés
- [ ] Documentation mise à jour

**Notes techniques :**
- Technologies utilisées
- Points d'attention particuliers

**Définition of Done :**
- [ ] Code développé et testé
- [ ] Revue de code effectuée
- [ ] Documentation à jour
- [ ] Déployé sur environnement de test
EOF

# -------------------------------
#Documention
# -------------------------------
cat > "$ISSUE_PATH"/documentation.md << EOF 
Titre: [DOC] Nom du document à créer/modifier

**Objectif :**
Expliquer le but de cette documentation.

**Contenu à couvrir :**
- [ ] Section 1
- [ ] Section 2
- [ ] Exemples pratiques
- [ ] Schémas/diagrammes si nécessaire

**Public cible :**
Préciser qui utilisera cette documentation.

**Livrables :**
- [ ] Document markdown finalisé
- [ ] Relecture effectuée
- [ ] Intégré dans l'arborescence docs/
EOF

# -------------------------------
#Configuration/environnement
# -------------------------------
cat > "$ISSUE_PATH"/configuration.md << EOF
Titre: [SETUP] Nom de la configuration

**Objectif :**
Décrire la configuration à mettre en place.

**Tâches :**
- [ ] Installation des outils
- [ ] Configuration des paramètres
- [ ] Test de fonctionnement
- [ ] Documentation des procédures

**Prérequis :**
- Outils nécessaires
- Permissions requises

**Validation :**
- [ ] Environnement fonctionnel
- [ ] Procédure reproductible documentée
EOF

# -------------------------------
# Autoformation
# -------------------------------
cat > "$ISSUE_PATH"/autoformation.md << EOF
Titre: [LEARN] Sujet d'apprentissage

**Objectif d'apprentissage :**
Décrire les compétences à acquérir.

**Ressources prévues :**
- [ ] Documentation officielle
- [ ] Tutoriels en ligne
- [ ] Cours/vidéos
- [ ] Expérimentation pratique

**Livrables :**
- [ ] Notes de synthèse dans docs/autoformation/
- [ ] Prototype/test si applicable
- [ ] Application dans le projet

**Critères de réussite :**
- [ ] Concepts compris
- [ ] Application pratique réussie
- [ ] Capacité à expliquer à un tiers
EOF

# -------------------------------
#Bug
# -------------------------------
cat > "$ISSUE_PATH"/bug.md << EOF
Titre: [BUG] Description courte du problème

**Description du problème :**
Décrire précisément le comportement incorrect.

**Étapes pour reproduire :**
1. Action 1
2. Action 2
3. Résultat inattendu

**Comportement attendu :**
Décrire ce qui devrait se passer normalement.

**Environnement :**
- Version du projet
- Configuration système
- Navigateur/OS si pertinent

**Solution proposée :**
Si une idée de solution existe.
EOF

# -------------------------------
#Design
# -------------------------------
cat > "$ISSUE_PATH"/design.md << EOF
Titre : [DESIGN] Titre convenable

**Objectif :**
Décrire les éléments visuels/UX à concevoir pour l'application Loisirs & Co.

**Type de travail :**
- [ ] Wireframes (structure/zoning)
- [ ] Maquettes haute fidélité
- [ ] Charte graphique
- [ ] Système de couleurs
- [ ] Typographie
- [ ] Iconographie
- [ ] Responsive design
- [ ] Logique de navigation

**Écrans/composants concernés :**
- [ ] Page d'accueil
- [ ] Gestion adhérents
- [ ] Gestion activités
- [ ] Planning séances
- [ ] Saisie participations
- [ ] Tableaux de bord/statistiques

**Livrables attendus :**
- [ ] Fichiers de maquettes (Figma/Sketch/Adobe XD ou images)
- [ ] Guide de style (couleurs, fonts, espacements)
- [ ] Spécifications responsive
- [ ] Interactions et micro-animations
- [ ] Documentation navigation

**Contraintes techniques :**
- Compatible navigateurs modernes
- Responsive mobile/tablette/desktop
- Accessibilité WCAG (contraste, lisibilité)
- Performance (images optimisées)

**Validation :**
- [ ] Navigation intuitive et logique
- [ ] Accessibilité respectée
- [ ] Responsive validé sur différents écrans

**Outils utilisés :**
Figma
EOF