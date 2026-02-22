class WorkspaceModel {
  final String id;
  final String clubId;
  final String clubName;
  final String? clubCrestUrl;
  final String status; // pending | approved | rejected
  final String managerId;
  final DateTime? createdAt;

  const WorkspaceModel({
    required this.id,
    required this.clubId,
    required this.clubName,
    this.clubCrestUrl,
    required this.status,
    required this.managerId,
    this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) {
    // Roshini's backend returns `team_name` instead of `club_name`,
    // and doesn't send `club_id` or `manager_id`.
    var clubName =
        (json['club_name'] ?? json['team_name'] ?? 'Unknown Club') as String;
    final providerTeamId = json['provider_team_id'] as int?;
    final clubId = (json['club_id'] ??
        json['provider_team_id']?.toString() ??
        'unknown') as String;

    // The backend returns placeholder names like "Team 529" or "Requested Team"
    // when it hasn't synced the real club name yet. Resolve the actual name
    // from the local club catalogue using the provider team ID.
    if ((clubName.startsWith('Team ') || clubName == 'Requested Team' || clubName == 'Unknown Club') &&
        providerTeamId != null) {
      final known = ClubSearchResult.demoResults()
          .where((c) => c.providerTeamId == providerTeamId)
          .map((c) => c.name)
          .firstOrNull;
      if (known != null) clubName = known;
    }

    return WorkspaceModel(
      id: json['id'] as String,
      clubId: clubId,
      clubName: clubName,
      clubCrestUrl: json['club_crest_url'] as String?,
      status: json['status'] as String? ?? 'pending',
      managerId: json['manager_id'] as String? ?? 'unknown',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  static WorkspaceModel demo() => WorkspaceModel(
        id: 'demo-workspace-001',
        clubId: 'demo-club-real-madrid',
        clubName: 'Real Madrid',
        clubCrestUrl: null,
        status: 'approved',
        managerId: 'demo-manager-uid',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      );
}

class ClubSearchResult {
  final String id;
  final String name;
  final String? country;
  final String? crestUrl;
  final int? founded;
  final int? providerTeamId;

  const ClubSearchResult({
    required this.id,
    required this.name,
    this.country,
    this.crestUrl,
    this.founded,
    this.providerTeamId,
  });

  factory ClubSearchResult.fromJson(Map<String, dynamic> json) =>
      ClubSearchResult(
        id: json['id'] as String,
        name: json['name'] as String,
        country: json['country'] as String?,
        crestUrl: json['crest_url'] as String?,
        founded: json['founded'] as int?,
        providerTeamId: json['provider_team_id'] as int?,
      );

  static List<ClubSearchResult> demoResults() => [
        const ClubSearchResult(
            id: 'real-madrid',
            name: 'Real Madrid',
            country: 'Spain',
            founded: 1902,
            providerTeamId: 541),
        const ClubSearchResult(
            id: 'barcelona',
            name: 'FC Barcelona',
            country: 'Spain',
            founded: 1899,
            providerTeamId: 529),
        const ClubSearchResult(
            id: 'man-city',
            name: 'Manchester City',
            country: 'England',
            founded: 1880,
            providerTeamId: 50),
        const ClubSearchResult(
            id: 'psg',
            name: 'Paris Saint-Germain',
            country: 'France',
            founded: 1970,
            providerTeamId: 85),
        const ClubSearchResult(
            id: 'bayern',
            name: 'Bayern Munich',
            country: 'Germany',
            founded: 1900,
            providerTeamId: 157),
      ];
}
