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

  factory FixtureModel.fromJson(Map<String, dynamic> json) => FixtureModel(
        id: json['id'] as String,
        homeTeam: json['home_team'] as String,
        awayTeam: json['away_team'] as String,
        homeLogoUrl: json['home_logo_url'] as String?,
        awayLogoUrl: json['away_logo_url'] as String?,
        kickoff: DateTime.parse(json['kickoff'] as String),
        status: json['status'] as String? ?? 'NS',
        homeScore: json['home_score'] as int?,
        awayScore: json['away_score'] as int?,
        venue: json['venue'] as String,
        competition: json['competition'] as String,
      );

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

  factory MatchReportModel.fromJson(Map<String, dynamic> json) =>
      MatchReportModel(
        fixtureId: json['fixture_id'] as String,
        opponent: json['opponent'] as String,
        matchDate: DateTime.parse(json['match_date'] as String),
        result: json['result'] as String,
        goalsFor: json['goals_for'] as int,
        goalsAgainst: json['goals_against'] as int,
        competition: json['competition'] as String,
        avgPlayerLoad: (json['avg_player_load'] as num?)?.toDouble(),
        headline:
            json['headline'] as String? ?? json['match_summary'] as String?,
      );

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
