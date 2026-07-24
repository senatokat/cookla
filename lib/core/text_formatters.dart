class AppTextFormatters {
  const AppTextFormatters._();

  static String displayName(Iterable<String> parts, {String fallback = ''}) {
    final value = parts
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join(' ')
        .trim();
    if (value.isEmpty) return fallback;
    return titleCaseName(value);
  }

  static String titleCaseName(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(_capitalizeCompoundName)
        .join(' ');
  }

  static String _capitalizeCompoundName(String value) {
    return value.split('-').map((part) => _capitalizeWord(part)).join('-');
  }

  static String _capitalizeWord(String value) {
    if (value.isEmpty) return value;
    final lower = value.toLowerCase();
    final first = lower.substring(0, 1);
    return '${_turkishUpper(first)}${lower.substring(1)}';
  }

  static String _turkishUpper(String value) {
    switch (value) {
      case 'i':
        return 'İ';
      case 'ı':
        return 'I';
      case 'ğ':
        return 'Ğ';
      case 'ü':
        return 'Ü';
      case 'ş':
        return 'Ş';
      case 'ö':
        return 'Ö';
      case 'ç':
        return 'Ç';
      default:
        return value.toUpperCase();
    }
  }
}
