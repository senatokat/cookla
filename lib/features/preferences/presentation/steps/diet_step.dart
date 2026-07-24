import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/constants.dart';

class DietStep extends StatelessWidget {
  final String title;
  final String? selectedDiet;
  final ValueChanged<String?> onSelect;

  const DietStep({
    super.key,
    required this.title,
    required this.selectedDiet,
    required this.onSelect,
  });

  static const orange = kPrimary;

  void _handleTap(String key) {
    onSelect(selectedDiet == key ? null : key);
  }

  Widget _card(String key, String label, String emoji) {
    final isSelected = selectedDiet == key;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _handleTap(key),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
        child: Center(
          child: Text(
            "$emoji  $label",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isSelected ? orange : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _card("vegetarian", "Vejetaryen", "🥦"),
                _card("sugarfree", "Şekersiz", "🍬🚫"),
                _card("carnivore", "Karnivor", "🥩"),
                _card("vegan", "Vegan", "🌱"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
