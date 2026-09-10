/// Explicit aliases avoid false matches such as sal/salmón or pan/panceta.
String ingredientKey(String value) {
  var name = value.toLowerCase().trim();
  const accents = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u'};
  accents.forEach((from, to) => name = name.replaceAll(from, to));
  name = name.replaceAll(RegExp(r'\s+'), ' ');
  const aliases = {
    'pechuga de pollo': 'pollo',
    'aceite de oliva': 'aceite',
    'huevos': 'huevo',
    'tomates': 'tomate',
    'papas': 'papa',
    'patata': 'papa',
    'patatas': 'papa',
    'cebollas': 'cebolla',
    'limones': 'limon',
    'zanahorias': 'zanahoria',
    'espinacas': 'espinaca',
    'fideos': 'pasta',
    'aceite de cocina': 'aceite',
    'pimienta negra': 'pimienta',
    'carne de res': 'carne',
    'palta': 'aguacate',
    'frijoles': 'frijol',
    'frejoles': 'frijol',
    'frejol': 'frijol',
  };
  return aliases[name] ?? name;
}

bool sameIngredient(String a, String b) => ingredientKey(a) == ingredientKey(b);
