import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/constants.dart';

class AllergiesStep extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<String> items;
  final Set<String> selected;

  const AllergiesStep({
    super.key,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.selected,
  });

  @override
  State<AllergiesStep> createState() => _AllergiesStepState();
}

class _AllergiesStepState extends State<AllergiesStep> {
  static const orange = kPrimary;

  static const Map<String, String> _emoji = {
    "Yumurta": "🥚",
    "Balık": "🐟",
    "Badem": "🥜",
    "Gluten": "🌾",
    "Çikolata": "🍫",
    "Avokado": "🥑",
    "Hardal": "🟡",
    "Şeftali": "🍑",
    "Fındık": "🌰",
    "Soya": "🫘",
    "Süt": "🥛",
    "Kakao": "🍫",
    "Ceviz": "🌰",
  };

  String _e(String name) => _emoji[name] ?? "⚠️";

  void _toggle(String a, bool selected) {
    setState(() {
      if (selected) {
        widget.selected.add(a);
      } else {
        widget.selected.remove(a);
      }
    });
  }

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
          const SizedBox(height: 8),
          Text(widget.subtitle, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 14),

          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final a in widget.items)
                    Builder(
                      builder: (_) {
                        final isSelected = widget.selected.contains(a);

                        return ChoiceChip(
                          label: Text("${_e(a)} $a"),
                          selected: isSelected,
                          onSelected: (v) => _toggle(a, v),

                          selectedColor: orange,
                          backgroundColor: Colors.white,

                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),

                          shape: StadiumBorder(
                            side: BorderSide(color: orange.withAlpha(153)),
                          ),
                        );
                      },
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
