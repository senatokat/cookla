import 'package:cloud_firestore/cloud_firestore.dart';

class AppClock {
  const AppClock._();

  static DateTime now() => DateTime.now().toLocal();

  static Timestamp timestampNow() => Timestamp.fromDate(now());

  static String compactDateTime([DateTime? value]) {
    final date = (value ?? now()).toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day.$month.${date.year} $hour:$minute';
  }

  static String compactDate(DateTime value) {
    final date = value.toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}
