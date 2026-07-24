import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/constants.dart';

class TagsStep extends StatefulWidget {
  final String title;
  final List<String> items;
  final Set<String> selected;

  const TagsStep({
    super.key,
    required this.title,
    required this.items,
    required this.selected,
  });

  @override
  State<TagsStep> createState() => _TagsStepState();
}

class _TagsStepState extends State<TagsStep> {
  static const orange = kPrimary;

  static const Map<String, String> _emoji = {
    "Özel Gün": "🎉",
    "Sağlıklı": "🥗",
    "Soğuk içecekler": "🧊",
    "Diyet Tarifleri": "📉",
    "Kolay Pişirilen": "⚡",
    "Glutensiz": "🚫🌾",
    "Atıştırmalıklar": "🍿",
    "Tatlılar": "🍰",
  };

  String _e(String name) => _emoji[name] ?? "🏷️";

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final t in widget.items)
                    FilterChip(
                      label: Text("${_e(t)} $t"),
                      selected: widget.selected.contains(t),
                      onSelected: (v) => setState(() {
                        if (v) {
                          widget.selected.add(t);
                        } else {
                          widget.selected.remove(t);
                        }
                      }),
                      selectedColor: orange,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: widget.selected.contains(t)
                            ? Colors.white
                            : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: StadiumBorder(
                        side: BorderSide(color: orange.withAlpha(153)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
