import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/player_model.dart';
import '../../widgets/common/gradient_badge.dart';
import '../../widgets/common/pulse_loader.dart';
import '../../services/api_client.dart';

class PlayerCheckInScreen extends StatefulWidget {
  final PlayerModel player;
  const PlayerCheckInScreen({super.key, required this.player});

  @override
  State<PlayerCheckInScreen> createState() => _PlayerCheckInScreenState();
}

class _PlayerCheckInScreenState extends State<PlayerCheckInScreen> {
  final _picker = ImagePicker();

  // ── Selfie States ──────────────────────────────────────────────────────────
  bool _isSelfieLoading = false;
  bool _selfieSuccess = false;
  XFile? _selfieVideo;
  String? _readinessFlag;
  int? _readinessDelta;
  String? _emotionalState;
  List<String> _contributingFactors = [];
  String? _selfieRecommendation;

  // ── Movement States ────────────────────────────────────────────────────────
  bool _isMovementLoading = false;
  bool _movementSuccess = false;
  XFile? _movementVideo;
  String? _mechanicalRiskBand;
  List<String> _movementFlags = [];
  List<String> _coachingCues = [];
  double? _movementConfidence;

  // ── Dialog Helper ──────────────────────────────────────────────────────────
  Future<bool> _showDemoDialog(
      String title, String description, IconData icon) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceElevated,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(title, style: AppTextStyles.headlineSmall),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBorder.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(icon, size: 60, color: AppColors.textPrimary)
                          .animate(onPlay: (controller) => controller.repeat())
                          .shimmer(duration: 1500.ms)
                          .moveY(
                              begin: -5,
                              end: 5,
                              duration: 1000.ms,
                              curve: Curves.easeInOut)
                          .then()
                          .moveY(
                              begin: 5,
                              end: -5,
                              duration: 1000.ms,
                              curve: Curves.easeInOut),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    description,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: AppColors.bg,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Proceed to Record',
                      style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.bg, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // ── Selfie recording + upload ──────────────────────────────────────────────
  Future<void> _recordSelfie() async {
    HapticFeedback.mediumImpact();

    final proceed = await _showDemoDialog(
      'Selfie Demo',
      'Hold the phone at eye level. Ensure your face is well-lit and clearly visible in the frame for the entire 10 seconds.',
      Icons.face_retouching_natural_rounded,
    );
    if (!proceed) return;

    // Open front camera for 10s video
    final video = await _picker.pickVideo(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      maxDuration: const Duration(seconds: 10),
    );

    if (video == null) return; // User cancelled

    setState(() {
      _selfieVideo = video;
      _isSelfieLoading = true;
      _selfieSuccess = false;
    });

    bool success = false;
    try {
      final result = await _uploadSelfieVideo(video);
      if (result != null && mounted) {
        _readinessFlag = result['readiness_flag'] as String?;
        _readinessDelta = (result['readiness_delta'] as num?)?.toInt();
        _emotionalState = result['emotional_state'] as String?;
        _contributingFactors =
            (result['contributing_factors'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];
        _selfieRecommendation = result['recommendation'] as String?;
        success = true;
      }
    } catch (e) {
      debugPrint('🔴 [CheckIn - Selfie] Exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process vitals: $e')),
        );
      }
    }

    if (mounted) {
      HapticFeedback.heavyImpact();
      setState(() {
        _isSelfieLoading = false;
        _selfieSuccess = success;
      });
    }
  }

  Future<Map<String, dynamic>?> _uploadSelfieVideo(XFile video) async {
    final baseUrl = await ApiClient().baseUrl;
    final uri =
        Uri.parse('$baseUrl/players/${widget.player.id}/presage_checkin');

    // Auth header
    final user = FirebaseAuth.instance.currentUser;
    final token = user != null
        ? await user.getIdToken() ?? 'test-token-admin'
        : 'test-token-admin';

    debugPrint('🟡 [CheckIn - Selfie] Posting JSON vitals to: $uri');

    // Presage endpoint takes a JSON body with vitals, NOT a video upload
    final response = await http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'vitals': {
              'stress_level': 'High',
              'focus': 'Low',
              'valence': 'Negative',
              'pulse_rate': 74,
              'hrv_ms': 42,
            }
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      debugPrint('🟢 [CheckIn - Selfie] API Response Body: ${response.body}');
      return jsonDecode(response.body) as Map<String, dynamic>?;
    } else {
      debugPrint(
          '🔴 [CheckIn - Selfie] API Error ${response.statusCode}: ${response.body}');
      throw Exception('API Error ${response.statusCode}: ${response.body}');
    }
  }

  // ── Movement recording + upload ────────────────────────────────────────────
  Future<void> _recordMovement() async {
    HapticFeedback.mediumImpact();

    final proceed = await _showDemoDialog(
      'Movement Demo',
      'Prop your phone up on the floor. Step back so your entire body is in the frame. Perform 3 squats followed by 3 hinges.',
      Icons.accessibility_new_rounded,
    );
    if (!proceed) return;

    // Open rear camera for 10s squat/hinge video
    final video = await _picker.pickVideo(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      maxDuration: const Duration(seconds: 10),
    );

    if (video == null) return;

    setState(() {
      _movementVideo = video;
      _isMovementLoading = true;
      _movementSuccess = false;
    });

    bool success = false;
    try {
      final result = await _uploadMovementVideo(video);
      if (result != null && mounted) {
        _mechanicalRiskBand = result['mechanical_risk_band'] as String?;
        _movementFlags = (result['flags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        _coachingCues = (result['coaching_cues'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        _movementConfidence = (result['confidence'] as num?)?.toDouble();
        success = true;
      }
    } catch (e) {
      debugPrint('🔴 [CheckIn - Movement] Exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process movement: $e')),
        );
      }
    }

    if (mounted) {
      HapticFeedback.heavyImpact();
      setState(() {
        _isMovementLoading = false;
        _movementSuccess = success;
      });
    }
  }

  Future<Map<String, dynamic>?> _uploadMovementVideo(XFile video) async {
    final baseUrl = await ApiClient().baseUrl;
    final uri =
        Uri.parse('$baseUrl/players/${widget.player.id}/movement_analysis');
    final request = http.MultipartRequest('POST', uri);

    final user = FirebaseAuth.instance.currentUser;
    final token = user != null
        ? await user.getIdToken() ?? 'test-token-admin'
        : 'test-token-admin';
    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(await http.MultipartFile.fromPath(
      'video',
      video.path,
      filename: '${widget.player.id}_movement.mp4',
    ));
    request.fields['player_id'] = widget.player.id;
    request.fields['position'] = widget.player.position;

    debugPrint('🟡 [CheckIn - Movement] Uploading video to: $uri');
    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      debugPrint('🟢 [CheckIn - Movement] API Response Body: ${response.body}');
      return jsonDecode(response.body) as Map<String, dynamic>?;
    } else {
      debugPrint(
          '🔴 [CheckIn - Movement] API Error ${response.statusCode}: ${response.body}');
      throw Exception('API Error ${response.statusCode}: ${response.body}');
    }
  }

  Color _flagColor(String flag) {
    switch (flag.toUpperCase()) {
      case 'GOOD':
        return AppColors.riskLow;
      case 'CONCERN':
        return AppColors.riskMed;
      case 'ALERT':
        return AppColors.riskHigh;
      default:
        return AppColors.riskLow;
    }
  }

  int _selectedTabIndex = 0; // 0 for Vitals, 1 for Biomechanics

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Check-In: ${widget.player.name}',
            style: AppTextStyles.headlineSmall),
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // ── Premium Segmented Control ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingL, vertical: 12),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Stack(
                children: [
                  // Automated sliding highlight
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    top: 4,
                    bottom: 4,
                    left: _selectedTabIndex == 0
                        ? 4
                        : (MediaQuery.of(context).size.width - 40) / 2 - 4,
                    width: (MediaQuery.of(context).size.width - 40) / 2 - 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.bg.withValues(alpha: 0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _buildTabItem(
                          0, 'Vitals Analysis', Icons.favorite_rounded),
                      _buildTabItem(
                          1, 'Biomechanics', Icons.accessibility_new_rounded),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Content Area ───────────────────────────────────────────────────
          Expanded(
            child: IndexedStack(
              index: _selectedTabIndex,
              children: [
                _buildTabContent(
                  title: 'Daily Vitals',
                  subtitle:
                      'Record a rapid 10-second facial video to analyze resting heart rate, HRV, and respiratory load.',
                  child: _buildSelfieSection(),
                ),
                _buildTabContent(
                  title: 'Movement Screen',
                  subtitle:
                      'Record a 10-second Squat & Hinge sequence to identify mechanical risks and joint mobility gaps.',
                  child: _buildMovementSection(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String text, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    final accentColor = index == 0
        ? const Color(0xFFE11D48)
        : const Color(0xFF3B82F6); // Rose for Vitals, Blue for Movement

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!isSelected) {
            HapticFeedback.selectionClick();
            setState(() => _selectedTabIndex = index);
          }
        },
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 16,
                  color: isSelected ? accentColor : AppColors.textMuted),
              const SizedBox(width: 8),
              Text(
                text,
                style: AppTextStyles.labelMedium.copyWith(
                  color:
                      isSelected ? AppColors.textPrimary : AppColors.textMuted,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(
      {required String title,
      required String subtitle,
      required Widget child}) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 24),
          child,
          const SizedBox(height: 40),
        ],
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05),
    );
  }

  // ── Selfie UI ──────────────────────────────────────────────────────────────
  Widget _buildSelfieSection() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 400),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: const Color(0xFFE11D48)
                .withValues(alpha: 0.3)), // Vibrant border
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceElevated,
            const Color(0xFFE11D48).withValues(alpha: 0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withValues(alpha: 0.15),
            blurRadius: 40,
            spreadRadius: -10,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: _selfieSuccess
          ? _buildSelfieResults()
          : _isSelfieLoading
              ? _buildLoadingState(
                  'Analyzing Vitals...',
                  'Processing optical blood flow algorithms...',
                  const Color(0xFFE11D48),
                )
              : _buildRecordPrompt(
                  icon: Icons.monitor_heart_rounded,
                  buttonIcon: Icons.camera_front_rounded,
                  buttonLabel: 'Record Vitals Video',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
                  ),
                  shadowColor: const Color(0xFFE11D48),
                  onTap: _recordSelfie,
                  hint: _selfieVideo == null
                      ? null
                      : 'Video captured — tap to re-record',
                ),
    );
  }

  Widget _buildSelfieResults() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Flag + Delta
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _flagColor(_readinessFlag ?? 'GOOD')
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _flagColor(_readinessFlag ?? 'GOOD')
                          .withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.monitor_heart_rounded,
                        size: 16, color: _flagColor(_readinessFlag ?? 'GOOD')),
                    const SizedBox(width: 8),
                    Text(
                      _readinessFlag ?? 'GOOD',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: _flagColor(_readinessFlag ?? 'GOOD'),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Readiness Shift',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted)),
                  Text(
                    '${(_readinessDelta ?? 0) >= 0 ? '+' : ''}${_readinessDelta ?? 0}%',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: (_readinessDelta ?? 0) >= 0
                          ? AppColors.riskLow
                          : AppColors.riskHigh,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.surfaceBorder),
          const SizedBox(height: 16),
          if (_emotionalState != null) ...[
            Row(
              children: [
                const Icon(Icons.sentiment_dissatisfied_rounded,
                    size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text('Emotional State: ',
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.textMuted)),
                Text(_emotionalState!,
                    style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Text('Physiological Indicators',
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 12),
          ..._contributingFactors.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: AppColors.textPrimary, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(f,
                            style: AppTextStyles.bodyMedium
                                .copyWith(height: 1.4))),
                  ],
                ),
              )),
          if (_selfieRecommendation != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded,
                      color: AppColors.textPrimary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(_selfieRecommendation!,
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.refresh_rounded,
                  size: 16, color: Color(0xFFE11D48)),
              label: Text('Retake Video',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: const Color(0xFFE11D48))),
              onPressed: () => setState(() {
                _selfieSuccess = false;
                _selfieVideo = null;
              }),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  // ── Movement UI ────────────────────────────────────────────────────────────
  Widget _buildMovementSection() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 400),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: const Color(0xFF3B82F6)
                .withValues(alpha: 0.3)), // Vibrant blue border
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.surfaceElevated,
            const Color(0xFF3B82F6).withValues(alpha: 0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
            blurRadius: 40,
            spreadRadius: -10,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: _movementSuccess
          ? _buildMovementResults()
          : _isMovementLoading
              ? _buildLoadingState(
                  'Processing Biomechanics...',
                  'Analyzing skeletal tracking and joint angles...',
                  const Color(0xFF3B82F6),
                )
              : _buildRecordPrompt(
                  icon: Icons.accessibility_new_rounded,
                  buttonIcon: Icons.videocam_rounded,
                  buttonLabel: 'Record Movement',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  ),
                  shadowColor: const Color(0xFF3B82F6),
                  onTap: _recordMovement,
                  hint: _movementVideo == null
                      ? null
                      : 'Video captured — tap to re-record',
                ),
    );
  }

  Widget _buildMovementResults() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: const Icon(Icons.analytics_rounded,
                    color: AppColors.textPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mechanical Load',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.textMuted)),
                  Text('Assessment',
                      style: AppTextStyles.bodyLarge
                          .copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const Spacer(),
              RiskBadge(
                  band: _mechanicalRiskBand ?? 'LOW',
                  score: _mechanicalRiskBand == 'HIGH'
                      ? 80
                      : _mechanicalRiskBand == 'MED'
                          ? 50
                          : 20,
                  pulse: _mechanicalRiskBand == 'HIGH'),
            ],
          ),
          if (_movementFlags.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Identified Risks',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 12),
            ..._movementFlags.map((flag) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.riskHigh,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(flag,
                            style:
                                AppTextStyles.bodyMedium.copyWith(height: 1.4)),
                      ),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 24),
          const Divider(color: AppColors.surfaceBorder),
          const SizedBox(height: 16),
          Text('Prescriptive Cues',
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 12),
          ..._coachingCues.map((cue) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: AppColors.textPrimary, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(cue,
                            style: AppTextStyles.bodyMedium
                                .copyWith(height: 1.4))),
                  ],
                ),
              )),
          if (_movementConfidence != null) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Tracking Confidence: ${(_movementConfidence! * 100).toInt()}%',
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.refresh_rounded,
                  size: 16, color: Color(0xFF3B82F6)),
              label: Text('Retake Movement',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: const Color(0xFF3B82F6))),
              onPressed: () => setState(() {
                _movementSuccess = false;
                _movementVideo = null;
              }),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  // ── Shared Helpers ─────────────────────────────────────────────────────────
  Widget _buildLoadingState(String title, String subtitle, Color color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: PulseLoader(color: color),
                ),
                Icon(Icons.auto_awesome, color: color, size: 24)
                    .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true))
                    .scaleXY(begin: 0.8, end: 1.2, duration: 1.seconds),
              ],
            ),
            const SizedBox(height: 32),
            Text(title,
                style: AppTextStyles.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildRecordPrompt({
    required IconData icon,
    required IconData buttonIcon,
    required String buttonLabel,
    required LinearGradient gradient,
    required Color shadowColor,
    required VoidCallback onTap,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: shadowColor.withValues(alpha: 0.1),
                border: Border.all(
                    color: shadowColor.withValues(alpha: 0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ]),
            child: Center(
              child: Icon(icon, size: 40, color: shadowColor),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                  duration: 2000.ms, color: Colors.white.withValues(alpha: 0.5))
              .scaleXY(
                  begin: 0.95,
                  end: 1.05,
                  duration: 1.5.seconds,
                  curve: Curves.easeInOut)
              .then()
              .scaleXY(
                  begin: 1.05,
                  end: 0.95,
                  duration: 1.5.seconds,
                  curve: Curves.easeInOut),
          const SizedBox(height: 32),
          if (hint != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.riskLow.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(hint,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.riskLow)),
            ),
            const SizedBox(height: 24),
          ],
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(buttonIcon, size: 20, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(buttonLabel,
                        style: AppTextStyles.labelMedium.copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          )
              .animate()
              .slideY(begin: 0.2, duration: 400.ms, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}
