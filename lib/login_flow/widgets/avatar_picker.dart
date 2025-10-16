import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AvatarPicker extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const AvatarPicker({Key? key, this.selected, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      children: Constants.avatars.map((id) {
        final isSelected = id == selected;
        return GestureDetector(
          onTap: () => onChanged(id),
          child: Card(
            color: isSelected ? Colors.green[100] : null,
            child: Center(child: Text(id)),
          ),
        );
      }).toList(),
    );
  }
}
