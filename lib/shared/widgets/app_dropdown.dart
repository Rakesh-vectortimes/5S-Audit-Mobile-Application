import 'package:flutter/material.dart';

/// Generic searchable-style dropdown used by org pickers.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.value,
    this.enabled = true,
    this.hint,
    this.isLoading = false,
    this.allowNone = false,
  });

  final String label;
  final List<T> items;
  final String Function(T item) itemLabel;
  final ValueChanged<T?> onChanged;
  final T? value;
  final bool enabled;
  final String? hint;
  final bool isLoading;
  final bool allowNone;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF1A1F1E),
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: Color(0xFF0F6B5C),
          fontWeight: FontWeight.w600,
        ),
        suffixIcon: isLoading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value != null && items.contains(value) ? value : null,
          hint: Text(
            hint ?? (allowNone ? 'None' : 'Select'),
            style: const TextStyle(color: Color(0xFF5C6B66)),
          ),
          items: [
            if (allowNone)
              DropdownMenuItem<T>(
                value: null,
                child: Text('None'),
              ),
            ...items.map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: enabled && !isLoading ? onChanged : null,
        ),
      ),
    );
  }
}
