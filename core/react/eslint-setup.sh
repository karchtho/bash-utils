#!/bin/bash
# ESLint Setup for React Projects
# Configures ESLint with Airbnb style guide and React plugins

# Source required libraries
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi
source "$SCRIPT_DIR/core/lib/colors.sh"
source "$SCRIPT_DIR/core/lib/error-handler.sh"
source "$SCRIPT_DIR/core/lib/validation.sh"
source "$SCRIPT_DIR/core/lib/common.sh"

# Install ESLint and dependencies
install_eslint() {
    local project_dir=${1:-.}

    print_section "Installing ESLint and React dependencies"

    # Check if npm is available
    if ! command_exists npm; then
        print_error "npm not found. Please install Node.js first."
        return 1
    fi

    # Check if package.json exists
    if [[ ! -f "$project_dir/package.json" ]]; then
        print_error "package.json not found in $project_dir"
        return 1
    fi

    cd "$project_dir" || return 1

    # Install ESLint packages
    print_info "Installing ESLint core packages..."
    npm install --save-dev \
        eslint \
        eslint-config-airbnb \
        eslint-plugin-import \
        eslint-plugin-react \
        eslint-plugin-react-hooks \
        eslint-plugin-jsx-a11y \
        @babel/eslint-parser 2>/dev/null || {
        print_error "Failed to install ESLint packages"
        return 1
    }

    print_ok "ESLint packages installed"
    echo ""

    return 0
}

# Generate ESLint configuration file
generate_eslint_config() {
    local project_dir=${1:-.}
    local config_file="$project_dir/.eslintrc.json"

    print_section "Generating ESLint configuration"

    if [[ -f "$config_file" ]]; then
        print_warning ".eslintrc.json already exists, backing up..."
        mv "$config_file" "$config_file.backup.$(date +%s)"
    fi

    cat > "$config_file" << 'EOF'
{
  "env": {
    "browser": true,
    "es2021": true,
    "node": true,
    "jest": true
  },
  "extends": [
    "airbnb",
    "airbnb/hooks"
  ],
  "parser": "@babel/eslint-parser",
  "parserOptions": {
    "ecmaVersion": "latest",
    "sourceType": "module",
    "ecmaFeatures": {
      "jsx": true
    }
  },
  "plugins": [
    "react",
    "react-hooks",
    "import"
  ],
  "rules": {
    "react/react-in-jsx-scope": "off",
    "react/function-component-definition": [
      2,
      {
        "namedComponents": "arrow-function",
        "unnamedComponents": "arrow-function"
      }
    ],
    "react/jsx-filename-extension": [
      1,
      {
        "extensions": [
          ".js",
          ".jsx",
          ".ts",
          ".tsx"
        ]
      }
    ],
    "import/extensions": [
      "error",
      "ignorePackages",
      {
        "js": "never",
        "jsx": "never",
        "ts": "never",
        "tsx": "never"
      }
    ],
    "import/no-extraneous-dependencies": [
      "error",
      {
        "devDependencies": [
          "**/*.test.js",
          "**/*.test.jsx",
          "**/test/**",
          "**/tests/**",
          "test.js",
          "tests.js",
          "**/__tests__/**"
        ]
      }
    ],
    "max-len": [
      "warn",
      {
        "code": 100,
        "ignoreComments": true,
        "ignoreUrls": true
      }
    ],
    "no-unused-vars": [
      "warn",
      {
        "argsIgnorePattern": "^_"
      }
    ],
    "indent": [
      "error",
      2
    ]
  },
  "settings": {
    "react": {
      "version": "detect"
    }
  }
}
EOF

    print_ok "ESLint configuration created: $config_file"
    echo ""

    return 0
}

# Generate .eslintignore file
generate_eslint_ignore() {
    local project_dir=${1:-.}
    local ignore_file="$project_dir/.eslintignore"

    print_section "Generating .eslintignore"

    if [[ -f "$ignore_file" ]]; then
        print_info ".eslintignore already exists"
        return 0
    fi

    cat > "$ignore_file" << 'EOF'
# Dependencies
node_modules/
.npm
npm-debug.log*

# Build directories
dist/
build/
.next/
out/

# Testing
coverage/
.nyc_output/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# Environment
.env
.env.local
.env.*.local

# OS
.DS_Store
Thumbs.db

# Generated files
*.min.js
*.min.css
EOF

    print_ok ".eslintignore created: $ignore_file"
    echo ""

    return 0
}

