import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/workspace_model.dart';
import '../../providers/workspace_provider.dart';

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkspaceProvider>().loadPendingRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkspaceProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spacingL,
                AppConstants.spacingL,
                AppConstants.spacingL,
                AppConstants.spacingM,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.admin_panel_settings_rounded,
                            color: AppColors.textPrimary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Admin Panel',
                              style: AppTextStyles.displaySmall),
                          Text('Workspace Requests',
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

            // Stats bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
              child: Row(
                children: [
                  _StatChip(
                    label: 'Pending',
                    value: provider.pendingRequests.length.toString(),
                    color: AppColors.riskMed,
                  ),
                  const SizedBox(width: 10),
                  _StatChip(
                      label: 'Approved Today',
                      value: '3',
                      color: AppColors.riskLow),
                  const SizedBox(width: 10),
                  _StatChip(
                      label: 'Total Clubs',
                      value: '12',
                      color: AppColors.textPrimary),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

            const SizedBox(height: AppConstants.spacingM),

            // List
            Expanded(
              child: provider.adminState == LoadState.loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.accent))
                  : provider.pendingRequests.isEmpty
                      ? _EmptyState()
                      : RefreshIndicator(
                          color: AppColors.textPrimary,
                          backgroundColor: AppColors.surface,
                          onRefresh: () => provider.loadPendingRequests(),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.spacingL),
                            itemCount: provider.pendingRequests.length,
                            itemBuilder: (ctx, i) => _RequestCard(
                              request: provider.pendingRequests[i],
                              index: i,
                              onApprove: () => provider.approveWorkspace(
                                  provider.pendingRequests[i].id),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTextStyles.monoMedium.copyWith(color: color)),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  final WorkspaceModel request;
  final int index;
  final VoidCallback onApprove;

  const _RequestCard(
      {required this.request, required this.index, required this.onApprove});

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _approving = false;

  Future<void> _approve() async {
    setState(() => _approving = true);
    await Future.delayed(const Duration(milliseconds: 800));
    widget.onApprove();
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final dateStr = req.createdAt != null
        ? DateFormat('MMM d, h:mm a').format(req.createdAt!)
        : 'Just now';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Club avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.riskMed.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    req.clubName.substring(0, 2).toUpperCase(),
                    style: AppTextStyles.headlineSmall
                        .copyWith(color: AppColors.riskMed),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(req.clubName, style: AppTextStyles.headlineMedium),
                    Text('Requested $dateStr', style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.riskMed.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusCircle),
                  border: Border.all(color: AppColors.riskMed.withValues(alpha: 0.3)),
                ),
                child: Text('PENDING',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.riskMed)),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Details
          Row(
            children: [
              _DetailItem(
                  icon: Icons.person_outline,
                  label: 'Manager ID',
                  value: req.managerId.substring(0, 12) + '...'),
              const SizedBox(width: 20),
              _DetailItem(
                  icon: Icons.sports_soccer,
                  label: 'Club ID',
                  value: req.clubId),
            ],
          ),

          const SizedBox(height: 16),

          // Approve button
          GestureDetector(
            onTap: _approving ? null : _approve,
            child: AnimatedContainer(
              duration: AppConstants.animFast,
              height: 44,
              decoration: BoxDecoration(
                gradient: _approving ? null : AppColors.gradientLow,
                color: _approving ? AppColors.surfaceElevated : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: _approving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: AppColors.riskLow, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline,
                              color: Colors.black, size: 16),
                          const SizedBox(width: 8),
                          Text('Approve Workspace',
                              style: AppTextStyles.labelMedium
                                  .copyWith(color: Colors.black)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: widget.index * 80))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                Text(value,
                    style: AppTextStyles.bodySmall,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.riskLow.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inbox_rounded,
                color: AppColors.riskLow, size: 36),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 20),
          Text('All caught up!', style: AppTextStyles.headlineMedium)
              .animate(delay: 150.ms)
              .fadeIn(),
          const SizedBox(height: 8),
          Text('No pending workspace requests', style: AppTextStyles.bodyMedium)
              .animate(delay: 250.ms)
              .fadeIn(),
        ],
      ),
    );
  }
}
