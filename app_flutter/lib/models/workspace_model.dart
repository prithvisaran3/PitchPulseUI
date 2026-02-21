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

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) => WorkspaceModel(
        id: json['id'] as String,
        clubId: json['club_id'] as String,
        clubName: json['club_name'] as String,
        clubCrestUrl: json['club_crest_url'] as String?,
        status: json['status'] as String? ?? 'pending',
        managerId: json['manager_id'] as String,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );

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

  const ClubSearchResult({
    required this.id,
    required this.name,
    this.country,
    this.crestUrl,
    this.founded,
  });

  factory ClubSearchResult.fromJson(Map<String, dynamic> json) => ClubSearchResult(
        id: json['id'] as String,
        name: json['name'] as String,
        country: json['country'] as String?,
        crestUrl: json['crest_url'] as String?,
        founded: json['founded'] as int?,
      );

  static List<ClubSearchResult> demoResults() => [
        const ClubSearchResult(id: 'real-madrid', name: 'Real Madrid', country: 'Spain', founded: 1902),
        const ClubSearchResult(id: 'barcelona', name: 'FC Barcelona', country: 'Spain', founded: 1899),
        const ClubSearchResult(id: 'man-city', name: 'Manchester City', country: 'England', founded: 1880),
        const ClubSearchResult(id: 'psg', name: 'Paris Saint-Germain', country: 'France', founded: 1970),
        const ClubSearchResult(id: 'bayern', name: 'Bayern Munich', country: 'Germany', founded: 1900),
      ];
}
