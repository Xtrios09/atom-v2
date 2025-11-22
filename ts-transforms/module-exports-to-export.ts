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
