class WorkshopAttendee {
  final String uid;
  final String userName;
  final String userEmail;
  final String requestStatus;
  final String attendanceStatus; // pending / attended / absent

  const WorkshopAttendee({
    required this.uid,
    required this.userName,
    required this.userEmail,
    required this.requestStatus,
    required this.attendanceStatus,
  });

  factory WorkshopAttendee.fromMap(String uid, Map<String, dynamic> data) {
    return WorkshopAttendee(
      uid: uid,
      userName: (data['userName'] ?? '').toString(),
      userEmail: (data['userEmail'] ?? '').toString(),
      requestStatus: (data['status'] ?? 'pending')
          .toString()
          .trim()
          .toLowerCase(),
      attendanceStatus: (data['attendanceStatus'] ?? 'pending')
          .toString()
          .trim()
          .toLowerCase(),
    );
  }
}
