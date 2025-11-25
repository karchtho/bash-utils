#!/bin/bash

# Script de création de composant React
# Usage: ./create-component.sh nom-du-composant

# Vérifier qu'un argument a été fourni
if [ $# -eq 0 ]; then
    echo "❌ Erreur: Vous devez fournir un nom de composant"
    echo "Usage: $0 nom-du-composant"
    exit 1
fi

# Récupérer le nom en minuscules avec tirets
FOLDER_NAME=$(echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')

# Convertir en PascalCase pour les noms de fichiers
# Exemple: mon-composant -> MonComposant
PASCAL_CASE=$(echo "$FOLDER_NAME" | sed -r 's/(^|-)([a-z])/\U\2/g')

# Trouver le dossier components (cherche dans src/components ou components)
if [ -d "src/components" ]; then
    COMPONENTS_DIR="src/components"
elif [ -d "components" ]; then
    COMPONENTS_DIR="components"
else
    echo "❌ Erreur: Dossier 'components' introuvable"
    echo "Assurez-vous d'être à la racine du projet React"
    exit 1
fi

# Chemin complet du nouveau composant
COMPONENT_PATH="$COMPONENTS_DIR/$FOLDER_NAME"

# Vérifier si le dossier existe déjà
if [ -d "$COMPONENT_PATH" ]; then
    echo "❌ Erreur: Le composant '$FOLDER_NAME' existe déjà"
    exit 1
fi

# Créer le dossier
mkdir -p "$COMPONENT_PATH"

# Créer le fichier JSX
cat > "$COMPONENT_PATH/$PASCAL_CASE.jsx" << EOF
import classes from './$PASCAL_CASE.module.css';

function $PASCAL_CASE() {
  return (
    <div className={classes.container}>
      <h2>$PASCAL_CASE</h2>
    </div>
  );
}

export default $PASCAL_CASE;
EOF

# Créer le fichier CSS Module
cat > "$COMPONENT_PATH/$PASCAL_CASE.module.css" << EOF
.container {
  /* Styles pour $PASCAL_CASE */
}
EOF

echo "✅ Composant créé avec succès!"
echo "📁 Emplacement: $COMPONENT_PATH"
echo "📄 Fichiers:"
echo "   - $PASCAL_CASE.jsx"
echo "   - $PASCAL_CASE.module.css"