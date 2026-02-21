import 'package:flutter/material.dart';

class FixtureModel {
  final String id;
  final String homeTeam;
  final String awayTeam;
  final String? homeLogoUrl;
  final String? awayLogoUrl;
  final DateTime kickoff;
  final String status; // NS | LIVE | FT | POSTPONED
  final int? homeScore;
  final int? awayScore;
  final String venue;
  final String competition;

  const FixtureModel({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    this.homeLogoUrl,
    this.awayLogoUrl,
    required this.kickoff,
    required this.status,
    this.homeScore,
    this.awayScore,
    required this.venue,
    required this.competition,
  });

  bool get isLive => status == 'LIVE';
  bool get isFinished => status == 'FT';
  bool get isNotStarted => status == 'NS';

  Duration get timeUntilKickoff => kickoff.difference(DateTime.now());

  factory FixtureModel.fromJson(Map<String, dynamic> json,
      [String myTeamName = 'My Club']) {
    // Roshini's API uses opponent_name + home_away instead of home_team/away_team.
    final opponent = json['opponent_name'] as String? ?? 'Unknown';
    final isHome = (json['home_away'] as String? ?? 'home') == 'home';
    return FixtureModel(
      id: json['id'] as String,
      homeTeam: isHome ? myTeamName : opponent,
      awayTeam: isHome ? opponent : myTeamName,
      homeLogoUrl: json['home_logo_url'] as String?,
      awayLogoUrl: json['away_logo_url'] as String?,
      kickoff: DateTime.parse(json['kickoff'] as String),
      status: json['status'] as String? ?? 'NS',
      homeScore: json['score_home'] as int?,
      awayScore: json['score_away'] as int?,
      venue: json['venue'] as String? ?? (isHome ? 'Home' : 'Away'),
      competition: json['competition'] as String? ?? 'League',
    );
  }

  static FixtureModel demoUpcoming() => FixtureModel(
        id: 'fixture-next-001',
        homeTeam: 'Real Madrid',
        awayTeam: 'Atlético Madrid',
        kickoff: DateTime.now().add(const Duration(days: 3, hours: 6)),
        status: 'NS',
        venue: 'Santiago Bernabéu',
        competition: 'La Liga',
      );

  static List<FixtureModel> demoUpcomingList() => [
        demoUpcoming(),
        FixtureModel(
          id: 'fixture-next-002',
          homeTeam: 'Sevilla',
          awayTeam: 'Real Madrid',
          kickoff: DateTime.now().add(const Duration(days: 10, hours: 2)),
          status: 'NS',
          venue: 'Ramón Sánchez Pizjuán',
          competition: 'La Liga',
        ),
        FixtureModel(
          id: 'fixture-next-003',
          homeTeam: 'Real Madrid',
          awayTeam: 'Bayern FC',
          kickoff: DateTime.now().add(const Duration(days: 14, hours: 8)),
          status: 'NS',
          venue: 'Santiago Bernabéu',
          competition: 'UCL',
        ),
      ];

  static FixtureModel demoLive() => FixtureModel(
        id: 'fixture-live-001',
        homeTeam: 'Real Madrid',
        awayTeam: 'Barcelona',
        kickoff: DateTime.now().subtract(const Duration(minutes: 67)),
        status: 'LIVE',
        homeScore: 2,
        awayScore: 1,
        venue: 'Santiago Bernabéu',
        competition: 'La Liga',
      );
}

class MatchReportModel {
  final String fixtureId;
  final String opponent;
  final DateTime matchDate;
  final String result; // W | D | L
  final int goalsFor;
  final int goalsAgainst;
  final String competition;
  final double? avgPlayerLoad;
  final String? headline;

  const MatchReportModel({
    required this.fixtureId,
    required this.opponent,
    required this.matchDate,
    required this.result,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.competition,
    this.avgPlayerLoad,
    this.headline,
  });

  factory MatchReportModel.fromJson(Map<String, dynamic> json) {
    // Roshini's `recent_fixtures` has opponent_name/kickoff/score_home/score_away
    final goalsFor = (json['goals_for'] ?? json['score_away']) as int? ?? 0;
    final goalsAgainst =
        (json['goals_against'] ?? json['score_home']) as int? ?? 0;
    final scoreFor = goalsFor;
    final scoreAgainst = goalsAgainst;
    final String result;
    if (scoreFor > scoreAgainst)
      result = 'W';
    else if (scoreFor < scoreAgainst)
      result = 'L';
    else
      result = 'D';

    return MatchReportModel(
      fixtureId: json['fixture_id'] as String? ?? json['id'] as String? ?? '',
      opponent: json['opponent'] as String? ??
          json['opponent_name'] as String? ??
          'Unknown',
      matchDate: DateTime.tryParse(json['match_date'] as String? ??
              json['kickoff'] as String? ??
              '') ??
          DateTime.now(),
      result: json['result'] as String? ?? result,
      goalsFor: goalsFor,
      goalsAgainst: goalsAgainst,
      competition: json['competition'] as String? ?? 'League',
      avgPlayerLoad: (json['avg_player_load'] as num?)?.toDouble(),
      headline: json['headline'] as String? ?? json['match_summary'] as String?,
    );
  }

  Color get resultColor {
    switch (result) {
      case 'W':
        return const Color(0xFF00E5A0);
      case 'D':
        return const Color(0xFFFFC107);
      case 'L':
        return const Color(0xFFFF4040);
      default:
        return const Color(0xFF8FA3BF);
    }
  }

  static List<MatchReportModel> demoList() => [
        MatchReportModel(
          fixtureId: 'r1',
          opponent: 'Villarreal',
          matchDate: DateTime.now().subtract(const Duration(days: 7)),
          result: 'W',
          goalsFor: 3,
          goalsAgainst: 1,
          competition: 'La Liga',
          avgPlayerLoad: 248,
          headline:
              '3 HIGH risk flags post-match. Bellingham & Carvajal flagged.',
        ),
        MatchReportModel(
          fixtureId: 'r2',
          opponent: 'Manchester City',
          matchDate: DateTime.now().subtract(const Duration(days: 14)),
          result: 'D',
          goalsFor: 1,
          goalsAgainst: 1,
          competition: 'UCL',
          avgPlayerLoad: 312,
          headline:
              'High load match. Squad fatigue elevated. 5 players in MED zone.',
        ),
        MatchReportModel(
          fixtureId: 'r3',
          opponent: 'Sevilla',
          matchDate: DateTime.now().subtract(const Duration(days: 21)),
          result: 'W',
          goalsFor: 2,
          goalsAgainst: 0,
          competition: 'La Liga',
          avgPlayerLoad: 215,
          headline: 'Controlled performance. Load within optimal range.',
        ),
        MatchReportModel(
          fixtureId: 'r4',
          opponent: 'Borussia Dortmund',
          matchDate: DateTime.now().subtract(const Duration(days: 28)),
          result: 'W',
          goalsFor: 2,
          goalsAgainst: 1,
          competition: 'UCL',
          avgPlayerLoad: 290,
          headline:
              'High intensity. Mbappé & Valverde show elevated acute spikes.',
        ),
      ];
}
