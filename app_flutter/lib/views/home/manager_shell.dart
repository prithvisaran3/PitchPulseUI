import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/workspace_provider.dart';
import 'home_screen.dart';
import '../onboarding/club_select_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';

class SquadScreen extends StatelessWidget {
  const SquadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Squad tab: reuse home but with full-width list layout (placeholder)
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Squad', style: AppTextStyles.displayMedium),
                  Text('Full roster · search & filter', style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            // Mirror homescreen squad grid with different layout (placeholder)
            const Expanded(child: HomeScreen()),
          ],
        ),
      ),
    );
  }
}

class ManagerShell extends StatefulWidget {
  const ManagerShell({super.key});

  @override
  State<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends State<ManagerShell> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fabCtrl;

  final _screens = const [
    HomeScreen(),
    ClubSelectScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fabCtrl.forward();

    // Preload workspace data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkspaceProvider>().loadWorkspaces();
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
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _PitchPulseNavBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = i);
        },
      ),
    );
  }
}

class _PitchPulseNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _PitchPulseNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: Icons.home_rounded, label: 'Home'),
      _NavItem(icon: Icons.sports_soccer_rounded, label: 'Club'),
      _NavItem(icon: Icons.bar_chart_rounded, label: 'Reports'),
      _NavItem(icon: Icons.settings_rounded, label: 'Settings'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.surfaceBorder, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isSelected = currentIndex == i;
              return _NavTile(
                item: item,
                isSelected: isSelected,
                onTap: () => onTap(i),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _NavTile extends StatefulWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTile({required this.item, required this.isSelected, required this.onTap});

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scale = Tween(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    if (widget.isSelected) _ctrl.value = 1;
  }

  @override
  void didUpdateWidget(_NavTile old) {
    super.didUpdateWidget(old);
    if (widget.isSelected != old.isSelected) {
      if (widget.isSelected) { _ctrl.forward(); }
      else { _ctrl.reverse(); }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _scale,
              builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
              child: AnimatedContainer(
                duration: AppConstants.animFast,
                width: 42, height: 32,
                decoration: BoxDecoration(
                  color: widget.isSelected ? AppColors.accent.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                ),
                child: Icon(
                  widget.item.icon,
                  size: 20,
                  color: widget.isSelected ? AppColors.accent : AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: AppConstants.animFast,
              style: AppTextStyles.caption.copyWith(
                color: widget.isSelected ? AppColors.accent : AppColors.textMuted,
                fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
              child: Text(widget.item.label),
            ),
          ],
        ),
      ),
    );
  }
}
