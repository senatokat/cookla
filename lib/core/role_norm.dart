String normRole(dynamic value) {
  final s = (value ?? '').toString().trim().toLowerCase();

  // Kullanıcı rolleri form, Firestore ve eski kayıtlardan farklı yazımlarla gelebilir.
  switch (s) {
    case 'user':
    case 'genel kullanıcı':
    case 'general':
      return 'user';

    case 'student':
    case 'öğrenci':
    case 'ogrenci':
    case 'gastronomi öğrencisi':
    case 'gastronomi ogrencisi':
      return 'student';

    case 'chef':
    case 'şef':
      return 'chef';

    case 'dietitian':
    case 'diyetisyen':
    case 'nutritionist':
      return 'dietitian';

    case 'admin':
      return 'admin';

    default:
      return s;
  }
}

class AppRoles {
  AppRoles._();

  static const String user = 'user';
  static const String student = 'student';
  static const String chef = 'chef';
  static const String dietitian = 'dietitian';
  static const String admin = 'admin';

  static String normalize(dynamic value) {
    return normRole(value);
  }

  static bool isAdmin(String? role) {
    return normRole(role) == admin;
  }

  static bool isChef(String? role) {
    return normRole(role) == chef;
  }

  static bool isStudent(String? role) {
    return normRole(role) == student;
  }

  static bool isDietitian(String? role) {
    return normRole(role) == dietitian;
  }

  static bool isUser(String? role) {
    return normRole(role) == user;
  }

  static bool isChefOrAdmin(String? role) {
    final r = normRole(role);
    return r == chef || r == admin;
  }

  static bool canRequestWorkshop(String? role) {
    final r = normRole(role);
    return r == user || r == student;
  }
}

bool isAdminRole(String? role) => AppRoles.isAdmin(role);
bool isChefRole(String? role) => AppRoles.isChef(role);
bool isStudentRole(String? role) => AppRoles.isStudent(role);
bool isDietitianRole(String? role) => AppRoles.isDietitian(role);
bool isUserRole(String? role) => AppRoles.isUser(role);
bool isChefOrAdmin(String? role) => AppRoles.isChefOrAdmin(role);
bool canRequestWorkshop(String? role) => AppRoles.canRequestWorkshop(role);
