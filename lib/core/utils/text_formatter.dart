import 'package:intl/intl.dart';

class TextFormatter {
  // Capitalize first letter of each word
  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;

    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  // Capitalize first letter only
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';
  }

  // Convert to title case
  static String toTitleCase(String text) {
    return capitalizeWords(text.toLowerCase());
  }

  // Convert to sentence case
  static String toSentenceCase(String text) {
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';
  }

  // Remove extra whitespace
  static String trimExtraWhitespace(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // Format currency amount
  static String formatCurrency(double amount, {String currency = '\$'}) {
    final formatter = NumberFormat.currency(symbol: currency, decimalDigits: 2);
    return formatter.format(amount);
  }

  // Format number with commas
  static String formatNumber(int number) {
    return NumberFormat.decimalPattern().format(number);
  }

  // Truncate text with ellipsis
  static String truncate(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}$suffix';
  }

  // Convert to plural form
  static String pluralize(int count, String singular, String plural) {
    return count == 1 ? singular : plural;
  }

  // Get initials from name
  static String getInitials(String name, {int maxInitials = 2}) {
    if (name.isEmpty) return '';

    final words = name.trim().split(' ');
    String initials = '';

    for (int i = 0; i < words.length && i < maxInitials; i++) {
      if (words[i].isNotEmpty) {
        initials += words[i][0].toUpperCase();
      }
    }

    return initials;
  }

  // Mask sensitive information
  static String maskEmail(String email) {
    if (email.isEmpty) return email;

    final parts = email.split('@');
    if (parts.length != 2) return email;

    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 2) {
      return username;
    }

    final maskedUsername =
        '${username[0]}${'*' * (username.length - 2)}${username[username.length - 1]}';
    return '$maskedUsername@$domain';
  }

  // Mask phone number
  static String maskPhoneNumber(String phone) {
    if (phone.length < 4) return phone;

    final digitsOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length < 4) return phone;

    final firstThree = digitsOnly.substring(0, 3);
    final lastFour = digitsOnly.substring(digitsOnly.length - 4);
    final middleStars = '*' * (digitsOnly.length - 7);

    return '$firstThree-$middleStars$lastFour';
  }

  // Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // Validate and format URL
  static String? formatUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    Uri? uri;
    try {
      uri = Uri.parse(url);
    } catch (e) {
      return null;
    }

    if (!uri.hasScheme) {
      return 'https://$url';
    }

    return url;
  }

  // Remove HTML tags
  static String stripHtml(String html) {
    final document = RegExp(r'<[^>]*>?[^<]*');
    return html.replaceAll(document, '');
  }

  // Convert to kebab-case
  static String toKebabCase(String text) {
    return text
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .replaceAll(RegExp(r'([A-Z])'), '-\$1')
        .toLowerCase()
        .replaceAll(RegExp(r'[_\s]+'), '-');
  }

  // Convert to snake_case
  static String toSnakeCase(String text) {
    return text
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .replaceAll(RegExp(r'([A-Z])'), '_\$1')
        .toLowerCase();
  }

  // Check if string is empty or only whitespace
  static bool isEmptyOrWhitespace(String? text) {
    return text == null || text.trim().isEmpty;
  }

  // Get safe text (handle null values)
  static String safeText(String? text, {String defaultValue = ''}) {
    return text ?? defaultValue;
  }
}
