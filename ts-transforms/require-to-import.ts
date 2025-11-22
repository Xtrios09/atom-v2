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
