import 'package:flutter/material.dart';

class SolarInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final VoidCallback? onHelpTap;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const SolarInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.onHelpTap,
    this.onChanged,
    this.validator,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: onHelpTap != null 
            ? IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.green),
                onPressed: onHelpTap,
              )
            : null,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[50],
          errorMaxLines: 2,
        ),
      ),
    );
  }
}