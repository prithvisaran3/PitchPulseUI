import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Wraps the native iOS SmartSpectra (Presage) SDK via a Flutter MethodChannel.
///
/// When the SDK is NOT yet linked in Xcode, every call returns
/// `{face_detected: false, sdk_available: false}` — the app never crashes.
class PresageService {
  PresageService._();

  static const _channel = MethodChannel('com.pitchpulse/presage');

  /// Runs a real Presage biometric face-scan (≈30 s on-device).
  ///
  /// Returns a vitals map that can be sent directly to POST /presage_checkin:
  /// ```json
  /// {
  ///   "face_detected": true,
  ///   "pulse_rate": 68,
  ///   "hrv_ms": 58,
  ///   "breathing_rate": 14,
  ///   "stress_level": "Normal",
  ///   "focus": "High",
  ///   "valence": "Positive",
  ///   "confidence": 0.91
  /// }
  /// ```
  /// On any error (SDK not linked, camera denied, timeout) returns:
  /// `{"face_detected": false}` — the backend handles this gracefully.
  static Future<Map<String, dynamic>> measureVitals({
    double duration = 30.0,
  }) async {
    final apiKey =
        dotenv.env['PRESAGE_API_KEY'] ?? 'G7vYKtya6Z8Qbb9ityoZh25MkdcbwJendXib7F82';

    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'measureVitals',
        {'apiKey': apiKey, 'duration': duration},
      );

      if (raw == null) return {'face_detected': false};

      final vitals = Map<String, dynamic>.from(raw);
      debugPrint('🟢 [Presage] Measurement complete: $vitals');
      return vitals;
    } on PlatformException catch (e) {
      debugPrint('🔴 [Presage] PlatformException: ${e.code} — ${e.message}');
      return {'face_detected': false, 'error': e.message ?? 'platform_error'};
    } catch (e) {
      debugPrint('🔴 [Presage] Unexpected error: $e');
      return {'face_detected': false};
    }
  }

  /// Dismisses any Presage native screen still on top of Flutter.
  /// Call this once at app startup / after every hot restart so the
  /// Presage scan view never blocks the UI.
  static Future<void> dismissIfPresented() async {
    try {
      await _channel.invokeMethod<void>('dismissNativeOverlay');
    } catch (_) {
      // Ignore — channel not available on non-iOS or during first launch
    }
  }

  /// Returns true only when the SmartSpectra SDK is linked in Xcode.
  static Future<bool> get isSdkAvailable async {
    try {
      final result = await _channel.invokeMethod<bool>('sdkAvailable');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
