import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workspace_provider.dart';
import '../onboarding/club_select_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final workspace = context.watch<WorkspaceProvider>();
    final user = auth.appUser;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Settings', style: AppTextStyles.displayMedium)
                        .animate()
                        .fadeIn(duration: 400.ms),
                    const SizedBox(height: AppConstants.spacingL),

                    // Profile card
                    _ProfileCard(
                      email: user?.email ?? '',
                      role: user?.role ?? 'manager',
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),

                    const SizedBox(height: AppConstants.spacingL),

                    // Workspace section
                    _SectionTitle(title: 'Active Workspace')
                        .animate()
                        .fadeIn(delay: 150.ms),
                    const SizedBox(height: 10),
                    if (workspace.activeWorkspace != null) ...[
                      _WorkspaceCard(
                        clubName: workspace.activeWorkspace!.clubName,
                        status: workspace.activeWorkspace!.status,
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ClubSelectScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated
                                .withValues(alpha: 0.5),
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusL),
                            border: Border.all(color: AppColors.surfaceBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded,
                                  color: AppColors.textPrimary, size: 18),
                              const SizedBox(width: 12),
                              Text('Search & Change Club',
                                  style: AppTextStyles.labelMedium),
                              const Spacer(),
                              const Icon(Icons.chevron_right_rounded,
                                  color: AppColors.textMuted, size: 20),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 220.ms),
                    ],

                    const SizedBox(height: AppConstants.spacingL),

                    // Demo mode
                    _SectionTitle(title: 'Developer')
                        .animate()
                        .fadeIn(delay: 250.ms),
                    const SizedBox(height: 10),
                    _DemoModeToggle(
                      enabled: auth.demoMode,
                      onToggle: (v) => auth.setDemoMode(v),
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: AppConstants.spacingL),

                    // App info
                    _SectionTitle(title: 'App').animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 10),
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      label: 'Version',
                      subtitle: '${AppConstants.appVersion} · Phase 1 Demo',
                    ).animate().fadeIn(delay: 450.ms),
                    const SizedBox(height: 8),
                    _SettingsTile(
                      icon: Icons.sports_soccer,
                      label: 'Data Provider',
                      subtitle: 'API-Football (placeholder)',
                    ).animate().fadeIn(delay: 500.ms),
                    const SizedBox(height: 8),
                    _SettingsTile(
                      icon: Icons.cloud_outlined,
                      label: 'Vector DB',
                      subtitle: 'Actian VectorAI (backend integration pending)',
                    ).animate().fadeIn(delay: 550.ms),
                    const SizedBox(height: 8),
                    _SettingsTile(
                      icon: Icons.auto_awesome_outlined,
                      label: 'AI Engine',
                      subtitle: 'Gemini Pro (backend integration pending)',
                    ).animate().fadeIn(delay: 600.ms),

                    const SizedBox(height: AppConstants.spacingL),

                    // Sign out
                    _SignOutButton(onTap: () => auth.signOut())
                        .animate()
                        .fadeIn(delay: 650.ms),

                    const SizedBox(height: AppConstants.spacingXXL),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String email;
  final String role;
  const _ProfileCard({required this.email, required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surface, AppColors.surfaceElevated],
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: isAdmin
                  ? AppColors.gradientHigh
                  : const LinearGradient(
                      colors: [Color(0xFFFFFFFF), Color(0xFFD4D4D4)]),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                email.isNotEmpty ? email[0].toUpperCase() : 'U',
                style: AppTextStyles.displaySmall.copyWith(color: Colors.black),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(email,
                    style: AppTextStyles.labelLarge,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:
                          (isAdmin ? AppColors.riskHigh : AppColors.textPrimary)
                              .withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusCircle),
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(
                        color: isAdmin
                            ? AppColors.riskHigh
                            : AppColors.textPrimary,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceCard extends StatelessWidget {
  final String clubName;
  final String status;
  const _WorkspaceCard({required this.clubName, required this.status});

  @override
  Widget build(BuildContext context) {
    final isApproved = status == 'approved';
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                clubName.substring(0, 2).toUpperCase(),
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(clubName, style: AppTextStyles.headlineSmall),
                Text('Workspace · $status', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Icon(
            isApproved
                ? Icons.check_circle_rounded
                : Icons.hourglass_top_rounded,
            color: isApproved ? AppColors.riskLow : AppColors.riskMed,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) => Text(
        title.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textMuted,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w700,
        ),
      );
}

class _DemoModeToggle extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onToggle;

  const _DemoModeToggle({required this.enabled, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(
          color: enabled
              ? AppColors.riskMed.withValues(alpha: 0.4)
              : AppColors.surfaceBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.riskMed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.developer_mode_rounded,
                color: AppColors.riskMed, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Demo Mode', style: AppTextStyles.labelMedium),
                Text('Shows "Simulate FT Update" button on Home',
                    style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onToggle,
            activeThumbColor: AppColors.riskMed,
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;

  const _SettingsTile(
      {required this.icon, required this.label, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.labelMedium),
                Text(subtitle,
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignOutButton extends StatefulWidget {
  final VoidCallback onTap;
  const _SignOutButton({required this.onTap});

  @override
  State<_SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends State<_SignOutButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) =>
            Transform.scale(scale: 1.0 - _ctrl.value * 0.03, child: child),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.riskHigh.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            border:
                Border.all(color: AppColors.riskHigh.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout_rounded,
                  color: AppColors.riskHigh, size: 18),
              const SizedBox(width: 10),
              Text('Sign Out',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.riskHigh)),
            ],
          ),
        ),
      ),
    );
  }
}
