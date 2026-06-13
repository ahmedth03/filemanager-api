import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';

// ---------------------------------------------------------------------------
// ReportScreen
// ---------------------------------------------------------------------------

/// Screen that allows users to report a listing, craftsman, or user.
///
/// [targetId] — the UUID of the entity being reported.
/// [targetType] — one of 'listing', 'craftsman', or 'user'.
class ReportScreen extends StatefulWidget {
  const ReportScreen({
    super.key,
    required this.targetId,
    required this.targetType,
  });

  final String targetId;
  final String targetType;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // ── Reason options ─────────────────────────────────────────────────────────

  static const List<_ReportReason> _reasons = [
    _ReportReason(key: 'MISLEADING', label: 'محتوى مضلل'),
    _ReportReason(key: 'INAPPROPRIATE', label: 'محتوى غير لائق'),
    _ReportReason(key: 'FRAUD', label: 'احتيال'),
    _ReportReason(key: 'PRIVACY', label: 'انتهاك الخصوصية'),
    _ReportReason(key: 'VIOLENCE', label: 'محتوى عنيف'),
    _ReportReason(key: 'OTHER', label: 'أخرى'),
  ];

  String? _selectedReasonKey;
  final TextEditingController _descController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_selectedReasonKey == null) {
      setState(() => _errorMessage = 'يرجى اختيار سبب البلاغ');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final body = {
        'targetId': widget.targetId,
        'type': widget.targetType.toUpperCase(),
        'reason': _selectedReasonKey,
        'description': _descController.text.trim().isNotEmpty
            ? _descController.text.trim()
            : null,
      };
      // Remove null description key
      body.removeWhere((_, v) => v == null);

      final response = await http
          .post(
            Uri.parse('/api/v1/reports'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'تم إرسال البلاغ بنجاح',
              style: TextStyle(fontFamily: 'Cairo'),
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.of(context).pop();
      } else {
        final decoded =
            jsonDecode(response.body) as Map<String, dynamic>? ?? {};
        final msg = decoded['message'] as String? ?? 'فشل إرسال البلاغ';
        setState(() => _errorMessage = msg);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'حدث خطأ، يرجى المحاولة مجدداً');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'الإبلاغ عن محتوى',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header card ─────────────────────────────────────────────
              _buildHeaderCard(),

              const SizedBox(height: 24),

              // ── Reason selection ─────────────────────────────────────────
              _buildSectionTitle('سبب البلاغ *'),
              const SizedBox(height: 12),
              _buildReasonList(),

              // ── Reason error ─────────────────────────────────────────────
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                _buildErrorBanner(_errorMessage!),
              ],

              const SizedBox(height: 24),

              // ── Description ──────────────────────────────────────────────
              _buildSectionTitle('وصف إضافي (اختياري)'),
              const SizedBox(height: 8),
              _buildDescriptionField(),

              const SizedBox(height: 32),

              // ── Submit ────────────────────────────────────────────────────
              AppButton(
                label: 'إرسال البلاغ',
                onPressed: _isLoading ? null : _submit,
                isLoading: _isLoading,
                size: AppButtonSize.large,
              ),

              const SizedBox(height: 16),

              const Text(
                'يتم مراجعة البلاغات من قِبَل فريق الإشراف خلال 24 ساعة.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AppColors.textHint,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────────────────────

  Widget _buildHeaderCard() {
    final typeLabel = _localizedType(widget.targetType);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.flag_rounded, color: AppColors.warning, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'أنت على وشك الإبلاغ عن $typeLabel. يرجى اختيار السبب المناسب.',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildReasonList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(_reasons.length, (index) {
          final reason = _reasons[index];
          final isSelected = _selectedReasonKey == reason.key;
          final isLast = index == _reasons.length - 1;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedReasonKey = reason.key;
                _errorMessage = null;
              });
            },
            borderRadius: BorderRadius.vertical(
              top: index == 0 ? const Radius.circular(14) : Radius.zero,
              bottom: isLast ? const Radius.circular(14) : Radius.zero,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.06)
                    : Colors.transparent,
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(color: AppColors.border, width: 0.5),
                      ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Radio indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1.5,
                      ),
                      color: isSelected ? AppColors.primary : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      reason.label,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _descController,
        textDirection: TextDirection.rtl,
        maxLines: 5,
        minLines: 3,
        maxLength: 500,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          color: AppColors.textPrimary,
          height: 1.6,
        ),
        decoration: const InputDecoration(
          hintText: 'اكتب تفاصيل إضافية تساعد فريق الإشراف في مراجعة البلاغ...',
          hintStyle: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            color: AppColors.textHint,
          ),
          contentPadding: EdgeInsets.all(14),
          border: InputBorder.none,
          counterStyle: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            color: AppColors.textHint,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _localizedType(String type) {
    switch (type.toLowerCase()) {
      case 'craftsman':
        return 'حرفي';
      case 'user':
        return 'مستخدم';
      case 'listing':
      default:
        return 'إعلان عقاري';
    }
  }
}

// ---------------------------------------------------------------------------
// Data class
// ---------------------------------------------------------------------------

class _ReportReason {
  const _ReportReason({required this.key, required this.label});

  final String key;
  final String label;
}
