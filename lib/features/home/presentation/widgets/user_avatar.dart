import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final double radius;

  const UserAvatar({super.key, required this.photoUrl, required this.radius});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    if (hasPhoto) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.black.withAlpha(15),
        backgroundImage: NetworkImage(photoUrl!),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.black.withAlpha(15),
      child: const Icon(Icons.person_outline, color: Colors.black54),
    );
  }
}
