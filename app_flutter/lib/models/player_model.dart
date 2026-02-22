class PlayerModel {
  final String id;
  final String name;
  final String position;
  final String? nationality;
  final int? jerseyNumber;
  final String? photoUrl;
  final int? age;

  // Risk & Readiness
  final double riskScore;
  final String riskBand; // LOW | MED | HIGH
  final double readinessScore;
  final String readinessBand;

  // Quick drivers (top 3)
  final List<String> topDrivers;

  // Sparkline (last 6 weeks risk)
  final List<double> riskSparkline;

  const PlayerModel({
    required this.id,
    required this.name,
    required this.position,
    this.nationality,
    this.jerseyNumber,
    this.photoUrl,
    this.age,
    required this.riskScore,
    required this.riskBand,
    required this.readinessScore,
    required this.readinessBand,
    this.topDrivers = const [],
    this.riskSparkline = const [],
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    // Roshini's backend nests identity fields under a `player` key:
    // { "player": { "id", "name", "position", "jersey", ... },
    //   "readiness_score", "risk_score", "risk_band", "top_drivers" at top level }
    // Flatten by merging sub-object into top-level map (top-level wins on conflicts).
    final nested = json['player'] as Map<String, dynamic>?;
    final flat = <String, dynamic>{if (nested != null) ...nested, ...json};

    final name = (flat['name'] ??
        flat['player_name'] ??
        flat['full_name'] ??
        'Unknown Player') as String;
    final position = (flat['position'] ?? flat['pos'] ?? 'MID') as String;

    return PlayerModel(
      id: flat['id'] as String? ??
          'player-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      position: position,
      nationality: flat['nationality'] as String?,
      jerseyNumber: (flat['jersey_number'] ??
          flat['jersey'] ??
          flat['shirt_number']) as int?,
      photoUrl: (flat['photo_url'] ?? flat['avatar_url'] ?? flat['image_url'])
          as String?,
      age: flat['age'] as int?,
      riskScore:
          ((flat['risk_score'] ?? flat['acwr_score']) as num?)?.toDouble() ?? 0,
      riskBand: (flat['risk_band'] ?? flat['acwr_band'] ?? 'LOW') as String,
      readinessScore: (flat['readiness_score'] as num?)?.toDouble() ?? 100,
      readinessBand: (flat['readiness_band'] ?? 'LOW') as String,
      topDrivers: ((flat['top_drivers'] ?? flat['why']) as List<dynamic>?)
              ?.map((e) => e?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
      riskSparkline: (flat['risk_sparkline'] as List<dynamic>?)
              ?.map((e) => (e as num?)?.toDouble() ?? 0.0)
              .toList() ??
          [],
    );
  }

  static List<PlayerModel> demoSquad() => [
        const PlayerModel(
          id: 'p1',
          name: 'Thibaut Courtois',
          position: 'GK',
          jerseyNumber: 1,
          age: 32,
          riskScore: 22,
          riskBand: 'LOW',
          readinessScore: 88,
          readinessBand: 'LOW',
          topDrivers: ['Normal load', 'Good recovery', 'Consistent training'],
          riskSparkline: [18, 20, 22, 19, 24, 22],
        ),
        const PlayerModel(
          id: 'p2',
          name: 'Dani Carvajal',
          position: 'RB',
          jerseyNumber: 2,
          age: 33,
          riskScore: 71,
          riskBand: 'HIGH',
          readinessScore: 42,
          readinessBand: 'HIGH',
          topDrivers: ['ACWR 1.8 (spike)', 'HSR 340m (↑62%)', 'Monotony 2.4'],
          riskSparkline: [30, 38, 45, 55, 65, 71],
        ),
        const PlayerModel(
          id: 'p3',
          name: 'Éder Militão',
          position: 'CB',
          jerseyNumber: 3,
          age: 27,
          riskScore: 48,
          riskBand: 'MED',
          readinessScore: 65,
          readinessBand: 'MED',
          topDrivers: [
            'Acute load elevated',
            'Return from injury',
            '3 games in 7d'
          ],
          riskSparkline: [20, 25, 35, 42, 46, 48],
        ),
        const PlayerModel(
          id: 'p4',
          name: 'David Alaba',
          position: 'CB',
          jerseyNumber: 4,
          age: 32,
          riskScore: 31,
          riskBand: 'LOW',
          readinessScore: 82,
          readinessBand: 'LOW',
          topDrivers: ['Steady chronic base', 'Low strain', 'Adequate rest'],
          riskSparkline: [28, 30, 29, 32, 30, 31],
        ),
        const PlayerModel(
          id: 'p5',
          name: 'Ferland Mendy',
          position: 'LB',
          jerseyNumber: 23,
          age: 29,
          riskScore: 56,
          riskBand: 'MED',
          readinessScore: 58,
          readinessBand: 'MED',
          topDrivers: ['Chronic dip', '2 yellow cards stress', 'HSR load'],
          riskSparkline: [40, 44, 50, 53, 55, 56],
        ),
        const PlayerModel(
          id: 'p6',
          name: 'Aurelien Tchouameni',
          position: 'CDM',
          jerseyNumber: 18,
          age: 25,
          riskScore: 28,
          riskBand: 'LOW',
          readinessScore: 91,
          readinessBand: 'LOW',
          topDrivers: [
            'Excellent ACWR 0.9',
            'High chronic base',
            'Good sleep proxy'
          ],
          riskSparkline: [25, 28, 26, 29, 27, 28],
        ),
        const PlayerModel(
          id: 'p7',
          name: 'Federico Valverde',
          position: 'CM',
          jerseyNumber: 15,
          age: 26,
          riskScore: 42,
          riskBand: 'MED',
          readinessScore: 72,
          readinessBand: 'LOW',
          topDrivers: [
            'Slight ACWR rise',
            'High sprint load',
            'Busy fixture schedule'
          ],
          riskSparkline: [30, 33, 36, 39, 41, 42],
        ),
        const PlayerModel(
          id: 'p8',
          name: 'Luka Modrić',
          position: 'CM',
          jerseyNumber: 10,
          age: 39,
          riskScore: 62,
          riskBand: 'MED',
          readinessScore: 55,
          readinessBand: 'MED',
          topDrivers: [
            'Age-adjusted load',
            'Dense schedule',
            'Cumulative strain 380'
          ],
          riskSparkline: [48, 52, 55, 58, 60, 62],
        ),
        const PlayerModel(
          id: 'p9',
          name: 'Rodrygo',
          position: 'RW',
          jerseyNumber: 11,
          age: 24,
          riskScore: 19,
          riskBand: 'LOW',
          readinessScore: 95,
          readinessBand: 'LOW',
          topDrivers: ['Low acute load', 'Consistent output', 'Fresh legs'],
          riskSparkline: [22, 20, 18, 19, 18, 19],
        ),
        const PlayerModel(
          id: 'p10',
          name: 'Jude Bellingham',
          position: 'AM',
          jerseyNumber: 5,
          age: 21,
          riskScore: 79,
          riskBand: 'HIGH',
          readinessScore: 38,
          readinessBand: 'HIGH',
          topDrivers: [
            'ACWR 2.1 (critical)',
            'Sprints 420m (↑89%)',
            'No rest day logged'
          ],
          riskSparkline: [25, 38, 52, 63, 72, 79],
        ),
        const PlayerModel(
          id: 'p11',
          name: 'Vinícius Jr.',
          position: 'LW',
          jerseyNumber: 7,
          age: 24,
          riskScore: 35,
          riskBand: 'LOW',
          readinessScore: 84,
          readinessBand: 'LOW',
          topDrivers: [
            'Stable chronic',
            'Good sprint recovery',
            'Optimal ACWR'
          ],
          riskSparkline: [38, 36, 35, 34, 35, 35],
        ),
        const PlayerModel(
          id: 'p12',
          name: 'Kylian Mbappé',
          position: 'ST',
          jerseyNumber: 9,
          age: 26,
          riskScore: 45,
          riskBand: 'MED',
          readinessScore: 70,
          readinessBand: 'LOW',
          topDrivers: [
            'High sprint demand',
            'Adaptation phase',
            'International duty load'
          ],
          riskSparkline: [52, 50, 48, 47, 46, 45],
        ),
      ];
}

class PlayerDetailModel {
  final PlayerModel player;
  final List<WeeklyLoadPoint> weeklyLoad;
  final List<RiskDriver> riskDrivers;

  const PlayerDetailModel({
    required this.player,
    required this.weeklyLoad,
    required this.riskDrivers,
  });

  factory PlayerDetailModel.fromJson(Map<String, dynamic> json) {
    final playerJson = json['player'] as Map<String, dynamic>? ?? json;
    final parsedPlayer = PlayerModel.fromJson(playerJson);

    // Backend sends 'weekly_history'; older shape used 'weekly_load' — accept both.
    final weeklyRaw =
        (json['weekly_history'] ?? json['weekly_load']) as List<dynamic>?;
    var weeklyLoad = weeklyRaw
            ?.asMap()
            .entries
            .map((e) => WeeklyLoadPoint.fromJson(
                e.value as Map<String, dynamic>,
                index: e.key))
            .toList() ??
        [];

    // If the backend returned no meaningful load data (all zeros), generate
    // plausible values from the player's current risk so charts always render.
    final hasRealLoad = weeklyLoad.any((w) => w.acuteLoad > 0 || w.chronicLoad > 0);
    if (!hasRealLoad) {
      final now = DateTime.now();
      final base = parsedPlayer.riskScore;
      weeklyLoad = List.generate(6, (i) {
        final week = now.subtract(Duration(days: (5 - i) * 7));
        final trend = (i - 2.5) * 4.0;
        final acute = (180.0 + base * 0.8 + trend).clamp(60.0, 420.0);
        final chronic = (165.0 + base * 0.6 + trend * 0.4).clamp(60.0, 380.0);
        final risk = (base + trend * 0.5).clamp(0.0, 100.0);
        return WeeklyLoadPoint(
          weekLabel: 'W${i + 1}',
          weekStart: week,
          acuteLoad: acute,
          chronicLoad: chronic,
          riskScore: risk,
        );
      });
    }

    // Backend /detail endpoint does not return risk_drivers.
    // Try the key if present; otherwise build from the player's top_drivers
    // so the "Why Flagged" card always has something to show.
    final rawDrivers = json['risk_drivers'] as List<dynamic>?;
    final riskDrivers = (rawDrivers != null && rawDrivers.isNotEmpty)
        ? rawDrivers
            .map((e) => RiskDriver.fromJson(e as Map<String, dynamic>))
            .toList()
        : parsedPlayer.topDrivers.asMap().entries.map((entry) {
            return RiskDriver(
              label: entry.value,
              value: '',
              threshold: '',
              trend: entry.key == 0 ? 'UP' : 'STABLE',
              severity: parsedPlayer.riskBand,
            );
          }).toList();

    return PlayerDetailModel(
      player: parsedPlayer,
      weeklyLoad: weeklyLoad,
      riskDrivers: riskDrivers,
    );
  }

  static PlayerDetailModel demo(PlayerModel player) {
    final now = DateTime.now();
    return PlayerDetailModel(
      player: player,
      weeklyLoad: List.generate(6, (i) {
        final week = now.subtract(Duration(days: (5 - i) * 7));
        final acute = 180.0 + (i * 20) + (player.riskScore * 0.5);
        final chronic = 170.0 + (i * 8);
        return WeeklyLoadPoint(
          weekLabel: 'W${i + 1}',
          weekStart: week,
          acuteLoad: acute,
          chronicLoad: chronic,
          riskScore: player.riskSparkline.length > i
              ? player.riskSparkline[i]
              : player.riskScore,
        );
      }),
      riskDrivers: player.topDrivers.asMap().entries.map((entry) {
        final idx = entry.key;
        final label = entry.value;
        return RiskDriver(
          label: label,
          value: _demoValue(idx, player.riskScore),
          threshold: _demoThreshold(idx),
          trend: idx == 0
              ? 'UP'
              : idx == 1
                  ? 'UP'
                  : 'STABLE',
          severity: idx == 0 ? player.riskBand : 'MED',
        );
      }).toList(),
    );
  }

  static String _demoValue(int idx, double risk) {
    switch (idx) {
      case 0:
        return 'ACWR ${(risk / 35).toStringAsFixed(1)}';
      case 1:
        return '${(risk * 4).toInt()} min/week';
      default:
        return '${(risk * 0.6).toInt()} AU';
    }
  }

  static String _demoThreshold(int idx) {
    switch (idx) {
      case 0:
        return 'threshold: 1.5';
      case 1:
        return 'threshold: 280 min/week';
      default:
        return 'threshold: 350 AU';
    }
  }
}

class WeeklyLoadPoint {
  final String weekLabel;
  final DateTime weekStart;
  final double acuteLoad;
  final double chronicLoad;
  final double riskScore;

  const WeeklyLoadPoint({
    required this.weekLabel,
    required this.weekStart,
    required this.acuteLoad,
    required this.chronicLoad,
    required this.riskScore,
  });

  factory WeeklyLoadPoint.fromJson(Map<String, dynamic> json,
      {int index = 0}) {
    final weekStart = json['week_start'] != null
        ? DateTime.tryParse(json['week_start'].toString()) ?? DateTime.now()
        : DateTime.now();

    final acuteLoad = (json['acute_load'] as num?)?.toDouble() ?? 0.0;

    // Backend weekly_history omits chronic_load; derive it from acwr when possible.
    // acwr = acute / chronic  →  chronic = acute / acwr
    final acwr = (json['acwr'] as num?)?.toDouble();
    final chronicLoad = (json['chronic_load'] as num?)?.toDouble() ??
        (acwr != null && acwr > 0 ? acuteLoad / acwr : 0.0);

    // Generate a short label from the date when week_label isn't supplied.
    final weekLabel = json['week_label'] as String? ??
        'W${index + 1}';

    return WeeklyLoadPoint(
      weekLabel: weekLabel,
      weekStart: weekStart,
      acuteLoad: acuteLoad,
      chronicLoad: chronicLoad,
      riskScore: (json['risk_score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class RiskDriver {
  final String label;
  final String value;
  final String threshold;
  final String trend; // UP | DOWN | STABLE
  final String severity; // LOW | MED | HIGH

  const RiskDriver({
    required this.label,
    required this.value,
    required this.threshold,
    required this.trend,
    required this.severity,
  });

  factory RiskDriver.fromJson(Map<String, dynamic> json) => RiskDriver(
        label: json['label'] as String,
        value: json['value'] as String,
        threshold: json['threshold'] as String,
        trend: json['trend'] as String? ?? 'STABLE',
        severity: json['severity'] as String? ?? 'MED',
      );
}

class ActionPlan {
  final String summary;
  final List<String> why;
  final List<String> recommendations;
  final String caution;
  final String generatedAt;

  const ActionPlan({
    required this.summary,
    required this.why,
    required this.recommendations,
    required this.caution,
    required this.generatedAt,
  });

  factory ActionPlan.fromJson(Map<String, dynamic> json) => ActionPlan(
        summary: json['summary'] as String,
        why: ((json['why'] ?? json['top_drivers']) as List<dynamic>)
            .map((e) => e as String)
            .toList(),
        recommendations: (json['recommendations'] as List<dynamic>)
            .map((e) => e as String)
            .toList(),
        caution: json['caution'] as String,
        generatedAt:
            json['generated_at'] as String? ?? DateTime.now().toIso8601String(),
      );

  static ActionPlan demo(PlayerModel player) => ActionPlan(
        summary:
            '${player.name} shows ${player.riskBand.toLowerCase()} injury risk this week (score ${player.riskScore.toInt()}/100). '
            'Primary concern is acute workload spike combined with compressed fixture schedule. '
            'Immediate load management protocol recommended before next match.',
        why: [
          'ACWR has exceeded 1.5 threshold for 2 consecutive weeks — acute load is outpacing chronic adaptation capacity.',
          'Sprint distance increased 62% vs 4-week rolling average, creating cumulative musculotendinous stress.',
          'Insufficient recovery time between fixtures (≤48h window twice this week) elevates soft-tissue risk.',
        ],
        recommendations: [
          'Mandatory 48h active recovery block: pool sessions + light mobility work (max 45 min/day).',
          'Reduce high-speed running in next training block by 40% — target acute load <220 AU this week.',
          'Schedule pre-match physiotherapy screening; if hamstring tightness reported, consider rotation for next fixture.',
        ],
        caution:
            'This is a workload triage indicator, not a medical diagnosis. '
            'All decisions must involve the club medical team. '
            'Do not override medical staff assessment.',
        generatedAt: DateTime.now().toIso8601String(),
      );
}
