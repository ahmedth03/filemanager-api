import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';

class _CategoryItem {
  const _CategoryItem({
    required this.labelAr,
    required this.specialtyKey,
    required this.icon,
    required this.color,
    this.count = 0,
  });

  final String labelAr;
  final String specialtyKey;
  final IconData icon;
  final Color color;
  final int count;
}

const _categories = [
  _CategoryItem(
    labelAr: 'سباك',
    specialtyKey: 'plumber',
    icon: Icons.water_drop_outlined,
    color: AppColors.plumberColor,
    count: 124,
  ),
  _CategoryItem(
    labelAr: 'كهربائي',
    specialtyKey: 'electrician',
    icon: Icons.electric_bolt_outlined,
    color: AppColors.electricianColor,
    count: 98,
  ),
  _CategoryItem(
    labelAr: 'نجار',
    specialtyKey: 'carpenter',
    icon: Icons.carpenter,
    color: AppColors.carpenterColor,
    count: 76,
  ),
  _CategoryItem(
    labelAr: 'دهان',
    specialtyKey: 'painter',
    icon: Icons.format_paint_outlined,
    color: AppColors.painterColor,
    count: 85,
  ),
  _CategoryItem(
    labelAr: 'بناء',
    specialtyKey: 'mason',
    icon: Icons.foundation,
    color: AppColors.masonColor,
    count: 62,
  ),
  _CategoryItem(
    labelAr: 'تقني تكييف',
    specialtyKey: 'acTech',
    icon: Icons.ac_unit_outlined,
    color: AppColors.tillerColor,
    count: 54,
  ),
  _CategoryItem(
    labelAr: 'حداد',
    specialtyKey: 'welder',
    icon: Icons.hardware_outlined,
    color: Color(0xFFB7950B),
    count: 41,
  ),
  _CategoryItem(
    labelAr: 'عامل نظافة',
    specialtyKey: 'cleaner',
    icon: Icons.cleaning_services_outlined,
    color: Color(0xFF117A65),
    count: 93,
  ),
];

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        return _CategoryTile(category: cat);
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});
  final _CategoryItem category;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push(
          '${RouteNames.pathCraftsmenList}?specialty=${category.specialtyKey}',
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: category.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(category.icon, color: category.color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            category.labelAr,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Cairo',
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (category.count > 0)
            Text(
              '${category.count}',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
            ),
        ],
      ),
    );
  }
}
