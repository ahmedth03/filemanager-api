/// Form-field validators for the HarfiDar application.
///
/// Every validator follows Flutter's `FormFieldValidator<String>` signature:
/// returns `null` if valid, or an error string if invalid.
///
/// Usage:
/// ```dart
/// TextFormField(
///   validator: Validators.compose([
///     Validators.required('Phone is required'),
///     Validators.algerianPhone,
///   ]),
/// )
/// ```
class Validators {
  Validators._();

  // ── Required ──────────────────────────────────────────────────────────────

  static String? Function(String?) required([String? message]) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return message ?? 'هذا الحقل مطلوب';
      }
      return null;
    };
  }

  // ── Email ─────────────────────────────────────────────────────────────────

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return null; // let required handle it
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'يرجى إدخال بريد إلكتروني صحيح';
    }
    return null;
  }

  // ── Algerian phone ────────────────────────────────────────────────────────
  //
  // Algeria country code: +213
  // Mobile networks: 05, 06, 07 (or +2135x, +2136x, +2137x)
  // Fixed lines:     021–xxx-xxxx, 030-xxx-xxxx, etc.

  static String? algerianPhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Accept: 05xxxxxxxx, 06xxxxxxxx, 07xxxxxxxx
    //         +2135xxxxxxxx, 00213 5xxxxxxxx, 0213 5xxxxxxxx
    final algerianMobileRegex = RegExp(
      r'^(?:\+213|00213|0213)?0?[5-7][0-9]{8}$',
    );
    // Landline: 02x, 03x, 04x prefix with 8 digits after 0
    final algerianLandlineRegex = RegExp(
      r'^(?:\+213|00213|0213)?0?[2-4][0-9]{8}$',
    );

    if (!algerianMobileRegex.hasMatch(cleaned) &&
        !algerianLandlineRegex.hasMatch(cleaned)) {
      return 'يرجى إدخال رقم هاتف جزائري صحيح (مثال: 0555123456)';
    }
    return null;
  }

  // ── Password ──────────────────────────────────────────────────────────────

  static String? password(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length < 8) {
      return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'كلمة المرور يجب أن تحتوي على حرف كبير واحد على الأقل';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'كلمة المرور يجب أن تحتوي على رقم واحد على الأقل';
    }
    return null;
  }

  static String? Function(String?) passwordConfirm(String password) {
    return (value) {
      if (value == null || value.isEmpty) return null;
      if (value != password) {
        return 'كلمتا المرور غير متطابقتين';
      }
      return null;
    };
  }

  // ── Name ──────────────────────────────────────────────────────────────────

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.trim().length < 3) {
      return 'الاسم يجب أن يكون 3 أحرف على الأقل';
    }
    if (value.trim().length > 60) {
      return 'الاسم يجب ألا يتجاوز 60 حرفًا';
    }
    return null;
  }

  // ── Price (Algerian Dinar) ────────────────────────────────────────────────

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.replaceAll(',', '').trim());
    if (parsed == null || parsed < 0) {
      return 'يرجى إدخال سعر صحيح';
    }
    if (parsed > 999_999_999) {
      return 'السعر المُدخل أكبر من الحد المسموح';
    }
    return null;
  }

  // ── Min length ────────────────────────────────────────────────────────────

  static String? Function(String?) minLength(int min, [String? message]) {
    return (value) {
      if (value == null || value.isEmpty) return null;
      if (value.length < min) {
        return message ?? 'يجب أن يكون الحقل $min أحرف على الأقل';
      }
      return null;
    };
  }

  // ── Max length ────────────────────────────────────────────────────────────

  static String? Function(String?) maxLength(int max, [String? message]) {
    return (value) {
      if (value == null || value.isEmpty) return null;
      if (value.length > max) {
        return message ?? 'يجب ألا يتجاوز الحقل $max حرفًا';
      }
      return null;
    };
  }

  // ── URL ───────────────────────────────────────────────────────────────────

  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final urlRegex = RegExp(
      r'^https?:\/\/'
      r'(([a-zA-Z0-9\-]+\.)+[a-zA-Z]{2,})'
      r'(\/[^\s]*)?$',
    );
    if (!urlRegex.hasMatch(value.trim())) {
      return 'يرجى إدخال رابط صحيح (يبدأ بـ http:// أو https://)';
    }
    return null;
  }

  // ── Compose multiple validators ───────────────────────────────────────────

  /// Runs validators in order and returns the first non-null error.
  static String? Function(String?) compose(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
