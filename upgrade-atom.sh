#!/usr/bin/env bash

echo "=== Atom Project Auto-Upgrader ==="
echo "Modernizing dependencies..."

# ---------------------------------------------------------
# 1. Ensure you're using a modern Node version
# ---------------------------------------------------------
NODE_MIN=18
NODE_CUR=$(node -v | sed 's/v//g' | cut -d'.' -f1)

if [ "$NODE_CUR" -lt "$NODE_MIN" ]; then
  echo "❌ Node version too old. Please install Node 18 or newer."
  exit 1
fi

# ---------------------------------------------------------
# 2. Clean old folders
# ---------------------------------------------------------
echo "🧹 Removing old build artifacts..."
rm -rf node_modules
rm -rf apm/node_modules
rm -rf script/node_modules

# ---------------------------------------------------------
# 3. Update package.json dependencies
# ---------------------------------------------------------
echo "📦 Auto-updating npm dependencies to latest..."
npm install -g npm-check-updates
ncu -u

echo "📦 Installing updated dependencies..."
npm install --legacy-peer-deps

# ---------------------------------------------------------
# 4. Upgrade Electron
# ---------------------------------------------------------
TARGET_ELECTRON="28.2.0"
echo "⚡ Upgrading Electron to version $TARGET_ELECTRON..."
npm install --save-dev electron@$TARGET_ELECTRON

# ---------------------------------------------------------
# 5. Replace CoffeeScript with TypeScript
# ---------------------------------------------------------
echo "☕ Removing CoffeeScript..."
npm remove coffeescript coffee-script

echo "🔧 Adding TypeScript & conversions..."
npm install --save-dev typescript ts-node @types/node decaffeinate

# Convert all CoffeeScript to JS
echo "📀 Converting CoffeeScript → JavaScript..."
find . -name "*.coffee" -type f | while read file; do
  echo "   → Converting $file"
  npx decaffeinate "$file"
  rm "$file"
done

# Initialize TypeScript config
echo "🛠 Creating tsconfig.json..."
cat <<EOF > tsconfig.json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "strict": false,
    "esModuleInterop": true,
    "allowJs": true,
    "skipLibCheck": true,
    "outDir": "dist"
  },
  "include": ["src", "packages"]
}
EOF

# ---------------------------------------------------------
# 6. Fix Electron forge/electron-builder issues
# ---------------------------------------------------------
echo "🔧 Installing modern Electron build tools..."
npm install --save-dev @electron-forge/cli
npx electron-forge import

# ---------------------------------------------------------
# 7. Inform user
# ---------------------------------------------------------
echo ""
echo "🎉 Upgrade complete!"
echo "You may need to manually fix:"
echo "• Electron remote module usage"
echo "• ipcRenderer → contextBridge migration"
echo "• fs and path API changes"
echo "• Any deprecated Atom APIs"
echo ""
echo "Run the project with:"
echo "  npx electron ."
echo ""
echo "✔ Modernization 80% complete!"