# Add ESLint scripts to package.json
add_eslint_scripts() {
    local project_dir=${1:-.}
    local package_file="$project_dir/package.json"

    print_section "Adding ESLint scripts to package.json"

    if [[ ! -f "$package_file" ]]; then
        print_error "package.json not found"
        return 1
    fi

    # Use Node.js to update package.json
    if command_exists node; then
        node << 'NODESCRIPT'
const fs = require('fs');
const path = require('path');
const pkg = require('./package.json');

if (!pkg.scripts) {
  pkg.scripts = {};
}

pkg.scripts.lint = 'eslint src/ --ext .js,.jsx,.ts,.tsx';
pkg.scripts['lint:fix'] = 'eslint src/ --ext .js,.jsx,.ts,.tsx --fix';
pkg.scripts['lint:watch'] = 'eslint src/ --ext .js,.jsx,.ts,.tsx --watch';

fs.writeFileSync('./package.json', JSON.stringify(pkg, null, 2) + '\n');
console.log('ESLint scripts added');
NODESCRIPT

        print_ok "ESLint scripts added to package.json"
    else
        print_warning "Node.js not available, skipping script addition"
    fi

    echo ""

    return 0
}

# Run ESLint check
run_eslint_check() {
    local project_dir=${1:-.}

    print_section "Running ESLint check"

    if [[ ! -f "$project_dir/package.json" ]]; then
        print_error "package.json not found"
        return 1
    fi

    cd "$project_dir" || return 1

    if ! npm run lint 2>/dev/null; then
        print_warning "ESLint found issues (see above)"
        return 0
    fi

    print_ok "ESLint check passed"
    echo ""

    return 0
}

# Setup ESLint for project
setup_eslint() {
    local project_dir=${1:-.}

    print_section "Setting up ESLint for React project"
    echo ""

    # Install ESLint
    if ! install_eslint "$project_dir"; then
        print_error "ESLint installation failed"
        return 1
    fi

    # Generate configuration
    if ! generate_eslint_config "$project_dir"; then
        print_error "ESLint configuration failed"
        return 1
    fi

    # Generate ignore file
    if ! generate_eslint_ignore "$project_dir"; then
        print_warning "ESLint ignore file generation failed"
    fi

    # Add scripts
    if ! add_eslint_scripts "$project_dir"; then
        print_warning "Adding ESLint scripts failed"
    fi

    print_section "ESLint Setup Complete"
    echo ""
    echo "Available commands:"
    echo "  npm run lint      - Run ESLint check"
    echo "  npm run lint:fix  - Fix ESLint issues automatically"
    echo "  npm run lint:watch - Watch mode for ESLint"
    echo ""

    return 0
}

# Verify ESLint installation
verify_eslint() {
    local project_dir=${1:-.}

    print_section "Verifying ESLint Installation"

    local all_ok=true

    # Check ESLint executable
    if [[ -f "$project_dir/node_modules/.bin/eslint" ]]; then
        print_ok "ESLint executable found"
    else
        print_warning "ESLint executable not found"
        all_ok=false
    fi

    # Check config file
    if [[ -f "$project_dir/.eslintrc.json" ]]; then
        print_ok "ESLint configuration found"
    else
        print_warning "ESLint configuration not found"
        all_ok=false
    fi

    # Check ignore file
    if [[ -f "$project_dir/.eslintignore" ]]; then
        print_ok "ESLint ignore file found"
    else
        print_warning "ESLint ignore file not found"
        all_ok=false
    fi

    echo ""

    if $all_ok; then
        print_ok "ESLint is ready to use"
        return 0
    else
        print_warning "ESLint setup incomplete"
        return 1
    fi
}

# Export functions
export -f install_eslint
export -f generate_eslint_config
export -f generate_eslint_ignore
export -f add_eslint_scripts
export -f run_eslint_check
export -f setup_eslint
export -f verify_eslint
