import 'package:flutter/foundation.dart';
import '../models/player_model.dart';
import '../services/api_client.dart';

enum PlayerLoadState { idle, loading, loaded, error }

class PlayerProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  final Map<String, PlayerDetailModel> _detailCache = {};
  final Map<String, List<SimilarCase>> _similarCache = {};
  final Map<String, ActionPlan> _planCache = {};

  PlayerDetailModel? _currentDetail;
  List<SimilarCase>? _currentSimilar;
  ActionPlan? _currentPlan;

  PlayerLoadState _detailState = PlayerLoadState.idle;
  PlayerLoadState _similarState = PlayerLoadState.idle;
  PlayerLoadState _planState = PlayerLoadState.idle;

  String? _error;

  PlayerDetailModel? get currentDetail => _currentDetail;
  List<SimilarCase>? get currentSimilar => _currentSimilar;
  ActionPlan? get currentPlan => _currentPlan;

  PlayerLoadState get detailState => _detailState;
  PlayerLoadState get similarState => _similarState;
  PlayerLoadState get planState => _planState;

  String? get error => _error;

  // ── Load Player Detail ──────────────────────────────────────────────────────
  Future<void> loadPlayerDetail(PlayerModel player) async {
    if (_detailCache.containsKey(player.id)) {
      _currentDetail = _detailCache[player.id];
      _currentSimilar = null;
      _currentPlan = null;
      notifyListeners();
      return;
    }

    _detailState = PlayerLoadState.loading;
    _currentDetail = null;
    _currentSimilar = null;
    _currentPlan = null;
    notifyListeners();

    try {
      final data = await _api.get('/players/${player.id}/detail?weeks=6')
          as Map<String, dynamic>;
      debugPrint('🟢 [PlayerProvider] Detail Response for ${player.id}: $data');
      _currentDetail = PlayerDetailModel.fromJson(data);
      _detailCache[player.id] = _currentDetail!;
      _detailState = PlayerLoadState.loaded;
    } catch (e) {
      debugPrint('🔴 [PlayerProvider] Detail Error for ${player.id}: $e');
      _detailState = PlayerLoadState.error;
      _error = e.toString();
    }
    notifyListeners();
  }

  // ── Load Similar Cases ──────────────────────────────────────────────────────
  Future<void> loadSimilarCases(String playerId) async {
    if (_similarCache.containsKey(playerId)) {
      _currentSimilar = _similarCache[playerId];
      notifyListeners();
      return;
    }

    _similarState = PlayerLoadState.loading;
    notifyListeners();

    try {
      final data = await _api.get('/players/$playerId/similar_cases?k=5')
          as List<dynamic>;
      debugPrint(
          '🟢 [PlayerProvider] Similar Cases Response for $playerId: $data');
      _currentSimilar = data
          .map((e) => SimilarCase.fromJson(e as Map<String, dynamic>))
          .toList();
      _similarCache[playerId] = _currentSimilar!;
      _similarState = PlayerLoadState.loaded;
    } catch (e) {
      debugPrint('🔴 [PlayerProvider] Similar Cases Error for $playerId: $e');
      _similarState = PlayerLoadState.error;
      _error = e.toString();
    }
    notifyListeners();
  }

  // ── Generate Action Plan ────────────────────────────────────────────────────
  Future<void> generateActionPlan(PlayerModel player) async {
    if (_planCache.containsKey(player.id)) {
      _currentPlan = _planCache[player.id];
      notifyListeners();
      return;
    }

    _planState = PlayerLoadState.loading;
    notifyListeners();

    try {
      final data = await _api.post('/players/${player.id}/action_plan')
          as Map<String, dynamic>;
      debugPrint(
          '🟢 [PlayerProvider] Action Plan Response for ${player.id}: $data');
      _currentPlan = ActionPlan.fromJson(data);
      _planCache[player.id] = _currentPlan!;
      _planState = PlayerLoadState.loaded;
    } catch (e) {
      debugPrint('🔴 [PlayerProvider] Action Plan Error for ${player.id}: $e');
      _planState = PlayerLoadState.error;
      _error = e.toString();
    }
    notifyListeners();
  }

  void clearCache() {
    _detailCache.clear();
    _similarCache.clear();
    _planCache.clear();
    _currentDetail = null;
    _currentSimilar = null;
    _currentPlan = null;
  }
}
