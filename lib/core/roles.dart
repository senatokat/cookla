String _normalizeEnumLike(
  dynamic value,
  Set<String> allowed, {
  required String fallback,
}) {
  final s = (value ?? '').toString().trim().toLowerCase();
  return allowed.contains(s) ? s : fallback;
}

class AppRoles {
  AppRoles._();

  static const String user = 'user';
  static const String student = 'student'; // gastronomi öğrencisi
  static const String chef = 'chef'; // şef + gastronomi öğretmeni
  static const String dietitian = 'dietitian';
  static const String admin = 'admin';

  static const Set<String> all = {user, chef, student, dietitian, admin};

  static bool isAdmin(String? role) => role == admin;
  static bool isUser(String? role) => role == user;
  static bool isChef(String? role) => role == chef;
  static bool isStudent(String? role) => role == student;
  static bool isDietitian(String? role) => role == dietitian;

  static bool isChefOrAdmin(String? role) => isChef(role) || isAdmin(role);

  static bool needsApproval(String? role) =>
      isChef(role) || isStudent(role) || isDietitian(role);

  static String normalize(dynamic value, {String fallback = user}) {
    return _normalizeEnumLike(value, all, fallback: fallback);
  }
}

class AppUserStatus {
  AppUserStatus._();

  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';

  static const Set<String> all = {pending, approved, rejected};

  static String normalize(dynamic value, {String fallback = pending}) {
    return _normalizeEnumLike(value, all, fallback: fallback);
  }

  static bool isApproved(String? status) => status == approved;
  static bool isPending(String? status) => status == pending;
  static bool isRejected(String? status) => status == rejected;
}

class RoleInfo {
  final String role; // user / chef / student / dietitian / admin
  final String status; // pending / approved / rejected

  const RoleInfo({required this.role, required this.status});

  bool get isAdmin => AppRoles.isAdmin(role);
  bool get isChef => AppRoles.isChef(role);
  bool get isStudent => AppRoles.isStudent(role);
  bool get isDietitian => AppRoles.isDietitian(role);

  bool get canManageWorkshops => AppRoles.isChefOrAdmin(role);

  bool get isApproved => AppUserStatus.isApproved(status);
  bool get isPending => AppUserStatus.isPending(status);
  bool get isRejected => AppUserStatus.isRejected(status);
}
