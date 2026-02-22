import 'package:flutter/foundation.dart';
import '../models/workspace_model.dart';
import '../models/player_model.dart';
import '../models/fixture_model.dart';
import '../services/api_client.dart';

enum LoadState { idle, loading, loaded, error }

class WorkspaceProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  // Workspace
  List<WorkspaceModel> _workspaces = [];
  WorkspaceModel? _activeWorkspace;
  LoadState _workspaceState = LoadState.idle;

  // Home
  List<FixtureModel> _upcomingFixtures = [];
  List<PlayerModel> _squad = [];
  LoadState _homeState = LoadState.idle;

  // Reports
  List<MatchReportModel> _reports = [];

  // Admin pending requests
  List<WorkspaceModel> _pendingRequests = [];
  LoadState _adminState = LoadState.idle;

  // Polling / simulate
  bool _simulating = false;
  String? _error;

  // Guard against concurrent loadHome calls for the same workspace
  String? _loadingHomeId;

  // Track workspaces that have already been auto-synced so we don't loop.
  final Set<String> _autoSyncedIds = {};

  // Getters
  List<WorkspaceModel> get workspaces => _workspaces;
  WorkspaceModel? get activeWorkspace => _activeWorkspace;
  LoadState get workspaceState => _workspaceState;
  List<FixtureModel> get upcomingFixtures => _upcomingFixtures;
  List<PlayerModel> get squad => _squad;
  LoadState get homeState => _homeState;
  List<MatchReportModel> get reports => _reports;
  List<WorkspaceModel> get pendingRequests => _pendingRequests;
  LoadState get adminState => _adminState;
  bool get simulating => _simulating;
  String? get error => _error;

  // ── Club Search (local filter — backend has no search endpoint) ────────────
  Future<List<ClubSearchResult>> searchClubs(String query) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final q = query.toLowerCase();
    return ClubSearchResult.demoResults()
        .where((c) => c.name.toLowerCase().contains(q))
        .toList();
  }

  // ── Request Access ──────────────────────────────────────────────────────────
  // Backend auto-approves and returns the workspace with status: "approved".
  // We grab the workspace ID, set it as active, load home, and sync in background.
  Future<void> requestAccess(String clubId, String clubName,
      {int? providerTeamId}) async {
    _workspaceState = LoadState.loading;
    notifyListeners();

    try {
      final body = providerTeamId != null
          ? {'provider_team_id': providerTeamId}
          : {'club_id': clubId, 'club_name': clubName};

      debugPrint('🟡 [WorkspaceProvider] request_access payload: $body');
      final data = await _api.post('/workspaces/request_access', body: body)
          as Map<String, dynamic>;
      debugPrint('🟢 [WorkspaceProvider] request_access Response: $data');

      // Parse the instantly-approved workspace
      var ws = WorkspaceModel.fromJson(data);

      // Backend bug: provider_team_id requests sometimes return 'Requested Team' or 'Team <ID>'.
      // If we see that, forcefully use the known clubName we just passed in.
      if (ws.clubName.startsWith('Team ') ||
          ws.clubName == 'Requested Team' ||
          ws.clubName == 'Unknown Club') {
        ws = WorkspaceModel(
          id: ws.id,
          clubId: ws.clubId,
          clubName: clubName,
          clubCrestUrl: ws.clubCrestUrl,
          status: ws.status,
          managerId: ws.managerId,
          createdAt: ws.createdAt,
        );
      }

      _workspaces = [ws];
      _activeWorkspace = ws;
      _workspaceState = LoadState.loaded;
      notifyListeners();

      // Load home data immediately so home screen is populated
      await loadHome(ws.id);
    } catch (e) {
      debugPrint('🔴 [WorkspaceProvider] request_access Error: $e');
      // Fall back: reload from /me in case workspace was already created
      await loadWorkspaces();
    }
  }

  // ── Load Workspaces ─────────────────────────────────────────────────────────
  Future<void> loadWorkspaces() async {
    _workspaceState = LoadState.loading;
    notifyListeners();
    try {
      final response = await _api.get('/me') as Map<String, dynamic>;
      final data = response['workspaces'] as List<dynamic>? ?? [];
      debugPrint('🟢 [WorkspaceProvider] Workspaces Response: $data');
      _workspaces = data
          .map((e) => WorkspaceModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (_workspaces.isNotEmpty && _activeWorkspace == null) {
        _activeWorkspace = _workspaces.firstWhere((w) => w.isApproved,
            orElse: () => _workspaces.first);
      }
      _workspaceState = LoadState.loaded;
    } catch (e) {
      debugPrint('🔴 [WorkspaceProvider] Error loading workspaces: $e');
      _workspaces = [];
      _workspaceState = LoadState.error;
    }
    notifyListeners();

    if (_activeWorkspace != null) {
      await loadHome(_activeWorkspace!.id);
    }
  }

  // ── Load Home ───────────────────────────────────────────────────────────────
  Future<void> loadHome(String workspaceId) async {
    // Prevent duplicate in-flight requests for the same workspace.
    if (_loadingHomeId == workspaceId) return;
    _loadingHomeId = workspaceId;

    _homeState = LoadState.loading;
    notifyListeners();
    try {
      final data = await _api.get('/workspaces/$workspaceId/home')
          as Map<String, dynamic>;
      debugPrint(
          '🟢 [WorkspaceProvider] Home Sync Response for ws=$workspaceId: $data');

      // Update workspace club name from home response if available.
      // Use WorkspaceModel.fromJson so placeholder names like "Team 529" are
      // automatically resolved to the real club name via providerTeamId lookup.
      final wsData = data['workspace'] as Map<String, dynamic>?;
      if (wsData != null && _activeWorkspace != null) {
        final resolved = WorkspaceModel.fromJson({
          ...wsData,
          'status': wsData['status'] ?? _activeWorkspace!.status,
          'manager_id': _activeWorkspace!.managerId,
        });
        // Only update if we got a better name (not a placeholder).
        if (resolved.clubName != 'Unknown Club' &&
            resolved.clubName != _activeWorkspace!.clubName) {
          _activeWorkspace = WorkspaceModel(
            id: _activeWorkspace!.id,
            clubId: _activeWorkspace!.clubId,
            clubName: resolved.clubName,
            clubCrestUrl: _activeWorkspace!.clubCrestUrl,
            status: _activeWorkspace!.status,
            managerId: _activeWorkspace!.managerId,
            createdAt: _activeWorkspace!.createdAt,
          );
        }
      }

      final effectiveTeamName = _activeWorkspace?.clubName ?? 'My Club';

      // Parse upcoming fixtures — backend sends `next_fixture` (singular)
      _upcomingFixtures = [];
      if (data['upcoming_fixtures'] != null) {
        final fixturesJson = data['upcoming_fixtures'] as List<dynamic>;
        _upcomingFixtures = fixturesJson
            .map((e) => FixtureModel.fromJson(
                e as Map<String, dynamic>, effectiveTeamName))
            .toList();
      } else if (data['next_fixture'] != null) {
        _upcomingFixtures = [
          FixtureModel.fromJson(
              data['next_fixture'] as Map<String, dynamic>, effectiveTeamName)
        ];
      }

      // If the backend has no fixture data for this approved workspace, show
      // demo fixtures branded with the workspace's team name so the UI is
      // always populated and the Suggested XI feature is accessible.
      if (_upcomingFixtures.isEmpty && _activeWorkspace?.status == 'approved') {
        _upcomingFixtures = _buildDemoFixturesFor(effectiveTeamName);
        debugPrint('🟡 [WorkspaceProvider] No fixtures from backend — using local demo for $effectiveTeamName');
      }

      // Parse recent fixtures to populate reports
      final recent = data['recent_fixtures'] as List<dynamic>?;
      if (recent != null && recent.isNotEmpty) {
        _reports = recent
            .map((e) => MatchReportModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _reports = [];
      }

      // Parse squad
      final squadJson = data['squad'] as List<dynamic>? ?? [];
      if (squadJson.isNotEmpty) {
        debugPrint(
            '🔍 [WorkspaceProvider] First squad member raw JSON: ${squadJson.first}');
      }
      _squad = squadJson
          .map((e) => PlayerModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _homeState = LoadState.loaded;
    } catch (e) {
      debugPrint('🔴 [WorkspaceProvider] Home Sync Error: $e');
      _upcomingFixtures = FixtureModel.demoUpcomingList();
      _squad = PlayerModel.demoSquad();
      _homeState = LoadState.error;
    }
    _loadingHomeId = null;
    notifyListeners();

    // If this workspace has no fixtures yet and hasn't been auto-synced,
    // trigger an initial sync to populate demo fixtures from the API.
    final isApproved = _activeWorkspace?.status == 'approved';
    if (isApproved &&
        _upcomingFixtures.isEmpty &&
        !_autoSyncedIds.contains(workspaceId)) {
      _autoSyncedIds.add(workspaceId);
      debugPrint('🟡 [WorkspaceProvider] No fixtures for $workspaceId — triggering initial sync');
      try {
        final ok = await _api.triggerInitialSync(workspaceId);
        if (ok) {
          debugPrint('🟢 [WorkspaceProvider] Initial sync done for $workspaceId — reloading');
          await loadHome(workspaceId);
        }
      } catch (e) {
        debugPrint('🔴 [WorkspaceProvider] Initial sync error for $workspaceId: $e');
      }
    }
  }

  /// Builds a short list of demo upcoming fixtures for teams that have no
  /// real fixture data in the backend yet (newly approved workspaces).
  List<FixtureModel> _buildDemoFixturesFor(String teamName) {
    final now = DateTime.now();
    final opponents = ['Arsenal', 'Bayern Munich', 'PSG', 'Juventus', 'Chelsea'];
    return List.generate(3, (i) {
      final isHome = i.isEven;
      return FixtureModel(
        id: 'demo-fixture-${teamName.hashCode}-$i',
        homeTeam: isHome ? teamName : opponents[i],
        awayTeam: isHome ? opponents[i] : teamName,
        kickoff: now.add(Duration(days: (i + 1) * 7 - 2)),
        status: 'NS',
        competition: 'League',
        venue: isHome ? 'Home Stadium' : '${opponents[i]} Stadium',
      );
    });
  }

  Future<Map<String, dynamic>> generateSuggestedXi(
      String workspaceId, Map<String, dynamic> payload) async {
    try {
      // AI endpoint — single attempt with a short timeout so the UI can
      // fall back to local XI selection quickly if the backend is slow.
      final data = await _api.post(
        '/workspaces/$workspaceId/suggested-xi',
        body: payload,
        timeout: const Duration(seconds: 10),
        maxRetries: 0,
      ) as Map<String, dynamic>;
      debugPrint('🟢 [WorkspaceProvider] Suggested XI Response: $data');
      return data;
    } catch (e) {
      debugPrint('🔴 [WorkspaceProvider] Suggested XI Error: $e');
      rethrow;
    }
  }

  // ── Admin: Load Pending Requests ────────────────────────────────────────────
  Future<void> loadPendingRequests() async {
    _adminState = LoadState.loading;
    notifyListeners();
    try {
      final data = await _api.get('/admin/requests') as List<dynamic>;
      debugPrint('🟢 [WorkspaceProvider] Pending Admin Requests: $data');
      _pendingRequests = data
          .map((e) => WorkspaceModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _adminState = LoadState.loaded;
    } catch (_) {
      _pendingRequests = [
        WorkspaceModel(
          id: 'pending-001',
          clubId: 'real-madrid',
          clubName: 'Real Madrid',
          status: 'pending',
          managerId: 'manager-uid-001',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        WorkspaceModel(
          id: 'pending-002',
          clubId: 'barcelona',
          clubName: 'FC Barcelona',
          status: 'pending',
          managerId: 'manager-uid-002',
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ];
      _adminState = LoadState.loaded;
    }
    notifyListeners();
  }

  // ── Admin: Approve Workspace ────────────────────────────────────────────────
  Future<void> approveWorkspace(String workspaceId) async {
    try {
      await _api.post('/admin/workspaces/$workspaceId/approve');
    } catch (_) {}
    _pendingRequests.removeWhere((w) => w.id == workspaceId);
    notifyListeners();
  }

  // ── Simulate FT Update ──────────────────────────────────────────────────────
  Future<void> simulateMatchFinished() async {
    _simulating = true;
    notifyListeners();
    try {
      await _api.post('/sync/fixtures/poll_once');
      await Future.delayed(const Duration(seconds: 2));
      // Reload home after simulation
      if (_activeWorkspace != null) {
        await loadHome(_activeWorkspace!.id);
      }
    } catch (e) {
      debugPrint('🔴 [WorkspaceProvider] Simulate Match Error: $e');
      // Demo: just update squad with more dramatic risk scores
      await Future.delayed(const Duration(seconds: 2));
      _squad = PlayerModel.demoSquad().map((p) {
        if (p.riskBand == 'LOW' && p.riskScore < 30) {
          return PlayerModel(
            id: p.id,
            name: p.name,
            position: p.position,
            jerseyNumber: p.jerseyNumber,
            age: p.age,
            riskScore: p.riskScore + 12,
            riskBand: 'MED',
            readinessScore: p.readinessScore - 10,
            readinessBand: 'MED',
            topDrivers: [
              'Post-match load spike',
              'Sprint distance elevated',
              ...p.topDrivers.take(1)
            ],
            riskSparkline: [...p.riskSparkline.skip(1), p.riskScore + 12],
          );
        }
        return p;
      }).toList();
      _upcomingFixtures = FixtureModel.demoUpcomingList()
          .skip(1)
          .toList(); // Remove the finished one
      _reports = [
        MatchReportModel(
          fixtureId: 'ft-001',
          opponent: 'Atlético Madrid',
          matchDate: DateTime.now(),
          result: 'W',
          goalsFor: 2,
          goalsAgainst: 1,
          competition: 'La Liga',
          avgPlayerLoad: 268,
          headline:
              'Post-match update: 4 players in MED risk, Bellingham flagged HIGH.',
        ),
        ...MatchReportModel.demoList(),
      ];
    }
    _simulating = false;
    notifyListeners();
  }

  /// Wipe all cached data so next load fetches from the real backend.
  void clearAll() {
    _workspaces = [];
    _activeWorkspace = null;
    _workspaceState = LoadState.idle;
    _upcomingFixtures = [];
    _squad = [];
    _homeState = LoadState.idle;
    _reports = [];
    _pendingRequests = [];
    _adminState = LoadState.idle;
    _simulating = false;
    _error = null;
    notifyListeners();
  }

  void setActiveWorkspace(WorkspaceModel ws) {
    _activeWorkspace = ws;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
