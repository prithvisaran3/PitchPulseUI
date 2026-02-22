import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';

import '../../providers/workspace_provider.dart';
import 'home_screen.dart';
// Replace ClubSelectScreen with the new CheckInScreen once it's created.
import '../check_in/check_in_screen.dart';
import '../settings/settings_screen.dart';

class ManagerShell extends StatefulWidget {
  const ManagerShell({super.key});

  @override
  State<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends State<ManagerShell>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fabCtrl;

  final _screens = const [
    HomeScreen(),
    CheckInScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fabCtrl.forward();

    // Only load if not already loaded — prevents re-triggering the fetch
    // that AuthGate already initiated on login.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wp = context.read<WorkspaceProvider>();
      if (wp.workspaceState == LoadState.idle) {
        wp.loadWorkspaces();
      }
    });
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody:
          true, // Allow content to flow under the transparent/floating nav bar
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: _FloatingNavBar(
              currentIndex: _currentIndex,
              onTap: (i) {
                HapticFeedback.selectionClick();
                setState(() => _currentIndex = i);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: Icons.home_rounded, label: 'Home'),
      _NavItem(icon: Icons.assignment_turned_in_rounded, label: 'Check-In'),
      _NavItem(icon: Icons.settings_rounded, label: 'Settings'),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
                color: AppColors.surfaceBorder.withValues(alpha: 0.5),
                width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isSelected = currentIndex == i;
              return _PillNavTile(
                item: item,
                isSelected: isSelected,
                onTap: () => onTap(i),
              );
            }).toList(),
          ),
        ),
      ),
    ).animate().slideY(
        begin: 1.5, end: 0, duration: 600.ms, curve: Curves.easeOutBack);
  }
}

class _PillNavTile extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _PillNavTile(
      {required this.item, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.textPrimary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? Border.all(color: AppColors.textPrimary.withValues(alpha: 0.3))
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 24,
              color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                item.label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.2, end: 0),
            ],
          ],
        ),
      ),
    );
  }
}
