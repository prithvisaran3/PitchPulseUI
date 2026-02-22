import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/fixture_model.dart';
import '../../models/player_model.dart';
import '../../providers/workspace_provider.dart';
import '../../widgets/common/pulse_loader.dart';
import '../../widgets/home/player_xi_bottom_sheet.dart';

class SuggestedXIScreen extends StatefulWidget {
  final FixtureModel fixture;
  const SuggestedXIScreen({super.key, required this.fixture});

  @override
  State<SuggestedXIScreen> createState() => _SuggestedXIScreenState();
}

class _SuggestedXIScreenState extends State<SuggestedXIScreen> {
  String _currentFormation = '4-3-3';
  String _aiTacticalAnalysis = '';
  List<PlayerModel> _startingXI = [];
  List<PlayerModel> _bench = [];
  Map<String, String> _playerRationales = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFromAI();
  }

  Future<void> _loadFromAI() async {
    final workspaceProvider = context.read<WorkspaceProvider>();
    final squad = List<PlayerModel>.from(workspaceProvider.squad);
    final wsId =
        workspaceProvider.activeWorkspace?.id ?? AppConstants.demoWorkspaceId;

    final clubName = workspaceProvider.activeWorkspace?.clubName ?? 'My Club';
    final isHome = widget.fixture.homeTeam == clubName;
    final opponent = isHome ? widget.fixture.awayTeam : widget.fixture.homeTeam;

    try {
      // Deduplicate squad first so we send clean data to the AI.
      final seenSquadIds = <String>{};
      final cleanSquad =
          squad.where((p) => seenSquadIds.add(p.id)).toList();

      final payload = {
        'opponent': opponent,
        'match_context':
            '${isHome ? "Home" : "Away"}, ${widget.fixture.competition}',
        'available_squad': cleanSquad
            .map((p) => {
                  'id': p.id,
                  'name': p.name,
                  'position': _toApiPosition(p.position),
                  'readiness': p.readinessScore.round(),
                  'risk': p.riskScore.round(),
                })
            .toList(),
      };

      final data = await workspaceProvider.generateSuggestedXi(wsId, payload);

      final bestFormation = data['best_formation'] as String? ?? '4-3-3';
      final analysis = data['tactical_analysis'] as String? ?? '';
      final xiIds = (data['starting_xi_ids'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList();
      final benchIdsFromApi = (data['bench_ids'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toSet();
      final rationales =
          (data['player_rationales'] as Map<String, dynamic>? ?? {})
              .map((k, v) => MapEntry(k, v.toString()));

      // Deduplicate squad by ID before building maps.
      final seenIds = <String>{};
      final uniqueSquad =
          squad.where((p) => seenIds.add(p.id)).toList();

      final idToPlayer = {for (var p in uniqueSquad) p.id: p};
      final aiXI = xiIds
          .where((id) => idToPlayer.containsKey(id))
          .map((id) => idToPlayer[id]!)
          .toList();

      if (aiXI.length >= 7) {
        final xiIdSet = {for (var p in aiXI) p.id};
        _currentFormation = bestFormation;
        _aiTacticalAnalysis = analysis;
        _startingXI = aiXI.take(11).toList();

        // Prefer bench_ids from AI if provided; otherwise exclude XI by ID.
        if (benchIdsFromApi != null && benchIdsFromApi.isNotEmpty) {
          _bench = benchIdsFromApi
              .where((id) => idToPlayer.containsKey(id) && !xiIdSet.contains(id))
              .map((id) => idToPlayer[id]!)
              .toList()
            ..sort((a, b) => b.readinessScore.compareTo(a.readinessScore));
        } else {
          _bench = uniqueSquad
              .where((p) => !xiIdSet.contains(p.id))
              .toList()
            ..sort((a, b) => b.readinessScore.compareTo(a.readinessScore));
        }
        _playerRationales = rationales;
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      // AI returned too few valid IDs — fall through to local builder.
    } catch (_) {
      // Timeout, network error, or bad response — fall through.
    }

    // ── Local fallback: pick best XI by readiness & position ─────────────────
    _buildLocalXI(squad, opponent);
    if (mounted) setState(() => _isLoading = false);
  }

  /// Maps a full position name to the short code expected by the API.
  String _toApiPosition(String pos) {
    final s = pos.toLowerCase();
    if (s.contains('goalkeeper') || s == 'gk') return 'GK';
    if (s.contains('defender') || s.contains('back') ||
        s == 'def' || s == 'cb' || s == 'lb' || s == 'rb') return 'DEF';
    if (s.contains('midfield') || s == 'mid' ||
        s == 'cm' || s == 'dm' || s == 'am') return 'MID';
    return 'FW';
  }

  /// Builds a complete starting XI from the squad using readiness scores,
  /// filling positions as best as possible in a 4-3-3 shape.
  /// Uses player IDs for deduplication — PlayerModel has no == override.
  void _buildLocalXI(List<PlayerModel> squad, String opponent) {
    // Deduplicate the squad itself first (API can return the same player twice).
    final seen = <String>{};
    final unique = squad.where((p) => seen.add(p.id)).toList()
      ..sort((a, b) => b.readinessScore.compareTo(a.readinessScore));

    final xiIds = <String>{};
    final xi    = <PlayerModel>[];

    void tryAdd(PlayerModel p) {
      if (!xiIds.contains(p.id) && xi.length < 11) {
        xiIds.add(p.id);
        xi.add(p);
      }
    }

    bool pos(PlayerModel p, List<String> keywords) {
      final s = p.position.toLowerCase();
      return keywords.any((k) => s.contains(k));
    }

    final gks  = unique.where((p) => pos(p, ['goalkeeper', 'gk'])).toList();
    final defs = unique.where((p) => pos(p, ['defender', 'back', ' cb', 'lb', 'rb', 'def']) && !pos(p, ['goalkeeper', 'gk'])).toList();
    final mids = unique.where((p) => pos(p, ['midfielder', 'midfield', 'mid', 'cm', 'dm', 'am']) && !pos(p, ['goalkeeper', 'gk', 'defender', 'back'])).toList();
    final fwds = unique.where((p) => pos(p, ['forward', 'attacker', 'winger', 'striker', 'fw', 'lw', 'rw', 'cf', 'st']) && !pos(p, ['goalkeeper', 'gk', 'defender', 'back', 'midfield'])).toList();

    // 1 GK → 4 DEF → 3 MID → 3 FWD
    gks.take(1).forEach(tryAdd);
    defs.take(4).forEach(tryAdd);
    mids.take(3).forEach(tryAdd);
    fwds.take(3).forEach(tryAdd);

    // Fill any remaining slots with the highest-readiness players not yet picked.
    if (xi.length < 11) {
      unique.where((p) => !xiIds.contains(p.id)).take(11 - xi.length).forEach(tryAdd);
    }

    _currentFormation = '4-3-3';
    _aiTacticalAnalysis =
        'Lineup built from current readiness data — players selected for '
        'peak physical availability ahead of the match vs $opponent.';
    _startingXI = xi;
    // Bench: everyone not in the starting XI, deduplicated by ID.
    _bench = unique.where((p) => !xiIds.contains(p.id)).toList();
  }

  void _showPlayerSheet(PlayerModel player) {
    HapticFeedback.lightImpact();
    final rationale = _playerRationales[player.id];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          PlayerXIBottomSheet(player: player, aiRationale: rationale),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clubName =
        context.read<WorkspaceProvider>().activeWorkspace?.clubName ??
            'My Club';
    final isHome = widget.fixture.homeTeam == clubName;
    final opponent = isHome ? widget.fixture.awayTeam : widget.fixture.homeTeam;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'AI Suggested XI vs $opponent',
          style: AppTextStyles.headlineSmall.copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: PulseLoader(color: AppColors.accent),
                  ),
                  const SizedBox(height: 16),
                  Text('AI is building your lineup...',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  Text('Analyzing squad readiness & opponent tactics',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted)),
                ],
              ).animate().fadeIn(duration: 300.ms),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Strategy Summary
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingL),
                    child: Container(
                      padding: const EdgeInsets.all(AppConstants.spacingM),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: AppColors.textPrimary, size: 24),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _aiTacticalAnalysis,
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 500.ms),
                  ),

                  const SizedBox(height: AppConstants.spacingL),

                  // Pitch Map
                  SizedBox(
                    height: 480,
                    child: _PitchMap(
                      startingXI: _startingXI,
                      formation: _currentFormation,
                      onPlayerTap: _showPlayerSheet,
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingL),

                  // Bench
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingL),
                    child: Row(
                      children: [
                        Text('Substitutes', style: AppTextStyles.headlineSmall),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceBorder,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('${_bench.length} Available',
                              style: AppTextStyles.labelSmall),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingM),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _bench.length,
                      itemBuilder: (context, index) {
                        return _BenchPlayerCard(
                          player: _bench[index],
                          onTap: () => _showPlayerSheet(_bench[index]),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

class _PitchMap extends StatelessWidget {
  final List<PlayerModel> startingXI;
  final String formation;
  final ValueChanged<PlayerModel> onPlayerTap;

  const _PitchMap(
      {required this.startingXI,
      required this.formation,
      required this.onPlayerTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
      decoration: BoxDecoration(
        color: const Color(0xFF142416), // Deep Pitch Green
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Basic pitch lines (Center circle, penalty boxes)
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2), width: 2),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: double.infinity,
              height: 2,
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 140,
              height: 80,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2), width: 2),
                  left: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2), width: 2),
                  right: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2), width: 2),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: 140,
              height: 80,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2), width: 2),
                  left: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2), width: 2),
                  right: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2), width: 2),
                ),
              ),
            ),
          ),

          // Render players
          ..._buildPlayerNodes(),
        ],
      ),
    );
  }

  List<Widget> _buildPlayerNodes() {
    if (startingXI.isEmpty) return [];

    // Matches both abbreviations (GK, CB, LB…) and full API names (Goalkeeper, Defender…)
    bool isGK(PlayerModel p) {
      final s = p.position.toLowerCase();
      return s == 'gk' || s.contains('goalkeeper');
    }
    bool isDef(PlayerModel p) {
      final s = p.position.toLowerCase();
      return s.endsWith('b') || s == 'def' ||
          s.contains('defender') || s.contains('back');
    }
    bool isMid(PlayerModel p) {
      final s = p.position.toLowerCase();
      return s.endsWith('m') || s == 'mid' || s.contains('midfield');
    }
    bool isFwd(PlayerModel p) {
      final s = p.position.toLowerCase();
      return s.endsWith('t') || s.endsWith('w') ||
          s == 'cf' || s == 'fw' ||
          s.contains('forward') || s.contains('attack') ||
          s.contains('winger') || s.contains('striker');
    }

    final gks = startingXI.where(isGK).toList();
    final dfs = startingXI.where((p) => !isGK(p) && isDef(p)).toList();
    final mfs = startingXI.where((p) => !isGK(p) && !isDef(p) && isMid(p)).toList();
    final fws = startingXI.where((p) => !isGK(p) && !isDef(p) && !isMid(p) && isFwd(p)).toList();

    // Parse formation logic
    final parts = formation.split('-');
    final numDef = int.parse(parts[0]);
    final numMid = int.parse(parts[1]);
    final numFw = int.parse(parts[2]);

    List<Widget> nodes = [];

    // Alignment helper
    List<Alignment> getAlignments(int count, double y) {
      if (count <= 0) return [];
      if (count == 1) return [Alignment(0, y)];
      if (count == 2) return [Alignment(-0.4, y), Alignment(0.4, y)];
      if (count == 3)
        return [Alignment(-0.6, y), Alignment(0, y), Alignment(0.6, y)];
      if (count == 4)
        return [
          Alignment(-0.75, y),
          Alignment(-0.25, y),
          Alignment(0.25, y),
          Alignment(0.75, y)
        ];
      if (count == 5)
        return [
          Alignment(-0.8, y),
          Alignment(-0.4, y),
          Alignment(0, y),
          Alignment(0.4, y),
          Alignment(0.8, y)
        ];
      return List.generate(
          count, (i) => Alignment(-0.8 + (1.6 / (count - 1)) * i, y));
    }

    // GK
    if (gks.isNotEmpty) {
      nodes.add(_PositionedPlayer(
          player: gks[0],
          alignment: const Alignment(0, 0.85),
          onTap: () => onPlayerTap(gks[0])));
    }

    // DF
    final dfAligns = getAlignments(numDef, 0.45);
    for (int i = 0; i < dfs.length && i < numDef; i++) {
      nodes.add(_PositionedPlayer(
          player: dfs[i],
          alignment: dfAligns[i],
          onTap: () => onPlayerTap(dfs[i])));
    }

    // MF
    final mfAligns = getAlignments(numMid, -0.05);
    for (int i = 0; i < mfs.length && i < numMid; i++) {
      nodes.add(_PositionedPlayer(
          player: mfs[i],
          alignment: mfAligns[i],
          onTap: () => onPlayerTap(mfs[i])));
    }

    // FW
    final fwAligns = getAlignments(numFw, -0.6);
    for (int i = 0; i < fws.length && i < numFw; i++) {
      nodes.add(_PositionedPlayer(
          player: fws[i],
          alignment: fwAligns[i],
          onTap: () => onPlayerTap(fws[i])));
    }

    // Leftovers if any positions missing
    final plotted = [
      ...gks.take(1),
      ...dfs.take(numDef),
      ...mfs.take(numMid),
      ...fws.take(numFw)
    ];
    final unplotted = startingXI.where((p) => !plotted.contains(p)).toList();
    for (int i = 0; i < unplotted.length; i++) {
      nodes.add(_PositionedPlayer(
          player: unplotted[i],
          alignment: Alignment(0, 0),
          onTap: () =>
              onPlayerTap(unplotted[i]))); // Messy center drop, fallback only
    }

    return nodes;
  }
}

