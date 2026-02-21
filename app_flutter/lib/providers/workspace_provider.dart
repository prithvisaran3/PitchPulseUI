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
  FixtureModel? _nextFixture;
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

  // Getters
  List<WorkspaceModel> get workspaces => _workspaces;
  WorkspaceModel? get activeWorkspace => _activeWorkspace;
  LoadState get workspaceState => _workspaceState;
  FixtureModel? get nextFixture => _nextFixture;
  List<PlayerModel> get squad => _squad;
  LoadState get homeState => _homeState;
  List<MatchReportModel> get reports => _reports;
  List<WorkspaceModel> get pendingRequests => _pendingRequests;
  LoadState get adminState => _adminState;
  bool get simulating => _simulating;
  String? get error => _error;

  // ── Club Search ─────────────────────────────────────────────────────────────
  Future<List<ClubSearchResult>> searchClubs(String query) async {
    try {
      final data = await _api.get('/clubs/search?q=${Uri.encodeComponent(query)}');
      final list = data as List<dynamic>;
      return list.map((e) => ClubSearchResult.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // Return demo results when backend is not available
      await Future.delayed(const Duration(milliseconds: 600));
      return ClubSearchResult.demoResults()
          .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  // ── Request Access ──────────────────────────────────────────────────────────
  Future<WorkspaceModel?> requestAccess(String clubId, String clubName) async {
    try {
      final data = await _api.post('/workspaces/request_access', body: {
        'club_id': clubId,
        'club_name': clubName,
      });
      final ws = WorkspaceModel.fromJson(data as Map<String, dynamic>);
      _workspaces.add(ws);
      notifyListeners();
      return ws;
    } catch (_) {
      // Demo mode: return pending workspace
      final ws = WorkspaceModel(
        id: 'ws-${DateTime.now().millisecondsSinceEpoch}',
        clubId: clubId,
        clubName: clubName,
        status: 'pending',
        managerId: 'demo-uid',
      );
      _workspaces.add(ws);
      notifyListeners();
      return ws;
    }
  }

  // ── Load Workspaces ─────────────────────────────────────────────────────────
  Future<void> loadWorkspaces() async {
    _workspaceState = LoadState.loading;
    notifyListeners();
    try {
      final data = await _api.get('/me/workspaces') as List<dynamic>;
      _workspaces = data.map((e) => WorkspaceModel.fromJson(e as Map<String, dynamic>)).toList();
      if (_workspaces.isNotEmpty && _activeWorkspace == null) {
        _activeWorkspace = _workspaces.firstWhere((w) => w.isApproved, orElse: () => _workspaces.first);
      }
      _workspaceState = LoadState.loaded;
    } catch (_) {
      _workspaces = [WorkspaceModel.demo()];
      _activeWorkspace = _workspaces.first;
      _workspaceState = LoadState.loaded;
    }
    notifyListeners();
  }

  // ── Load Home ───────────────────────────────────────────────────────────────
  Future<void> loadHome(String workspaceId) async {
    _homeState = LoadState.loading;
    notifyListeners();
    try {
      final data = await _api.get('/workspaces/$workspaceId/home') as Map<String, dynamic>;
      _nextFixture = FixtureModel.fromJson(data['next_fixture'] as Map<String, dynamic>);
      final playersJson = data['squad'] as List<dynamic>;
      _squad = playersJson.map((e) => PlayerModel.fromJson(e as Map<String, dynamic>)).toList();
      _homeState = LoadState.loaded;
    } catch (_) {
      _nextFixture = FixtureModel.demoUpcoming();
      _squad = PlayerModel.demoSquad();
      _homeState = LoadState.loaded;
    }
    notifyListeners();
  }

  // ── Load Reports ────────────────────────────────────────────────────────────
  Future<void> loadReports(String workspaceId) async {
    try {
      final data = await _api.get('/workspaces/$workspaceId/reports') as List<dynamic>;
      _reports = data.map((e) => MatchReportModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      _reports = MatchReportModel.demoList();
    }
    notifyListeners();
  }

  // ── Admin: Load Pending Requests ────────────────────────────────────────────
  Future<void> loadPendingRequests() async {
    _adminState = LoadState.loading;
    notifyListeners();
    try {
      final data = await _api.get('/admin/workspaces/pending') as List<dynamic>;
      _pendingRequests = data.map((e) => WorkspaceModel.fromJson(e as Map<String, dynamic>)).toList();
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
    } catch (_) {
      // Demo: just update squad with more dramatic risk scores
      await Future.delayed(const Duration(seconds: 2));
      _squad = PlayerModel.demoSquad().map((p) {
        if (p.riskBand == 'LOW' && p.riskScore < 30) {
          return PlayerModel(
            id: p.id, name: p.name, position: p.position,
            jerseyNumber: p.jerseyNumber, age: p.age,
            riskScore: p.riskScore + 12, riskBand: 'MED',
            readinessScore: p.readinessScore - 10, readinessBand: 'MED',
            topDrivers: ['Post-match load spike', 'Sprint distance elevated', ...p.topDrivers.take(1)],
            riskSparkline: [...p.riskSparkline.skip(1), p.riskScore + 12],
          );
        }
        return p;
      }).toList();
      _nextFixture = FixtureModel(
        id: 'fixture-ft-001',
        homeTeam: 'Real Madrid',
        awayTeam: 'Atlético Madrid',
        kickoff: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'FT',
        homeScore: 2,
        awayScore: 1,
        venue: 'Santiago Bernabéu',
        competition: 'La Liga',
      );
      _reports = [
        MatchReportModel(
          fixtureId: 'ft-001',
          opponent: 'Atlético Madrid',
          matchDate: DateTime.now(),
          result: 'W', goalsFor: 2, goalsAgainst: 1,
          competition: 'La Liga',
          avgPlayerLoad: 268,
          headline: 'Post-match update: 4 players in MED risk, Bellingham flagged HIGH.',
        ),
        ...MatchReportModel.demoList(),
      ];
    }
    _simulating = false;
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
