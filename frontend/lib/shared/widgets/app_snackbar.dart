import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Brand colours (inline)
// ---------------------------------------------------------------------------
class _C {
  static const Color primary = Color(0xFF1B4F72);
  static const Color accent = Color(0xFFF39C12);
  static const Color white = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFDC3545);
  static const Color success = Color(0xFF28A745);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF17A2B8);
  static const Color textDark = Color(0xFF212529);
}

enum _SnackType { success, error, info, warning }

// ---------------------------------------------------------------------------
// AppSnackbar
// ---------------------------------------------------------------------------
class AppSnackbar {
  AppSnackbar._();

  // ------------------------------------------------------------------ public

  static void showSuccess(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _show(
      context,
      type: _SnackType.success,
      message: message,
      title: title,
      duration: duration,
      action: action,
    );
  }

  static void showError(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    _show(
      context,
      type: _SnackType.error,
      message: message,
      title: title,
      duration: duration,
      action: action,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _show(
      context,
      type: _SnackType.info,
      message: message,
      title: title,
      duration: duration,
      action: action,
    );
  }

  static void showWarning(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _show(
      context,
      type: _SnackType.warning,
      message: message,
      title: title,
      duration: duration,
      action: action,
    );
  }

  static void dismiss(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  // ------------------------------------------------------------------ private

  static void _show(
    BuildContext context, {
    required _SnackType type,
    required String message,
    String? title,
    required Duration duration,
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final Color bgColor = _bgColor(type);
    final Color iconColor = _iconColor(type);
    final IconData icon = _icon(type);

    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        behavior: SnackBarBehavior.floating,
        content: _SnackbarContent(
          type: type,
          message: message,
          title: title,
          bgColor: bgColor,
          iconColor: iconColor,
          icon: icon,
          action: action,
        ),
      ),
    );
  }

  static Color _bgColor(_SnackType type) {
    switch (type) {
      case _SnackType.success:
        return _C.success;
      case _SnackType.error:
        return _C.error;
      case _SnackType.info:
        return _C.info;
      case _SnackType.warning:
        return _C.warning;
    }
  }

  static Color _iconColor(_SnackType type) {
    if (type == _SnackType.warning) return _C.textDark;
    return _C.white;
  }

  static IconData _icon(_SnackType type) {
    switch (type) {
      case _SnackType.success:
        return Icons.check_circle_rounded;
      case _SnackType.error:
        return Icons.error_rounded;
      case _SnackType.info:
        return Icons.info_rounded;
      case _SnackType.warning:
        return Icons.warning_rounded;
    }
  }
}

// ---------------------------------------------------------------------------
// _SnackbarContent – the actual visual widget
// ---------------------------------------------------------------------------
class _SnackbarContent extends StatelessWidget {
  const _SnackbarContent({
    required this.type,
    required this.message,
    this.title,
    required this.bgColor,
    required this.iconColor,
    required this.icon,
    this.action,
  });

  final _SnackType type;
  final String message;
  final String? title;
  final Color bgColor;
  final Color iconColor;
  final IconData icon;
  final SnackBarAction? action;

  @override
  Widget build(BuildContext context) {
    final Color textColor =
        type == _SnackType.warning ? _C.textDark : _C.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null && title!.isNotEmpty) ...[
                  Text(
                    title!,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message,
                  style: TextStyle(
                    color: textColor.withOpacity(title != null ? 0.9 : 1.0),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Action button
          if (action != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: action!.onPressed,
              style: TextButton.styleFrom(
                foregroundColor: textColor,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                action!.label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
