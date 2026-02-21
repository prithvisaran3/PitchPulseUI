import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/workspace_provider.dart';
import '../views/auth/login_screen.dart';
import '../views/home/manager_shell.dart';
import '../views/admin/admin_shell.dart';
import '../views/onboarding/club_select_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AuthStatus? _lastStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    // Trigger workspace load exactly once when auth becomes authenticated.
    // Use addPostFrameCallback to avoid calling notifyListeners during build.
    if (auth.status == AuthStatus.authenticated &&
        _lastStatus != AuthStatus.authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<WorkspaceProvider>().loadWorkspaces();
        }
      });
    }
    _lastStatus = auth.status;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final workspace = context.watch<WorkspaceProvider>();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: child,
      ),
      child: switch (auth.status) {
        AuthStatus.unknown => const _SplashScreen(),
        AuthStatus.unauthenticated => const LoginScreen(),
        AuthStatus.loading => const _SplashScreen(),
        AuthStatus.authenticated =>
          auth.isAdmin ? const AdminShell() : _managerRoute(workspace),
      },
    );
  }

  /// Routes an authenticated manager to home if they have a workspace,
  /// or to ClubSelectScreen if they're a brand-new user with no workspace.
  Widget _managerRoute(WorkspaceProvider workspace) {
    // Still fetching workspaces from the backend — show splash
    if (workspace.workspaceState == LoadState.loading ||
        workspace.workspaceState == LoadState.idle ||
        workspace.workspaceState == LoadState.error) {
      return const _SplashScreen();
    }

    // No workspace found — new user, must pick a club first
    if (workspace.workspaces.isEmpty || workspace.activeWorkspace == null) {
      return const ClubSelectScreen();
    }

    // Has an approved workspace — go straight to home
    return const ManagerShell();
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C18),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => Container(
                width: 80 + _controller.value * 4,
                height: 80 + _controller.value * 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4FACFE), Color(0xFF6E57FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4FACFE)
                          .withValues(alpha: 0.3 + _controller.value * 0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('⚽', style: TextStyle(fontSize: 36)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'PitchPulse',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Club Readiness Intelligence',
              style: TextStyle(color: Color(0xFF8FA3BF), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
