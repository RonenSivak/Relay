#!/usr/bin/env bash
# detect-test-framework.sh -- Deterministic detection of test framework and project type
# Outputs JSON to stdout. All diagnostic messages go to stderr.
#
# Usage: bash detect-test-framework.sh [target-directory]
#        target-directory defaults to current working directory

set -euo pipefail

TARGET_DIR="${1:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

# Ensure package.json exists
if [ ! -f "$TARGET_DIR/package.json" ]; then
  echo '{"error": "No package.json found in target directory"}' 
  exit 1
fi

PKG_JSON="$TARGET_DIR/package.json"

# --- Helper: check if a dep exists in package.json (dependencies or devDependencies) ---
has_dep() {
  local dep="$1"
  # Check both dependencies and devDependencies
  if command -v node &>/dev/null; then
    node -e "
      const pkg = require('$PKG_JSON');
      const deps = { ...pkg.dependencies, ...pkg.devDependencies };
      process.exit(deps['$dep'] ? 0 : 1);
    " 2>/dev/null
  else
    # Fallback: grep-based detection
    grep -q "\"$dep\"" "$PKG_JSON" 2>/dev/null
  fi
}

has_dev_dep() {
  local dep="$1"
  if command -v node &>/dev/null; then
    node -e "
      const pkg = require('$PKG_JSON');
      const deps = pkg.devDependencies || {};
      process.exit(deps['$dep'] ? 0 : 1);
    " 2>/dev/null
  else
    grep -q "\"$dep\"" "$PKG_JSON" 2>/dev/null
  fi
}

# --- Detect current test framework ---
FRAMEWORK="unknown"
JEST_CONFIG=""

if has_dev_dep "vitest" || has_dep "vitest"; then
  FRAMEWORK="vitest"
elif has_dev_dep "jest" || has_dep "jest"; then
  FRAMEWORK="jest"
fi

# Find jest config file
for cfg in jest.config.js jest.config.ts jest.config.mjs jest.config.cjs; do
  if [ -f "$TARGET_DIR/$cfg" ]; then
    JEST_CONFIG="$cfg"
    break
  fi
done

# Check for jest config in package.json
if [ -z "$JEST_CONFIG" ]; then
  if command -v node &>/dev/null; then
    if node -e "const p=require('$PKG_JSON'); process.exit(p.jest ? 0 : 1)" 2>/dev/null; then
      JEST_CONFIG="package.json (jest key)"
    fi
  fi
fi

# --- Detect project type ---
PROJECT_TYPE="standalone"

if has_dev_dep "@wix/serverless-jest-config" || has_dev_dep "@wix/serverless-vitest-config"; then
  PROJECT_TYPE="serverless"
elif command -v node &>/dev/null && node -e "
  const pkg = require('$PKG_JSON');
  const fw = pkg.wix && pkg.wix.framework && pkg.wix.framework.type;
  process.exit(fw === 'WIX_SERVERLESS' ? 0 : 1);
" 2>/dev/null; then
  PROJECT_TYPE="serverless"
elif has_dep "@wix/yoshi-flow-bm" || has_dev_dep "jest-yoshi-preset" || has_dev_dep "@wix/jest-yoshi-preset-base"; then
  PROJECT_TYPE="yoshi-flow-bm"
elif has_dep "@wix/yoshi-flow-editor"; then
  PROJECT_TYPE="editor-flow"
elif has_dev_dep "@wix/fed-cli-vitest" || has_dep "@wix/fed-cli"; then
  PROJECT_TYPE="fed-cli"
fi

# --- Check for "type": "module" ---
HAS_TYPE_MODULE="false"
if command -v node &>/dev/null; then
  if node -e "const p=require('$PKG_JSON'); process.exit(p.type === 'module' ? 0 : 1)" 2>/dev/null; then
    HAS_TYPE_MODULE="true"
  fi
else
  if grep -q '"type"[[:space:]]*:[[:space:]]*"module"' "$PKG_JSON" 2>/dev/null; then
    HAS_TYPE_MODULE="true"
  fi
fi

