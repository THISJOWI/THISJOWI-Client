import 'dart:math';

class PasswordGeneratorService {
  PasswordGeneratorService._();

  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _numbers = '0123456789';
  static const String _symbols = '!@#\$%^&*()-_=+[]{}|;:,.<>?/~`';

  static final Random _random = Random.secure();

  static String generate({
    int length = 16,
    bool useUppercase = true,
    bool useLowercase = true,
    bool useNumbers = true,
    bool useSymbols = true,
  }) {
    String chars = '';
    if (useLowercase) chars += _lowercase;
    if (useUppercase) chars += _uppercase;
    if (useNumbers) chars += _numbers;
    if (useSymbols) chars += _symbols;

    if (chars.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      buffer.write(chars[_random.nextInt(chars.length)]);
    }

    var result = buffer.toString();

    if (useLowercase && !result.contains(RegExp(r'[a-z]'))) {
      result = _ensureAtLeastOne(result, _lowercase, length);
    }
    if (useUppercase && !result.contains(RegExp(r'[A-Z]'))) {
      result = _ensureAtLeastOne(result, _uppercase, length);
    }
    if (useNumbers && !result.contains(RegExp(r'[0-9]'))) {
      result = _ensureAtLeastOne(result, _numbers, length);
    }
    if (useSymbols && !result.contains(RegExp(r'[!@#\$%^&*()\-_=+\[\]{}|;:,.<>?/~`]'))) {
      result = _ensureAtLeastOne(result, _symbols, length);
    }

    return result;
  }

  static String _ensureAtLeastOne(String password, String charSet, int length) {
    final chars = password.split('');
    chars[_random.nextInt(length)] = charSet[_random.nextInt(charSet.length)];
    return chars.join();
  }

  static double calculateEntropy(String password) {
    int poolSize = 0;
    if (password.contains(RegExp(r'[a-z]'))) poolSize += 26;
    if (password.contains(RegExp(r'[A-Z]'))) poolSize += 26;
    if (password.contains(RegExp(r'[0-9]'))) poolSize += 10;
    if (password.contains(RegExp(r'[^a-zA-Z0-9]'))) poolSize += 33;

    if (poolSize == 0) return 0;
    return password.length * (log(poolSize) / log(2));
  }

  static ({double bits, String label}) strengthInfo(String password) {
    if (password.isEmpty) {
      return (bits: 0, label: 'Empty');
    }
    final entropy = calculateEntropy(password);
    String label;
    if (entropy < 28) {
      label = 'Weak';
    } else if (entropy < 36) {
      label = 'Fair';
    } else if (entropy < 60) {
      label = 'Strong';
    } else if (entropy < 128) {
      label = 'Very Strong';
    } else {
      label = 'Excellent';
    }
    return (bits: entropy, label: label);
  }

  static double strengthFraction(String password) {
    final entropy = calculateEntropy(password);
    return (entropy / 128).clamp(0.0, 1.0);
  }
}
