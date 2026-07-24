class IngredientData {
  final String title;
  final String emoji;
  final String amount;

  const IngredientData({
    required this.title,
    required this.emoji,
    this.amount = '',
  });

  static const Map<String, String> catalog = {
    'Limon': '\u{1F34B}',
    'Avokado': '\u{1F951}',
    'Çilek': '\u{1F353}',
    'Brokoli': '\u{1F966}',
    'Havuç': '\u{1F955}',
    'Biber': '\u{1FAD1}',
    'Domates': '\u{1F345}',
    'Ceviz': '\u{1F330}',
    'Kavun': '\u{1F348}',
    'Salatalık': '\u{1F952}',
    'Badem': '\u{1F95C}',
    'Muz': '\u{1F34C}',
    'Kiraz': '\u{1F352}',
    'Yumurta': '\u{1F95A}',
    'Patlıcan': '\u{1F346}',
    'Elma': '\u{1F34E}',
    'Armut': '\u{1F350}',
    'Portakal': '\u{1F34A}',
    'Un': '\u{1F33E}',
    'Süt': '\u{1F95B}',
    'Peynir': '\u{1F9C0}',
    'Tereyağı': '\u{1F9C8}',
    'Yoğurt': '\u{1F963}',
    'Krema': '\u{1F96B}',
    'Makarna': '\u{1F35D}',
    'Pirinç': '\u{1F35A}',
    'Patates': '\u{1F954}',
    'Soğan': '\u{1F9C5}',
    'Sarımsak': '\u{1F9C4}',
    'Maydanoz': '\u{1F33F}',
    'Dereotu': '\u{1F33F}',
    'Roka': '\u{1F96C}',
    'Marul': '\u{1F96C}',
    'Ispanak': '\u{1F96C}',
    'Kabak': '\u{1F96C}',
    'Mantar': '\u{1F344}',
    'Mısır': '\u{1F33D}',
    'Bezelye': '\u{1FADB}',
    'Nohut': '\u{1F95B}',
    'Mercimek': '\u{1F95B}',
    'Fasulye': '\u{1FAD8}',
    'Tavuk': '\u{1F357}',
    'Et': '\u{1F969}',
    'Kıyma': '\u{1F969}',
    'Balık': '\u{1F41F}',
    'Ton balığı': '\u{1F41F}',
    'Somon': '\u{1F41F}',
    'Zeytinyağı': '\u{1FAD2}',
    'Ayçiçek yağı': '\u{1FAD2}',
    'Salça': '\u{1F345}',
    'Bal': '\u{1F36F}',
    'Şeker': '\u{1F9C2}',
    'Tuz': '\u{1F9C2}',
    'Karabiber': '\u{1FAD9}',
    'Pul biber': '\u{1F336}',
    'Kimyon': '\u{1F33F}',
    'Kekik': '\u{1F331}',
    'Nane': '\u{1F33F}',
    'Vanilya': '\u{1F36A}',
    'Kabartma tozu': '\u{1F9C1}',
    'Çikolata': '\u{1F36B}',
    'Kakao': '\u{1F36B}',
  };

  static const String fallbackEmoji = '\u{1F37D}';

  static List<String> get defaultNames => catalog.keys.toList(growable: false);

  static final Map<String, String> _catalogAliases = {
    for (final name in catalog.keys) _stripTurkish(name).toLowerCase(): name,
  };

  static String emojiFor(String name) {
    final cleaned = name.trim();
    final normalized = _normalizeLabel(cleaned);
    return catalog[cleaned] ?? catalog[normalized] ?? fallbackEmoji;
  }

  factory IngredientData.fromMap(Map<String, dynamic> map) {
    final title = (map['title'] ?? map['name'] ?? '').toString();
    return IngredientData(
      title: title,
      emoji: (map['emoji'] ?? emojiFor(title)).toString(),
      amount: (map['amount'] ?? '').toString(),
    );
  }

  factory IngredientData.fromName(String name) {
    final cleaned = _normalizeLabel(name.trim());
    return IngredientData(title: cleaned, emoji: emojiFor(cleaned));
  }

  Map<String, dynamic> toMap() {
    return {'title': title, 'emoji': emoji, 'amount': amount};
  }

  IngredientData copyWithAmount(String value) {
    return IngredientData(title: title, emoji: emoji, amount: value.trim());
  }

  @override
  String toString() => 'IngredientData(title: $title, emoji: $emoji)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IngredientData &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          emoji == other.emoji &&
          amount == other.amount;

  @override
  int get hashCode => title.hashCode ^ emoji.hashCode ^ amount.hashCode;

  static String _normalizeLabel(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    return _catalogAliases[_stripTurkish(trimmed).toLowerCase()] ?? trimmed;
  }

  static String _stripTurkish(String value) {
    return value
        .replaceAll('Ç', 'C')
        .replaceAll('ç', 'c')
        .replaceAll('Ğ', 'G')
        .replaceAll('ğ', 'g')
        .replaceAll('İ', 'I')
        .replaceAll('ı', 'i')
        .replaceAll('Ö', 'O')
        .replaceAll('ö', 'o')
        .replaceAll('Ş', 'S')
        .replaceAll('ş', 's')
        .replaceAll('Ü', 'U')
        .replaceAll('ü', 'u');
  }
}
