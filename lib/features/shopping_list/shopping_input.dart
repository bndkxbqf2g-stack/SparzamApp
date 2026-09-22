import 'package:flutter/material.dart';

class ShoppingInput extends StatelessWidget {
  const ShoppingInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmit,
    required this.onOpenScanner,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onOpenScanner;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: (_) => onChanged(),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => onSubmit(),
        decoration: InputDecoration(
          hintText: 'Was möchtest du einkaufen?',
          prefixIcon: const Icon(Icons.add_circle_outline),
          suffixIcon: controller.text.isEmpty
              ? IconButton(
                  tooltip: 'Barcode scannen',
                  onPressed: onOpenScanner,
                  icon: const Icon(Icons.qr_code_scanner),
                )
              : IconButton(
                  tooltip: 'Eingabe löschen',
                  onPressed: () {
                    controller.clear();
                    onChanged();
                  },
                  icon: const Icon(Icons.close),
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      );
