#!/bin/bash
# React Component Generator
# Scaffolds functional React components with hooks and styling

# Source required libraries
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi
source "$SCRIPT_DIR/core/lib/colors.sh"
source "$SCRIPT_DIR/core/lib/error-handler.sh"
source "$SCRIPT_DIR/core/lib/validation.sh"
source "$SCRIPT_DIR/core/lib/common.sh"

# Generate functional component
generate_component() {
    local component_name=$1
    local components_dir=${2:-./src/components}

    print_section "Generating React Component"

    # Validate component name
    if [[ -z "$component_name" ]]; then
        print_error "Component name required"
        return 1
    fi

    if ! [[ "$component_name" =~ ^[A-Z][a-zA-Z0-9]*$ ]]; then
        print_error "Invalid component name (must start with uppercase)"
        return 1
    fi

    # Create component directory
    local component_path="$components_dir/$component_name"
    if [[ -d "$component_path" ]]; then
        print_error "Component directory already exists: $component_path"
        return 1
    fi

    mkdir -p "$component_path"

    print_info "Component: $component_name"
    print_info "Location: $component_path"
    echo ""

    # Generate component file
    cat > "$component_path/$component_name.jsx" << COMP_EOF
import React from 'react';
import PropTypes from 'prop-types';
import './$component_name.css';

/**
 * $component_name component
 * @param {Object} props - Component props
 * @returns {JSX.Element}
 */
const $component_name = ({ children, ...props }) => {
  return (
    <div className="$component_name" {...props}>
      <h2>$component_name</h2>
      {children}
    </div>
  );
};

$component_name.propTypes = {
  children: PropTypes.node,
};

$component_name.defaultProps = {
  children: null,
};

export default $component_name;
COMP_EOF

    print_ok "Component file created: $component_path/$component_name.jsx"

    # Generate CSS file
    cat > "$component_path/$component_name.css" << CSS_EOF
.$component_name {
  /* Add your styles here */
}

.$component_name h2 {
  margin: 0;
  font-size: 1.5rem;
}
CSS_EOF

    print_ok "CSS file created: $component_path/$component_name.css"

    # Generate test file
    cat > "$component_path/$component_name.test.jsx" << TEST_EOF
import React from 'react';
import { render, screen } from '@testing-library/react';
import $component_name from './$component_name';

describe('$component_name', () => {
  it('renders without crashing', () => {
    render(<$component_name />);
    expect(screen.getByRole('heading')).toBeInTheDocument();
  });

  it('renders children', () => {
    const testText = 'Test content';
    render(<$component_name>{testText}</$component_name>);
    expect(screen.getByText(testText)).toBeInTheDocument();
  });
});
TEST_EOF

    print_ok "Test file created: $component_path/$component_name.test.jsx"

    # Generate index file
    cat > "$component_path/index.js" << INDEX_EOF
export { default } from './$component_name';
export { default as $component_name } from './$component_name';
INDEX_EOF

    print_ok "Index file created: $component_path/index.js"

    echo ""
    print_ok "Component generated successfully!"
    echo ""
    print_info "Files created:"
    echo "  - $component_name.jsx (main component)"
    echo "  - $component_name.css (styles)"
    echo "  - $component_name.test.jsx (tests)"
    echo "  - index.js (export)"
    echo ""
    print_info "Usage:"
    echo "  import $component_name from './$component_name';"
    echo "  <$component_name>Content</$component_name>"
    echo ""

    return 0
}

