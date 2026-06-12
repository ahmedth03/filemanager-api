import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ────────────────────────────────────────────────────────────────────────────
// String extensions
// ────────────────────────────────────────────────────────────────────────────

extension StringX on String {
  /// Returns `true` if the string is empty after trimming.
  bool get isBlank => trim().isEmpty;

  /// Returns `true` if the string is not empty after trimming.
  bool get isNotBlank => trim().isNotEmpty;

  /// Capitalises the first letter, lowercase the rest.
  String get capitalised =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';

  /// Capitalises the first letter of every word.
  String get titleCase => split(' ')
      .map((w) => w.isEmpty ? w : w.capitalised)
      .join(' ');

  /// Returns `null` if the string is blank, otherwise returns itself.
  String? get nullIfBlank => isBlank ? null : this;

  /// Truncates to [maxLength] and appends [ellipsis] if truncated.
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }

  /// Removes all Arabic diacritics (tashkeel / harakat).
  String get removeDiacritics =>
      replaceAll(RegExp(r'[ً-ٰٟ]'), '');

  /// Normalises Arabic text for comparison (removes diacritics, alef variants).
  String get normaliseArabic => removeDiacritics
      .replaceAll(RegExp(r'[أإآ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي');

  /// Returns `true` if the string is a valid email address.
  bool get isValidEmail =>
      RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
          .hasMatch(this);

  /// Returns `true` if the string is a valid Algerian mobile number.
  bool get isValidAlgerianPhone =>
      RegExp(r'^(?:\+213|00213|0213)?0?[5-7][0-9]{8}$')
          .hasMatch(replaceAll(RegExp(r'[\s\-\(\)]'), ''));

  /// Converts a snake_case or kebab-case string to Sentence case.
  String get fromSnakeCase =>
      replaceAll('_', ' ').replaceAll('-', ' ').capitalised;

  /// Parses a date string (ISO 8601) and returns a [DateTime], or `null`.
  DateTime? get toDateTime => DateTime.tryParse(this);
}

// ────────────────────────────────────────────────────────────────────────────
// DateTime extensions
// ────────────────────────────────────────────────────────────────────────────

extension DateTimeX on DateTime {
  /// Returns `true` if this date is today.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Returns `true` if this date was yesterday.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Returns `true` if this date is in the current week.
  bool get isThisWeek {
    final now = DateTime.now();
    final diff = now.difference(this);
    return diff.inDays < 7;
  }

  /// Formats with a named locale, e.g. `date.format('dd/MM/yyyy', 'ar')`.
  String format(String pattern, [String locale = 'ar']) =>
      DateFormat(pattern, locale).format(this);

  /// Returns a short display string (today/yesterday/date based on age).
  String get smartDisplay {
    if (isToday) return DateFormat.Hm('ar').format(this);
    if (isYesterday) return 'أمس';
    if (isThisWeek) return DateFormat.EEEE('ar').format(this);
    return DateFormat.yMd('ar').format(this);
  }

  /// Returns `true` if the date is in the past.
  bool get isPast => isBefore(DateTime.now());

  /// Returns `true` if the date is in the future.
  bool get isFuture => isAfter(DateTime.now());

  /// Returns this date at midnight (00:00:00).
  DateTime get startOfDay => DateTime(year, month, day);

  /// Returns this date at the last moment of the day (23:59:59.999).
  DateTime get endOfDay =>
      DateTime(year, month, day, 23, 59, 59, 999);
}

// ────────────────────────────────────────────────────────────────────────────
// BuildContext extensions
// ────────────────────────────────────────────────────────────────────────────

extension BuildContextX on BuildContext {
  // ── Theme ─────────────────────────────────────────────────────────────────
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // ── Media query ───────────────────────────────────────────────────────────
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  EdgeInsets get padding => MediaQuery.paddingOf(this);
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);
  double get statusBarHeight => MediaQuery.paddingOf(this).top;
  double get bottomBarHeight => MediaQuery.paddingOf(this).bottom;
  bool get isKeyboardOpen => MediaQuery.viewInsetsOf(this).bottom > 0;

  // ── Responsive helpers ────────────────────────────────────────────────────
  bool get isSmallScreen => screenWidth < 360;
  bool get isMediumScreen => screenWidth >= 360 && screenWidth < 600;
  bool get isLargeScreen => screenWidth >= 600;

  // ── Localisation ──────────────────────────────────────────────────────────
  bool get isRtl =>
      Directionality.of(this) == TextDirection.rtl;

  // ── Scaffold / overlay ────────────────────────────────────────────────────
  ScaffoldState get scaffold => Scaffold.of(this);
  ScaffoldMessengerState get messenger => ScaffoldMessenger.of(this);

  void showSnackBar(
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? colorScheme.error : colorScheme.primary,
          duration: duration,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void hideKeyboard() => FocusScope.of(this).unfocus();
}

// ────────────────────────────────────────────────────────────────────────────
// num / double / int extensions
// ────────────────────────────────────────────────────────────────────────────

extension NumX on num {
  /// Returns a [SizedBox] with this value as both width and height.
  SizedBox get squareBox => SizedBox(width: toDouble(), height: toDouble());

  /// Returns a [SizedBox] with this value as height only.
  SizedBox get heightBox => SizedBox(height: toDouble());

  /// Returns a [SizedBox] with this value as width only.
  SizedBox get widthBox => SizedBox(width: toDouble());

  /// Returns all-side padding of this value.
  EdgeInsets get allPadding => EdgeInsets.all(toDouble());

  /// Returns symmetric vertical padding of this value.
  EdgeInsets get verticalPadding =>
      EdgeInsets.symmetric(vertical: toDouble());

  /// Returns symmetric horizontal padding of this value.
  EdgeInsets get horizontalPadding =>
      EdgeInsets.symmetric(horizontal: toDouble());
}

// ────────────────────────────────────────────────────────────────────────────
// List extensions
// ────────────────────────────────────────────────────────────────────────────

extension ListX<T> on List<T> {
  /// Returns the element at [index] or `null` if out of bounds.
  T? getOrNull(int index) =>
      (index >= 0 && index < length) ? this[index] : null;

  /// Returns a new list with [separator] inserted between each element.
  List<T> intersperse(T separator) {
    if (length <= 1) return toList();
    final result = <T>[];
    for (int i = 0; i < length; i++) {
      result.add(this[i]);
      if (i < length - 1) result.add(separator);
    }
    return result;
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Color extensions
// ────────────────────────────────────────────────────────────────────────────

extension ColorX on Color {
  /// Returns this color with modified opacity.
  Color withAlphaFactor(double factor) =>
      withOpacity(opacity * factor.clamp(0.0, 1.0));
}
