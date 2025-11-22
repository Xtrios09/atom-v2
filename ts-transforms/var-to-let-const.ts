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