class _PositionedPlayer extends StatelessWidget {
  final PlayerModel player;
  final Alignment alignment;
  final VoidCallback onTap;

  const _PositionedPlayer(
      {required this.player, required this.alignment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: player.photoUrl == null
                    ? AppColors.gradientForRisk(player.riskBand)
                    : null,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: player.photoUrl != null
                    ? Image.network(
                        player.photoUrl!,
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            player.jerseyNumber?.toString() ?? '?',
                            style: AppTextStyles.labelMedium.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          player.jerseyNumber?.toString() ?? '?',
                          style: AppTextStyles.labelMedium.copyWith(
                              color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                player.name.split(' ').last,
                style: AppTextStyles.caption
                    .copyWith(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        )
            .animate()
            .scale(duration: 400.ms, curve: Curves.easeOutBack, delay: 200.ms),
      ),
    );
  }
}

class _BenchPlayerCard extends StatelessWidget {
  final PlayerModel player;
  final VoidCallback onTap;

  const _BenchPlayerCard({required this.player, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(player.name,
                style: AppTextStyles.labelMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(player.position,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.battery_charging_full_rounded,
                    size: 14, color: AppColors.readinessGreen),
                const SizedBox(width: 4),
                Text('${player.readinessScore.toInt()}%',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.readinessGreen)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
