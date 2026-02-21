class AppUser {
  final String uid;
  final String email;
  final String role;
  final List<String> workspaceIds;
  final String? displayName;

  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.workspaceIds,
    this.displayName,
  });

  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager';

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        uid: json['uid'] as String,
        email: json['email'] as String,
        role: json['role'] as String? ?? 'manager',
        workspaceIds: (json['workspace_ids'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        displayName: json['display_name'] as String?,
      );

  // Demo / fallback constructor
  factory AppUser.demo({required String uid, required String email, required String role}) =>
      AppUser(uid: uid, email: email, role: role, workspaceIds: ['demo-workspace-001']);
}
