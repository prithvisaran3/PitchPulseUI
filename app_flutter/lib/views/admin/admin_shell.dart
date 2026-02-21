import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import 'admin_requests_screen.dart';
import '../settings/settings_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  final _screens = const [
    AdminRequestsScreen(),
    _AdminWorkspacesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.surfaceBorder)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _AdminNavTile(icon: Icons.approval_rounded, label: 'Requests', isSelected: _currentIndex == 0, onTap: () { HapticFeedback.selectionClick(); setState(() => _currentIndex = 0); }),
                _AdminNavTile(icon: Icons.domain_rounded, label: 'Workspaces', isSelected: _currentIndex == 1, onTap: () { HapticFeedback.selectionClick(); setState(() => _currentIndex = 1); }),
                _AdminNavTile(icon: Icons.settings_rounded, label: 'Settings', isSelected: _currentIndex == 2, onTap: () { HapticFeedback.selectionClick(); setState(() => _currentIndex = 2); }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AdminNavTile({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: AppConstants.animFast,
            width: 42, height: 32,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.riskHigh.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: isSelected ? AppColors.riskHigh : AppColors.textMuted),
          ),
          const SizedBox(height: 3),
          Text(label, style: AppTextStyles.caption.copyWith(
            color: isSelected ? AppColors.riskHigh : AppColors.textMuted,
          )),
        ],
      ),
    );
  }
}

class _AdminWorkspacesScreen extends StatelessWidget {
  const _AdminWorkspacesScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Approved Workspaces', style: AppTextStyles.displayMedium),
              const SizedBox(height: 8),
              Text('All active club workspaces', style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppConstants.spacingL),
              _ApprovedCard(clubName: 'Real Madrid', manager: 'manager@realmadrid.com', since: '3 days ago'),
              _ApprovedCard(clubName: 'Manchester City', manager: 'coach@mancity.com', since: '1 week ago'),
              _ApprovedCard(clubName: 'Bayern Munich', manager: 'trainer@fcbayern.com', since: '2 weeks ago'),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApprovedCard extends StatelessWidget {
  final String clubName;
  final String manager;
  final String since;

  const _ApprovedCard({required this.clubName, required this.manager, required this.since});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.riskLow.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.riskLow.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(clubName.substring(0, 2),
                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.riskLow)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(clubName, style: AppTextStyles.headlineSmall),
                Text(manager, style: AppTextStyles.bodySmall, overflow: TextOverflow.ellipsis),
                Text('Active since $since', style: AppTextStyles.caption),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppColors.riskLow, size: 18),
        ],
      ),
    );
  }
}
