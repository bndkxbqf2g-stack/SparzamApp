/// Converts retailer supplied category slugs into readable UI labels.
///
/// The returned value is presentation only. The raw category remains on
/// [OfferImportRecord] for provenance and is never used as product identity,
/// price evidence, or route input.
String presentProspectCategory(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return '';

  var key = value.toLowerCase().replaceAll(RegExp(r'[_-]+'), ' ');
  key = key.replaceAll(RegExp(r'\s+'), ' ').trim();
  key = key.replaceFirst(RegExp(r'^\d+[a-z]?\s+'), '');
  key = key.replaceFirst(RegExp(r'\s*\d+$'), '');

  const labels = <String, String>{
    'fleisch geflügel wurst': 'Fleisch & Fisch',
    'frischer fisch': 'Fleisch & Fisch',
    'obst gemüse pflanzen': 'Obst & Gemüse',
    'molkereiprodukte fette': 'Milchprodukte',
    'tiefkühlkost': 'Tiefkühl',
    'feinkost konserven': 'Vorrat & Konserven',
    'grundnahrungsmittel': 'Vorrat & Konserven',
    'kaffee tee süßwaren knabberartikel': 'Kaffee & Snacks',
    'getränke spirituosen': 'Getränke',
    'drogerie tiernahrung': 'Drogerie',
    'elektro büro medien': 'Non-Food',
    'heim haus': 'Haushalt',
    'bekleidung auto freizeit spiel': 'Non-Food',
    'wochenstartwerbung': 'Weitere Angebote',
    'store': 'Weitere Angebote',
    'dauerhaft im preis gesenkt': 'Dauerhaft günstiger',
    'drogerie und haushalt': 'Drogerie',
    'fleisch und wurst': 'Fleisch & Fisch',
    'food highlights für alle': 'Weitere Angebote',
    'framstag': 'Weitere Angebote',
    'garten und baumarkt': 'Non-Food',
    'getränke': 'Getränke',
    'haushalt und wohnen': 'Haushalt',
    'kinderwelt': 'Non-Food',
    'kochen und backen': 'Vorrat & Konserven',
    'kühlregal': 'Kühlregal',
    'obst und gemüse': 'Obst & Gemüse',
    'pflanzen': 'Garten & Pflanzen',
    'pflanzen mo sa': 'Garten & Pflanzen',
    'sparen auf top marken': 'Weitere Angebote',
    'süßigkeiten und snacks': 'Kaffee & Snacks',
    'top angebote': 'Weitere Angebote',
    'weitere angebote': 'Weitere Angebote',
    'xxl lebensmittel für alle': 'Weitere Angebote',
  };
  final translatedKey = _replaceGermanTransliterations(key);
  return labels[key] ?? labels[translatedKey] ?? _titleCase(key);
}

/// Provides a presentation-only fallback when a retailer omits a category.
///
/// This classification is deliberately kept separate from product identity,
/// pricing and route planning. Both the offers and prospect screens use it so
/// the same label is grouped consistently across the app.
String fallbackProspectCategory(String label) {
  final value = label.toLowerCase();
  if (RegExp(r'gemüse|salat|tomat|gurk|kartoff|obst|apfel|banane|traube')
      .hasMatch(value)) {
    return 'Obst & Gemüse';
  }
  if (RegExp(r'milch|joghurt|käse|schmand|sahne|quark|butter')
      .hasMatch(value)) {
    return 'Milchprodukte';
  }
  if (RegExp(r'hack|fleisch|wurst|schinken|fisch|lachs|hähnchen')
      .hasMatch(value)) {
    return 'Fleisch & Fisch';
  }
  if (RegExp(r'brot|bröt|toast|backwaren|croissant').hasMatch(value)) {
    return 'Backwaren';
  }
  if (RegExp(r'kaffee|espresso|tee|snack|chips|knabber').hasMatch(value)) {
    return 'Kaffee & Snacks';
  }
  if (RegExp(r'getränk|wasser|saft|cola|bier|wein').hasMatch(value)) {
    return 'Getränke';
  }
  if (RegExp(r'tiefkühl|tk |pizza|eis ').hasMatch(value)) {
    return 'Tiefkühl';
  }
  if (RegExp(r'reis|nudel|mehl|zucker|dose|konserve|sauce|öl|gewürz')
      .hasMatch(value)) {
    return 'Vorrat & Konserven';
  }
  if (RegExp(r'seife|shampoo|zahnpasta|deo|waschmittel|reiniger')
      .hasMatch(value)) {
    return 'Drogerie';
  }
  if (RegExp(r'küche|haushalt|müll|papier|lampe|werkzeug|akku|bastel|raum-weiß')
      .hasMatch(value)) {
    return 'Haushalt';
  }
  if (RegExp(r'non-food|bekleidung|schuh|spielzeug|dekoration')
      .hasMatch(value)) {
    return 'Non-Food';
  }
  return 'Weitere Angebote';
}

String _replaceGermanTransliterations(String value) => value
    .replaceAll('ae', 'ä')
    .replaceAll('oe', 'ö')
    .replaceAll('ue', 'ü')
    .replaceAll('ss', 'ß');

String _titleCase(String value) => value
    .split(' ')
    .where((word) => word.isNotEmpty)
    .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
    .join(' ');
