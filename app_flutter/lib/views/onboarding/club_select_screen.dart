import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/workspace_model.dart';
import '../../providers/workspace_provider.dart';
import '../../widgets/common/pulse_loader.dart';

class ClubSelectScreen extends StatefulWidget {
  const ClubSelectScreen({super.key});

  @override
  State<ClubSelectScreen> createState() => _ClubSelectScreenState();
}

class _ClubSelectScreenState extends State<ClubSelectScreen> {
  final _searchCtrl = TextEditingController();
  List<ClubSearchResult> _results = [];
  bool _searching = false;
  ClubSearchResult? _selected;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    _doSearch('');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _doSearch(String q) async {
    setState(() => _searching = true);
    final provider = context.read<WorkspaceProvider>();
    final results = await provider.searchClubs(q);
    if (mounted)
      setState(() {
        _results = results;
        _searching = false;
      });
  }

  Future<void> _requestAccess() async {
    if (_selected == null) return;
    setState(() => _requesting = true);

    debugPrint(
        '🟡 [ClubSelect] Requesting access for: ${_selected!.name} (providerTeamId: ${_selected!.providerTeamId})');

    try {
      await context.read<WorkspaceProvider>().requestAccess(
            _selected!.id,
            _selected!.name,
            providerTeamId: _selected!.providerTeamId,
          );
      // AuthGate will automatically route to home if workspace is now set.
      // If still on this screen after the call, workspace creation failed.
      if (mounted &&
          context.read<WorkspaceProvider>().activeWorkspace == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Could not connect to backend. Check your connection and try again.'),
            backgroundColor: Color(0xFFE53935),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
      }
    }

    if (mounted) setState(() => _requesting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (Navigator.canPop(context))
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppConstants.spacingM),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppColors.textPrimary),
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  Text('Select Club', style: AppTextStyles.displayMedium)
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: -0.1),
                  const SizedBox(height: 6),
                  Text(
                    'Search for your club to set up your workspace',
                    style: AppTextStyles.bodyMedium,
                  ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
              child: TextField(
                controller: _searchCtrl,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Search clubs...',
                  prefixIcon: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: PulseLoader(color: AppColors.textPrimary),
                        )
                      : const Icon(Icons.search,
                          color: AppColors.textMuted, size: 20),
                ),
                onChanged: (v) {
                  Future.delayed(const Duration(milliseconds: 400), () {
                    if (_searchCtrl.text == v) _doSearch(v);
                  });
                },
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
            ),

            const SizedBox(height: AppConstants.spacingM),

            // Results list — always visible
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingL),
                itemCount: _results.length,
                itemBuilder: (context, i) {
                  final club = _results[i];
                  final isSelected = _selected?.id == club.id;
                  return _ClubCard(
                    club: club,
                    isSelected: isSelected,
                    index: i,
                    onTap: () =>
                        setState(() => _selected = isSelected ? null : club),
                  );
                },
              ),
            ),

            // Bottom button — shown when a club is selected
            if (_selected != null)
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacingL),
                child: _RequestButton(
                  clubName: _selected!.name,
                  loading: _requesting,
                  onTap: _requestAccess,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ClubCard extends StatelessWidget {
  final ClubSearchResult club;
  final bool isSelected;
  final int index;
  final VoidCallback onTap;

  const _ClubCard({
    required this.club,
    required this.isSelected,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.animFast,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.textPrimary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          border: Border.all(
            color: isSelected ? AppColors.textPrimary : AppColors.surfaceBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Crest placeholder
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Center(
                child: Text(
                  club.name.substring(0, 2).toUpperCase(),
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.textPrimary),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(club.name, style: AppTextStyles.headlineSmall),
                  if (club.country != null)
                    Text(
                        '${club.country}${club.founded != null ? ' · Est. ${club.founded}' : ''}',
                        style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                    color: AppColors.textPrimary, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 14, color: Colors.black),
              ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 50))
        .fadeIn(duration: 350.ms)
        .slideX(begin: 0.05, end: 0);
  }
}

class _RequestButton extends StatefulWidget {
  final String clubName;
  final bool loading;
  final VoidCallback onTap;

  const _RequestButton(
      {required this.clubName, required this.loading, required this.onTap});

  @override
  State<_RequestButton> createState() => _RequestButtonState();
}

class _RequestButtonState extends State<_RequestButton>
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
        if (!widget.loading) widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(
          scale: 1.0 - _ctrl.value * 0.03,
          child: child,
        ),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.textPrimary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: PulseLoader(color: AppColors.bg),
                  )
                : Text(
                    'Request Access · ${widget.clubName}',
                    style:
                        AppTextStyles.labelLarge.copyWith(color: AppColors.bg),
                  ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.5, end: 0, curve: Curves.elasticOut);
  }
}
