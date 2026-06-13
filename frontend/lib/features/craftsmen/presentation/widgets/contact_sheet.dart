import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';

class ContactSheet extends StatelessWidget {
  const ContactSheet({
    super.key,
    required this.craftsmanId,
    required this.craftsmanName,
    this.phone,
    this.whatsapp,
  });

  final String craftsmanId;
  final String craftsmanName;
  final String? phone;
  final String? whatsapp;

  static Future<void> show(
    BuildContext context, {
    required String craftsmanId,
    required String craftsmanName,
    String? phone,
    String? whatsapp,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ContactSheet(
        craftsmanId: craftsmanId,
        craftsmanName: craftsmanName,
        phone: phone,
        whatsapp: whatsapp,
      ),
    );
  }

  Future<void> _launchPhone(BuildContext context) async {
    final raw = phone?.replaceAll(RegExp(r'[^0-9+]'), '') ?? '';
    if (raw.isEmpty) return;
    final uri = Uri.parse('tel:$raw');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر فتح تطبيق الاتصال')),
        );
      }
    }
  }

  Future<void> _launchWhatsApp(BuildContext context) async {
    final raw = (whatsapp ?? phone)?.replaceAll(RegExp(r'[^0-9+]'), '') ?? '';
    if (raw.isEmpty) return;
    // Normalise to international format for Algeria (+213)
    String number = raw;
    if (number.startsWith('0')) number = '213${number.substring(1)}';
    if (!number.startsWith('+')) number = '+$number';
    final uri = Uri.parse(
        'https://wa.me/${number.replaceAll('+', '')}?text=${Uri.encodeComponent('مرحباً، رأيت إعلانك على حرفي دار')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر فتح واتساب')),
        );
      }
    }
  }

  void _openChat(BuildContext context) {
    Navigator.pop(context);
    context.push(
      '${RouteNames.pathChatList}/$craftsmanId',
      extra: {'name': craftsmanName},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'تواصل مع $craftsmanName',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (phone != null && phone!.isNotEmpty)
            _ContactButton(
              icon: Icons.phone_rounded,
              label: 'اتصل الآن',
              subtitle: phone,
              color: AppColors.success,
              onTap: () => _launchPhone(context),
            ),
          if (phone != null && phone!.isNotEmpty)
            const SizedBox(height: 12),
          _ContactButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'واتساب',
            subtitle: 'أرسل رسالة واتساب',
            color: const Color(0xFF25D366),
            onTap: () => _launchWhatsApp(context),
          ),
          const SizedBox(height: 12),
          _ContactButton(
            icon: Icons.forum_outlined,
            label: 'دردشة داخل التطبيق',
            subtitle: 'تحدّث عبر حرفي دار',
            color: AppColors.primary,
            onTap: () => _openChat(context),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'إلغاء',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: color.withOpacity(0.7)),
            ],
          ),
        ),
      ),
    );
  }
}
