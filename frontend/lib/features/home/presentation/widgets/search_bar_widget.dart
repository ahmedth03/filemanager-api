import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({
    super.key,
    this.hintText = 'ابحث عن حرفي أو عقار...',
    this.onSearch,
    this.initialQuery,
  });

  final String hintText;
  final ValueChanged<String>? onSearch;
  final String? initialQuery;

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSubmit(String query) {
    if (query.trim().isEmpty) return;
    if (widget.onSearch != null) {
      widget.onSearch!(query.trim());
    } else {
      context.push(
        '${RouteNames.pathCraftsmenList}?q=${Uri.encodeComponent(query.trim())}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                textDirection: TextDirection.rtl,
                textInputAction: TextInputAction.search,
                onSubmitted: _onSubmit,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  fontFamily: 'Cairo',
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintTextDirection: TextDirection.rtl,
                  hintStyle: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 14,
                    fontFamily: 'Cairo',
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            // Mic button
            _IconBtn(
              icon: Icons.mic_none_rounded,
              onTap: () {
                // Voice search placeholder
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('البحث الصوتي قادم قريباً')),
                );
              },
            ),
            // Filter button
            _IconBtn(
              icon: Icons.tune_rounded,
              color: AppColors.accent,
              onTap: () {
                context.push('${RouteNames.pathCraftsmenList}?filter=true');
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.color = AppColors.textSecondary,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}
