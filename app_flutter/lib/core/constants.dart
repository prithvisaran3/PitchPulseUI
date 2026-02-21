class AppConstants {
  AppConstants._();

  // Backend base URL — update when Roshini deploys
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://ferreous-semisaline-sean.ngrok-free.dev',
  );

  // Roshini's real workspace ID — pre-seeded with Real Madrid squad
  static const String demoWorkspaceId = 'test-workspace-1';
  static const String demoClubId = 'real-madrid';
  static const String demoFixtureId = 'demo-fixture-001';

  // App metadata
  static const String appName = 'PitchPulse';
  static const String appVersion = '1.0.0';

  // Roles
  static const String roleAdmin = 'admin';
  static const String roleManager = 'manager';

  // Risk bands
  static const String riskLow = 'LOW';
  static const String riskMed = 'MED';
  static const String riskHigh = 'HIGH';

  // Animation durations
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animMedium = Duration(milliseconds: 400);
  static const Duration animSlow = Duration(milliseconds: 600);
  static const Duration animBounce = Duration(milliseconds: 800);

  // Spacing
  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 16;
  static const double spacingL = 24;
  static const double spacingXL = 32;
  static const double spacingXXL = 48;

  // Border radius
  static const double radiusS = 8;
  static const double radiusM = 14;
  static const double radiusL = 20;
  static const double radiusXL = 28;
  static const double radiusCircle = 100;

  // Card elevation / blur
  static const double cardBlur = 20;
  static const double cardBgOpacity = 0.05;
}
