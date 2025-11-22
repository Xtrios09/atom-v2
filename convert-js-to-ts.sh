#!/usr/bin/env bash

echo "=== JavaScript → TypeScript Syntax Converter ==="

# Install required tools
echo "📦 Installing jscodeshift + ts-migrate..."
npm install -g jscodeshift ts-migrate @babel/preset-typescript

# Create a temporary transform folder
mkdir -p ts-transforms

# ---------------------------
# 1. Transform require() → import
# ---------------------------

cat << 'EOF' > ts-transforms/require-to-import.js
module.exports = function(file, api) {
  const j = api.jscodeshift;
  const root = j(file.source);

  root.find(j.CallExpression, { callee: { name: "require" } })
    .filter(path => path.value.arguments.length === 1)
    .forEach(path => {
      const requireArg = path.value.arguments[0].value;
      const decl = path.parent.value;

      if (decl.type === "VariableDeclarator") {
        const localName = decl.id.name;

        j(path.parent.parent).replaceWith(
          j.importDeclaration(
            [j.importDefaultSpecifier(j.identifier(localName))],
            j.literal(requireArg)
          )
        );
      }
    });

  return root.toSource();
};
EOF

# ---------------------------
# 2. Convert module.exports → export default
# ---------------------------

cat << 'EOF' > ts-transforms/module-exports-to-export.js
module.exports = function(file, api) {
  const j = api.jscodeshift;
  const root = j(file.source);

  root.find(j.AssignmentExpression, {
    left: { object: { name: "module" }, property: { name: "exports" }}
  }).forEach(path => {
    const exported = path.value.right;
    j(path).replaceWith(
      j.exportDefaultDeclaration(exported)
    );
  });

  return root.toSource();
};
EOF

# ---------------------------
# 3. Convert var → let/const
# ---------------------------

cat << 'EOF' > ts-transforms/var-to-let-const.js
module.exports = function(file, api) {
  const j = api.jscodeshift;
  const root = j(file.source);

  root.find(j.VariableDeclaration, { kind: "var" })
    .forEach(path => {
      const isReassigned = j(path).find(j.UpdateExpression).size() > 0;
      path.value.kind = isReassigned ? "let" : "const";
    });

  return root.toSource();
};
EOF

# ---------------------------
# 4. Convert JS to TS with ts-migrate
# ---------------------------

echo "⚙️ Running TypeScript migrator (ts-migrate)..."
npx ts-migrate init .
npx ts-migrate migrate .

# ---------------------------
# 5. Rename files .js → .ts
# ---------------------------

echo "🔄 Renaming .js → .ts files..."
find . -type f -name "*.js" -not -path "*node_modules*" | while read file; do
  mv "$file" "${file%.js}.ts"
done

echo "🎉 Complete! Your JS files are now modern TypeScript."
echo "You may need to fix:"
echo "• implicit any"
echo "• missing interfaces"
echo "• legacy Atom APIs"
echo "Run: npx tsc --noEmit"
