/// Standard full-name validation/formatting used for signup, profile,
/// guest-booking, and cardholder-name fields: each part starts with a
/// capital letter, letters only (hyphens/apostrophes allowed for names like
/// "Mary-Jane" or "O'Brien"), single spaces between parts, at least a first
/// and last name, and not a placeholder value like "Cardholder Name".
class NameValidator {
  NameValidator._();

  static final RegExp _namePartPattern =
      RegExp(r"^[A-Za-z]+(?:['-][A-Za-z]+)*$");

  // Words/phrases people type when they don't want to give a real name —
  // most commonly by echoing a form's own placeholder/label text back into
  // it (e.g. typing literal "Cardholder Name" into the cardholder field).
  static const Set<String> _placeholderWords = {
    'cardholder', 'card', 'holder', 'test', 'testing', 'sample', 'example',
    'name', 'firstname', 'lastname', 'guest', 'unknown', 'none', 'na',
    'asdf', 'qwerty', 'abc', 'xyz', 'user', 'customer', 'client', 'demo',
    'dummy', 'placeholder', 'anonymous', 'nobody', 'fake', 'temp',
    'temporary',
  };

  static const Set<String> _placeholderPhrases = {
    'card holder', 'cardholder name', 'card holder name', 'first last',
    'first name last name', 'your name', 'your full name', 'full name',
    'not applicable', 'no name', 'n a', 'test user', 'test test',
    'sample name', 'test name', 'john doe', 'jane doe',
  };

  static bool isPlaceholderName(String rawName) {
    final normalized = rawName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return false;
    if (_placeholderPhrases.contains(normalized)) return true;
    final words = normalized.split(' ');
    return words.every(_placeholderWords.contains);
  }

  static String? validate(String? value) {
    final name = (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
    if (name.isEmpty) return 'Please enter your full name';
    final parts = name.split(' ');
    if (parts.length < 2) {
      return 'Please enter both first and last name';
    }
    if (!parts.every(_namePartPattern.hasMatch)) {
      return 'Name should only contain letters (hyphens and apostrophes allowed)';
    }
    if (isPlaceholderName(name)) {
      return 'Please enter your real name, not a placeholder value';
    }
    return null;
  }

  /// For a payment form's "Name on card" / "Cardholder name" field — same
  /// standard as [validate] but with wording appropriate to that context.
  static String? validateCardholderName(String? value) {
    final name = (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
    if (name.isEmpty) return 'Please enter the name on the card';
    final parts = name.split(' ');
    if (parts.length < 2) {
      return 'Enter the cardholder\'s first and last name';
    }
    if (!parts.every(_namePartPattern.hasMatch)) {
      return 'Cardholder name should only contain letters';
    }
    if (isPlaceholderName(name)) {
      return 'Enter the actual name on the card, not "Cardholder Name"';
    }
    return null;
  }

  /// Title-cases every part, e.g. "john o'brien-smith" -> "John O'Brien-Smith".
  static String format(String rawName) {
    final name = rawName.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (name.isEmpty) return name;
    return name.split(' ').map(_formatPart).join(' ');
  }

  static String _formatPart(String part) {
    return part.split('-').map((seg) {
      return seg.split("'").map((piece) {
        if (piece.isEmpty) return piece;
        return piece[0].toUpperCase() + piece.substring(1).toLowerCase();
      }).join("'");
    }).join('-');
  }
}
