import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/constants.dart';
import 'package:flutter_application_1/features/home/models/ingredient_data.dart';

class IngredientsStep extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<String> items;
  final Set<String> selected;

  const IngredientsStep({
    super.key,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.selected,
  });

  @override
  State<IngredientsStep> createState() => _IngredientsStepState();
}

class _IngredientsStepState extends State<IngredientsStep> {
  static const orange = kPrimary;

  String _e(String name) => IngredientData.emojiFor(name);

  int _crossAxisCountFor(double width) {
    if (width < 360) return 3;
    if (width < 420) return 4;
    return 5;
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
            child: LayoutBuilder(
              builder: (context, c) {
                final crossAxisCount = _crossAxisCountFor(c.maxWidth);

                return GridView.builder(
                  itemCount: widget.items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.9,
                  ),
                  itemBuilder: (_, i) {
                    final name = widget.items[i];
                    final isSelected = widget.selected.contains(name);

                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() {
                        if (isSelected) {
                          widget.selected.remove(name);
                        } else {
                          widget.selected.add(name);
                        }
                      }),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? orange : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 8,
                              color: Color(0x11000000),
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Center(
                          child: Text(
                            '${_e(name)} $name',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? orange : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
