import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/fixture_model.dart';
import '../../models/player_model.dart';
import '../../providers/workspace_provider.dart';
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

    final isHome = widget.fixture.homeTeam == 'Castilla' ||
        widget.fixture.homeTeam == 'Real Madrid';
    final opponent = isHome ? widget.fixture.awayTeam : widget.fixture.homeTeam;

    try {
      final payload = {
        'opponent': opponent,
        'match_context':
            '${isHome ? "Home" : "Away"}, ${widget.fixture.competition}',
        'available_squad': squad
            .map((p) => {
                  'id': p.id,
                  'name': p.name,
                  'position': p.position,
                  'readiness': p.readinessScore.round(),
                  'form': p.readinessBand == 'LOW'
                      ? 'Excellent'
                      : p.readinessBand == 'MED'
                          ? 'Good'
                          : 'Poor',
                })
            .toList(),
      };

      final data = await workspaceProvider.generateSuggestedXi(wsId, payload);

      final bestFormation = data['best_formation'] as String? ?? '4-3-3';
      final analysis = data['tactical_analysis'] as String? ?? '';
      final xiIds = (data['starting_xi_ids'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList();
      final rationales =
          (data['player_rationales'] as Map<String, dynamic>? ?? {})
              .map((k, v) => MapEntry(k, v.toString()));

      // Build starting XI from IDs returned by AI
      final idToPlayer = {for (var p in squad) p.id: p};
      final aiXI = xiIds
          .where((id) => idToPlayer.containsKey(id))
          .map((id) => idToPlayer[id]!)
          .toList();

      if (aiXI.length >= 7) {
        // Enough valid players matched — use AI result
        _currentFormation = bestFormation;
        _aiTacticalAnalysis = analysis;
        _startingXI = aiXI.take(11).toList();
        _bench = squad.where((p) => !_startingXI.contains(p)).toList();
        _playerRationales = rationales;
        _bench.sort((a, b) => b.readinessScore.compareTo(a.readinessScore));
      } else {
        throw Exception("Failed to match squad IDs");
      }
    } catch (_) {
      _aiTacticalAnalysis =
          "Error reaching the Gemini proxy. Please check your backend connection.";
    }

    if (mounted) setState(() => _isLoading = false);
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
    final isHome = widget.fixture.homeTeam == 'Real Madrid' ||
        widget.fixture.homeTeam == 'Castilla';
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
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                        color: AppColors.accent, strokeWidth: 3),
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

    // Sort into buckets roughly for 4-3-3
    final gks = startingXI.where((p) => p.position == 'GK').toList();
    final dfs = startingXI
        .where((p) => p.position.endsWith('B') || p.position == 'DEF')
        .toList();
    final mfs = startingXI
        .where((p) => p.position.endsWith('M') || p.position == 'MID')
        .toList();
    final fws = startingXI
        .where((p) =>
            p.position.endsWith('T') ||
            p.position.endsWith('W') ||
            p.position == 'CF' ||
            p.position == 'FW')
        .toList();

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
                gradient: AppColors.gradientForRisk(player.riskBand),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  player.jerseyNumber?.toString() ?? '?',
                  style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.black, fontWeight: FontWeight.bold),
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
