import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/storage/preferences_storage.dart';
import '../../../../core/theme/app_colors.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _appVersion = '${info.version} (${info.buildNumber})');
      }
    } catch (_) {
      if (mounted) setState(() => _appVersion = '1.0.0');
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesStorageProvider);
    final currentLanguage = prefs.appLanguage;
    final currentTheme = prefs.themeMode;
    final notificationsEnabled = prefs.notificationsEnabled;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'الإعدادات',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Language ───────────────────────────────────────────────
            _SettingsSection(
              title: 'اللغة والمنطقة',
              children: [
                _SettingsItem(
                  icon: Icons.language,
                  iconColor: AppColors.primary,
                  title: 'لغة التطبيق',
                  trailing: _LanguageSelector(
                    current: currentLanguage,
                    onChanged: (lang) async {
                      await prefs.setAppLanguage(lang);
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Appearance ─────────────────────────────────────────────
            _SettingsSection(
              title: 'المظهر',
              children: [
                _SettingsItem(
                  icon: Icons.brightness_6_outlined,
                  iconColor: Colors.deepPurple,
                  title: 'وضع العرض',
                  trailing: _ThemeSelector(
                    current: currentTheme,
                    onChanged: (mode) async {
                      await prefs.setThemeMode(mode);
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Notifications ──────────────────────────────────────────
            _SettingsSection(
              title: 'الإشعارات',
              children: [
                _SettingsItem(
                  icon: Icons.notifications_outlined,
                  iconColor: Colors.orange,
                  title: 'تفعيل الإشعارات',
                  trailing: Switch(
                    value: notificationsEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (val) async {
                      await prefs.setNotificationsEnabled(val);
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── About ──────────────────────────────────────────────────
            _SettingsSection(
              title: 'حول التطبيق',
              children: [
                _SettingsItem(
                  icon: Icons.info_outline,
                  iconColor: AppColors.info,
                  title: 'حول حرفي دار',
                  onTap: () => _showAboutDialog(context),
                ),
                _buildDivider(),
                _SettingsItem(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: Colors.green,
                  title: 'سياسة الخصوصية',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'سيتم فتح سياسة الخصوصية قريباً',
                          style: TextStyle(fontFamily: 'Cairo'),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _SettingsItem(
                  icon: Icons.description_outlined,
                  iconColor: Colors.teal,
                  title: 'شروط الاستخدام',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'سيتم فتح شروط الاستخدام قريباً',
                          style: TextStyle(fontFamily: 'Cairo'),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _SettingsItem(
                  icon: Icons.star_outline,
                  iconColor: AppColors.accent,
                  title: 'قيّم التطبيق',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'شكراً لتقييمك!',
                          style: TextStyle(fontFamily: 'Cairo'),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _SettingsItem(
                  icon: Icons.tag,
                  iconColor: AppColors.textSecondary,
                  title: 'إصدار التطبيق',
                  trailing: Text(
                    _appVersion.isNotEmpty ? _appVersion : '...',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.only(right: 52),
      child: Divider(height: 1, color: AppColors.divider),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'حد',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'حرفي دار',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          content: const Text(
            'حرفي دار هو تطبيق جزائري يربط أصحاب المنازل بالحرفيين المحترفين، ويتيح البحث عن عقارات للكراء والبيع في جميع ولايات الجزائر.\n\nتواصل مباشر، بدون وسيط، بدون تعقيد.',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'حسناً',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Settings section container
// ---------------------------------------------------------------------------

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, right: 4),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Settings item row
// ---------------------------------------------------------------------------

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            trailing ??
                (onTap != null
                    ? const Icon(
                        Icons.chevron_left,
                        color: AppColors.textSecondary,
                        size: 18,
                      )
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Language selector
// ---------------------------------------------------------------------------

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.current, required this.onChanged});

  final String current;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LangChip(
          label: 'AR',
          isSelected: current == 'ar',
          onTap: () => onChanged('ar'),
        ),
        const SizedBox(width: 6),
        _LangChip(
          label: 'FR',
          isSelected: current == 'fr',
          onTap: () => onChanged('fr'),
        ),
      ],
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Theme selector
// ---------------------------------------------------------------------------

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.current, required this.onChanged});

  final String current;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: current,
        isDense: true,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
        items: const [
          DropdownMenuItem(
            value: 'light',
            child: Text('فاتح', style: TextStyle(fontFamily: 'Cairo')),
          ),
          DropdownMenuItem(
            value: 'dark',
            child: Text('داكن', style: TextStyle(fontFamily: 'Cairo')),
          ),
          DropdownMenuItem(
            value: 'system',
            child: Text('تلقائي', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
        onChanged: (val) {
          if (val != null) onChanged(val);
        },
      ),
    );
  }
}
