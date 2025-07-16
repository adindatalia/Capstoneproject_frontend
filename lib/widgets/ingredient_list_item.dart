import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IngredientListItem extends StatelessWidget {
  final String ingredientName;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  const IngredientListItem({
    super.key,
    required this.ingredientName,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          )
        ],
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: onChanged,
        title: Text(ingredientName, style: GoogleFonts.lato(fontSize: 16)),
        secondary: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Text(
            ingredientName.isNotEmpty ? ingredientName[0].toUpperCase() : '?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        activeColor: Theme.of(context).primaryColor,
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }
}
