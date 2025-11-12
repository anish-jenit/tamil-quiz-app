import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AvatarPicker extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const AvatarPicker({super.key, this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1,
      children: Constants.avatars.map((id) {
        final isSelected = id == selected;
        return GestureDetector(
          onTap: () => onChanged(id),
            child: Card(
            elevation: isSelected ? 6 : 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: isSelected ? Theme.of(context).colorScheme.primary.withAlpha((0.08 * 255).round()) : null,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey.shade100,
                  backgroundImage: AssetImage('assets/avatars/$id.png'),
                  onBackgroundImageError: (error, stack) {},
                  child: ClipOval(
                    child: Image.asset(
                      'assets/avatars/$id.png',
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => Icon(Icons.person, size: 32, color: Colors.grey.shade700),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
