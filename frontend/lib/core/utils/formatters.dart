import 'package:intl/intl.dart';

/// Formatting utilities for the HarfiDar application.
///
/// Covers:
/// - Algerian Dinar prices
/// - Dates in Arabic / French / English
/// - Phone numbers
/// - File sizes
/// - Durations
class AppFormatters {
  AppFormatters._();

  // ── Currency — Algerian Dinar (DZD / دج) ──────────────────────────────────

  static final _dzdAr = NumberFormat('#,##0 دج', 'ar');
  static final _dzdFr = NumberFormat('#,##0 DA', 'fr');
  static final _dzdEn = NumberFormat('#,##0 DZD', 'en');

  /// Formats [amount] as Algerian Dinar for the given [locale].
  ///
  /// - `ar` → "١٢٣٬٠٠٠ دج"
  /// - `fr` → "123 000 DA"
  /// - `en` → "123,000 DZD"
  static String formatPrice(double amount, {String locale = 'ar'}) {
    switch (locale) {
      case 'fr':
        return _dzdFr.format(amount);
      case 'en':
        return _dzdEn.format(amount);
      default:
        return _dzdAr.format(amount);
    }
  }

  /// Returns a compact price string, e.g. "1.2M دج" or "500K دج".
  static String formatPriceCompact(double amount, {String locale = 'ar'}) {
    final suffix = locale == 'fr' ? 'DA' : locale == 'en' ? 'DZD' : 'دج';
    if (amount >= 1_000_000) {
      return '${(amount / 1_000_000).toStringAsFixed(1)}M $suffix';
    }
    if (amount >= 1_000) {
      return '${(amount / 1_000).toStringAsFixed(0)}K $suffix';
    }
    return '${amount.toStringAsFixed(0)} $suffix';
  }

  // ── Dates ─────────────────────────────────────────────────────────────────

  /// Full date: "الأربعاء، ١١ يونيو ٢٠٢٥" (ar) / "mercredi 11 juin 2025" (fr) / "Wednesday, June 11, 2025" (en)
  static String formatDateFull(DateTime date, {String locale = 'ar'}) {
    final format = DateFormat.yMMMMEEEEd(locale);
    return format.format(date);
  }

  /// Short date: "١١/٦/٢٠٢٥" (ar) / "11/06/2025" (fr) / "6/11/2025" (en)
  static String formatDateShort(DateTime date, {String locale = 'ar'}) {
    final format = DateFormat.yMd(locale);
    return format.format(date);
  }

  /// Month + year: "يونيو ٢٠٢٥" / "juin 2025" / "June 2025"
  static String formatMonthYear(DateTime date, {String locale = 'ar'}) {
    final format = DateFormat.yMMMM(locale);
    return format.format(date);
  }

  /// Time only: "١٤:٣٠" (ar) / "14:30" (fr/en)
  static String formatTime(DateTime date, {String locale = 'ar'}) {
    final format = DateFormat.Hm(locale);
    return format.format(date);
  }

  /// Relative time, e.g. "منذ دقيقتين" / "il y a 2 minutes" / "2 minutes ago".
  static String formatRelativeTime(DateTime date, {String locale = 'ar'}) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) {
      return _relativeJustNow(locale);
    } else if (diff.inMinutes < 60) {
      return _relativeMins(diff.inMinutes, locale);
    } else if (diff.inHours < 24) {
      return _relativeHours(diff.inHours, locale);
    } else if (diff.inDays < 7) {
      return _relativeDays(diff.inDays, locale);
    } else {
      return formatDateShort(date, locale: locale);
    }
  }

  static String _relativeJustNow(String locale) {
    switch (locale) {
      case 'fr': return 'à l\'instant';
      case 'en': return 'just now';
      default: return 'الآن';
    }
  }

  static String _relativeMins(int mins, String locale) {
    switch (locale) {
      case 'fr': return 'il y a $mins min';
      case 'en': return '$mins min ago';
      default:
        if (mins == 1) return 'منذ دقيقة';
        if (mins == 2) return 'منذ دقيقتين';
        if (mins < 11) return 'منذ $mins دقائق';
        return 'منذ $mins دقيقة';
    }
  }

  static String _relativeHours(int hours, String locale) {
    switch (locale) {
      case 'fr': return 'il y a $hours h';
      case 'en': return '${hours}h ago';
      default:
        if (hours == 1) return 'منذ ساعة';
        if (hours == 2) return 'منذ ساعتين';
        if (hours < 11) return 'منذ $hours ساعات';
        return 'منذ $hours ساعة';
    }
  }

  static String _relativeDays(int days, String locale) {
    switch (locale) {
      case 'fr': return 'il y a $days j';
      case 'en': return '${days}d ago';
      default:
        if (days == 1) return 'أمس';
        if (days == 2) return 'منذ يومين';
        if (days < 11) return 'منذ $days أيام';
        return 'منذ $days يوم';
    }
  }

  // ── Phone number ──────────────────────────────────────────────────────────

  /// Formats an Algerian phone number to "0555 12 34 56" style.
  static String formatAlgerianPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    String digits = cleaned;

    // Strip country code if present
    if (digits.startsWith('213') && digits.length == 12) {
      digits = '0${digits.substring(3)}';
    } else if (digits.startsWith('00213') && digits.length == 14) {
      digits = '0${digits.substring(5)}';
    }

    if (digits.length == 10) {
      return '${digits.substring(0, 4)} ${digits.substring(4, 6)} '
          '${digits.substring(6, 8)} ${digits.substring(8, 10)}';
    }
    return phone; // return as-is if format unknown
  }

  // ── File size ─────────────────────────────────────────────────────────────

  /// Returns a human-readable file size string, e.g. "2.3 MB".
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  // ── Duration ──────────────────────────────────────────────────────────────

  /// Formats a [Duration] as "MM:SS" (e.g. for voice messages).
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // ── Rating ────────────────────────────────────────────────────────────────

  /// Formats a rating to one decimal place, e.g. "4.7".
  static String formatRating(double rating) =>
      rating.toStringAsFixed(rating == rating.roundToDouble() ? 0 : 1);

  // ── Distance ──────────────────────────────────────────────────────────────

  /// Formats a distance in metres to a display string.
  /// - <1 km  → "850 م"
  /// - ≥1 km  → "2.3 كم"
  static String formatDistance(double meters, {String locale = 'ar'}) {
    if (meters < 1000) {
      final m = meters.toStringAsFixed(0);
      return locale == 'ar' ? '$m م' : '${m}m';
    }
    final km = (meters / 1000).toStringAsFixed(1);
    return locale == 'ar' ? '$km كم' : '${km}km';
  }
}
