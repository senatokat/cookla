import 'package:flutter/material.dart';

import '../../../../core/constants.dart';
import '../../models/workshop.dart';

class WorkshopCard extends StatelessWidget {
  final Workshop workshop;
  final VoidCallback? onTap;

  const WorkshopCard({super.key, required this.workshop, this.onTap});

  String _dateText(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year;
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');

    return '$dd.$mm.$yy  $hh:$min';
  }

  String _durationText(int minutes) {
    if (minutes <= 0) return 'Belirtilmedi';

    final h = minutes ~/ 60;
    final m = minutes % 60;

    if (h > 0 && m > 0) return '$h saat $m dk';
    if (h > 0) return '$h saat';
    return '$m dk';
  }

  @override
  Widget build(BuildContext context) {
    final description = workshop.description.trim();
    final metaText =
        '${workshop.ratingCount} degerlendirme - ${workshop.chefName}';

    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C68412D),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        workshop.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: kTextPrimary,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _InfoBadge(
                      icon: Icons.star_rounded,
                      label: workshop.ratingAverage.toStringAsFixed(1),
                      iconColor: const Color(0xFFF7B500),
                      textColor: kTextPrimary,
                      expandLabel: false,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  metaText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: kTextSecondary,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: kTextSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _InfoBadge(
                        icon: Icons.location_on_outlined,
                        label: workshop.location,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoBadge(
                        icon: Icons.calendar_today_rounded,
                        label: _dateText(workshop.date),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _InfoBadge(
                        icon: Icons.people_alt_outlined,
                        label: 'Kontenjan ${workshop.capacity}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoBadge(
                        icon: Icons.access_time_rounded,
                        label: _durationText(workshop.durationMinutes),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final Color? textColor;
  final bool expandLabel;

  const _InfoBadge({
    required this.icon,
    required this.label,
    this.iconColor,
    this.textColor,
    this.expandLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 38),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: kPrimaryMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: expandLabel ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor ?? kPrimary),
          const SizedBox(width: 8),
          if (expandLabel)
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor ?? kTextPrimary,
                ),
              ),
            )
          else
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor ?? kTextPrimary,
              ),
            ),
        ],
      ),
    );
  }
}