# Generate hook template
generate_hook() {
    local hook_name=$1
    local hooks_dir=${2:-./src/hooks}

    print_section "Generating React Hook"

    # Validate hook name
    if [[ -z "$hook_name" ]]; then
        print_error "Hook name required"
        return 1
    fi

    if ! [[ "$hook_name" =~ ^use[A-Z][a-zA-Z0-9]*$ ]]; then
        print_error "Invalid hook name (must start with 'use' followed by uppercase)"
        return 1
    fi

    mkdir -p "$hooks_dir"

    print_info "Hook: $hook_name"
    print_info "Location: $hooks_dir/$hook_name.js"
    echo ""

    # Generate hook file
    cat > "$hooks_dir/$hook_name.js" << HOOK_EOF
import { useState, useCallback } from 'react';

/**
 * Custom hook: $hook_name
 * @param {*} initialValue - Initial state value
 * @returns {Object} Hook state and handlers
 */
const $hook_name = (initialValue) => {
  const [value, setValue] = useState(initialValue);

  const reset = useCallback(() => {
    setValue(initialValue);
  }, [initialValue]);

  return {
    value,
    setValue,
    reset,
  };
};

export default $hook_name;
HOOK_EOF

    print_ok "Hook file created: $hooks_dir/$hook_name.js"

    # Generate test file
    cat > "$hooks_dir/$hook_name.test.js" << HOOK_TEST_EOF
import { renderHook, act } from '@testing-library/react';
import $hook_name from './$hook_name';

describe('$hook_name', () => {
  it('initializes with correct value', () => {
    const { result } = renderHook(() => $hook_name('initial'));
    expect(result.current.value).toBe('initial');
  });

  it('updates value', () => {
    const { result } = renderHook(() => $hook_name('initial'));
    act(() => {
      result.current.setValue('updated');
    });
    expect(result.current.value).toBe('updated');
  });

  it('resets to initial value', () => {
    const { result } = renderHook(() => $hook_name('initial'));
    act(() => {
      result.current.setValue('updated');
    });
    act(() => {
      result.current.reset();
    });
    expect(result.current.value).toBe('initial');
  });
});
HOOK_TEST_EOF

    print_ok "Hook test file created: $hooks_dir/$hook_name.test.js"

    echo ""
    print_ok "Hook generated successfully!"
    echo ""
    print_info "Usage:"
    echo "  import $hook_name from './hooks/$hook_name';"
    echo "  const { value, setValue, reset } = $hook_name(initialValue);"
    echo ""

    return 0
}

# Generate context provider
generate_context() {
    local context_name=$1
    local contexts_dir=${2:-./src/contexts}

    print_section "Generating React Context"

    # Validate context name
    if [[ -z "$context_name" ]]; then
        print_error "Context name required"
        return 1
    fi

    mkdir -p "$contexts_dir"

    print_info "Context: $context_name"
    print_info "Location: $contexts_dir/${context_name}Context.jsx"
    echo ""

    # Generate context file
    cat > "$contexts_dir/${context_name}Context.jsx" << CONTEXT_EOF
import React, { createContext, useState, useCallback } from 'react';
import PropTypes from 'prop-types';

export const ${context_name}Context = createContext();

/**
 * ${context_name}Provider component
 * @param {Object} props - Component props
 * @returns {JSX.Element}
 */
export const ${context_name}Provider = ({ children }) => {
  const [state, setState] = useState({});

  const updateState = useCallback((updates) => {
    setState((prev) => ({ ...prev, ...updates }));
  }, []);

  const value = {
    state,
    updateState,
  };

  return (
    <${context_name}Context.Provider value={value}>
      {children}
    </${context_name}Context.Provider>
  );
};

${context_name}Provider.propTypes = {
  children: PropTypes.node.isRequired,
};

export const use${context_name} = () => {
  const context = React.useContext(${context_name}Context);
  if (!context) {
    throw new Error('use${context_name} must be used within ${context_name}Provider');
  }
  return context;
};
CONTEXT_EOF

    print_ok "Context file created: $contexts_dir/${context_name}Context.jsx"

    echo ""
    print_ok "Context generated successfully!"
    echo ""
    print_info "Usage:"
    echo "  1. Wrap app with provider:"
    echo "     <${context_name}Provider><App /></${context_name}Provider>"
    echo ""
    echo "  2. Use in components:"
    echo "     const { state, updateState } = use${context_name}();"
    echo ""

    return 0
}

# Export functions
export -f generate_component
export -f generate_hook
export -f generate_context
