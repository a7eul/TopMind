import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  final int activeIndex;

  const SideMenu({super.key, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 320,
      margin: const EdgeInsets.only(top: 60, right: 12, bottom: 60),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildNavItem(
            icon: Icons.person_outline,
            label: 'Профиль',
            index: 0,
            context: context,
            isActive: activeIndex == 0,
          ),
          const SizedBox(height: 24),
          _buildNavItem(
            icon: Icons.chat,
            label: 'Чаты',
            index: 1,
            context: context,
            isActive: activeIndex == 1,
          ),
          const SizedBox(height: 24),
          _buildNavItem(
            icon: Icons.calendar_today_outlined,
            label: 'Расписание',
            index: 2,
            context: context,
            isActive: activeIndex == 2,
          ),
          const SizedBox(height: 24),
          _buildNavItem(
            icon: Icons.settings_outlined,
            label: 'Настройки\n(будут)',
            index: 3,
            context: context,
            isActive: activeIndex == 3,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required BuildContext context,
    required bool isActive,
  }) {
    final Color color = isActive ? const Color(0xFFE53935) : Colors.grey;

    return GestureDetector(
      onTap: () {
        if (index == activeIndex) return;

        String route = '/main';
        if (index == 0) route = '/profile';
        if (index == 1) route = '/main';
        if (index == 2) route = '/schedule';
        if (index == 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Настройки будут позже!')),
          );
          return;
        }

        Navigator.pushReplacementNamed(context, route);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              height: 1.2,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}