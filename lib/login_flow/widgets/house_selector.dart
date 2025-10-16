import 'package:flutter/material.dart';
import '../utils/constants.dart';

class HouseSelector extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelected;

  const HouseSelector({super.key, this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
  final colors = [Colors.red, Colors.amber, Colors.blue, Colors.green];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      childAspectRatio: 2.5,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: List.generate(Constants.houses.length, (i) {
        final name = Constants.houses[i];
        final isSelected = selected == name;
        return GestureDetector(
          onTap: () => onSelected(name),
          child: Card(
            color: isSelected ? colors[i].withAlpha(76) : null,
            child: Center(child: Text(name)),
          ),
        );
      }),
    );
  }
}