# --- Count test files ---
TEST_FILE_COUNT=$(find "$TARGET_DIR" \
  -type f \( -name "*.spec.ts" -o -name "*.spec.tsx" -o -name "*.spec.js" -o -name "*.spec.jsx" \
  -o -name "*.test.ts" -o -name "*.test.tsx" -o -name "*.test.js" -o -name "*.test.jsx" \) \
  -not -path "*/node_modules/*" -not -path "*/dist/*" -not -path "*/.git/*" \
  2>/dev/null | wc -l | tr -d ' ')

# --- Blocker detection ---
BLOCKERS="[]"
blocker_list=()

# Blocker 1: Stylable
ST_CSS_COUNT=$(find "$TARGET_DIR" -type f \( -name "*.st.css" \) \
  -not -path "*/node_modules/*" -not -path "*/dist/*" \
  2>/dev/null | wc -l | tr -d ' ')

if [ "$ST_CSS_COUNT" -gt 0 ] || has_dep "wix-style-react"; then
  blocker_list+=("{\"id\":\"stylable\",\"severity\":\"hard\",\"detail\":\"Found $ST_CSS_COUNT .st.css files or wix-style-react dependency\"}")
fi

# Blocker 2: wix-testkit-base / ambassador-testkit
if has_dev_dep "@wix/ambassador-testkit" || has_dev_dep "@wix/ambassador-grpc-testkit" || has_dev_dep "wix-testkit-base"; then
  blocker_list+=("{\"id\":\"testkit-base\",\"severity\":\"workaround\",\"detail\":\"ambassador-testkit or wix-testkit-base in devDependencies\"}")
fi

# Blocker 3: Yoshi monorepo (check parent for workspaces)
PARENT_PKG="$TARGET_DIR/../package.json"
if [ -f "$PARENT_PKG" ]; then
  if command -v node &>/dev/null; then
    WORKSPACE_COUNT=$(node -e "
      try {
        const p = require('$(cd "$TARGET_DIR/.." && pwd)/package.json');
        const ws = p.workspaces || (p.workspaces && p.workspaces.packages) || [];
        const arr = Array.isArray(ws) ? ws : (ws.packages || []);
        console.log(arr.length);
      } catch(e) { console.log(0); }
    " 2>/dev/null || echo "0")
    if [ "$WORKSPACE_COUNT" -gt 1 ]; then
      # Check if sibling packages use yoshi
      YOSHI_SIBLINGS=$(find "$TARGET_DIR/.." -maxdepth 3 -name "package.json" \
        -not -path "*/node_modules/*" -not -path "$PKG_JSON" \
        -exec grep -l "yoshi-flow" {} \; 2>/dev/null | wc -l | tr -d ' ')
      if [ "$YOSHI_SIBLINGS" -gt 0 ]; then
        blocker_list+=("{\"id\":\"yoshi-monorepo\",\"severity\":\"warning\",\"detail\":\"$YOSHI_SIBLINGS sibling packages use yoshi-flow in workspace\"}")
      fi
    fi
  fi
fi

# Blocker 4: yoshi-flow-bm ESM issues
if has_dep "@wix/yoshi-flow-bm"; then
  blocker_list+=("{\"id\":\"bm-flow-esm\",\"severity\":\"warning\",\"detail\":\"@wix/yoshi-flow-bm has ESM compatibility issues with Vitest\"}")
fi

# Build blockers JSON array
if [ ${#blocker_list[@]} -gt 0 ]; then
  BLOCKERS="[$(IFS=,; echo "${blocker_list[*]}")]"
fi

# --- Find test script ---
TEST_SCRIPT=""
if command -v node &>/dev/null; then
  TEST_SCRIPT=$(node -e "
    const p = require('$PKG_JSON');
    console.log((p.scripts && p.scripts.test) || '');
  " 2>/dev/null || echo "")
fi

# --- Output JSON ---
cat <<EOF
{
  "framework": "$FRAMEWORK",
  "projectType": "$PROJECT_TYPE",
  "jestConfig": "$JEST_CONFIG",
  "packageJson": "package.json",
  "testFileCount": $TEST_FILE_COUNT,
  "hasTypeModule": $HAS_TYPE_MODULE,
  "testScript": "$TEST_SCRIPT",
  "blockers": $BLOCKERS
}
EOF
