import 'package:flutter/material.dart';

import 'offer_filter.dart';

class OfferFilterBar extends StatelessWidget {
  const OfferFilterBar({
    super.key,
    required this.controller,
    required this.filter,
    required this.onQueryChanged,
    required this.onFilterChanged,
  });

  final TextEditingController controller;
  final OfferStatusFilter filter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<OfferStatusFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          TextField(
            controller: controller,
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              hintText: 'Produkt oder Markt suchen',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Suche löschen',
                      onPressed: () {
                        controller.clear();
                        onQueryChanged('');
                      },
                      icon: const Icon(Icons.close),
                    ),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<OfferStatusFilter>(
            segments: const [
              ButtonSegment(
                value: OfferStatusFilter.active,
                label: Text('Aktiv'),
              ),
              ButtonSegment(
                value: OfferStatusFilter.all,
                label: Text('Alle'),
              ),
              ButtonSegment(
                value: OfferStatusFilter.expired,
                label: Text('Abgelaufen'),
              ),
            ],
            selected: {filter},
            onSelectionChanged: (value) => onFilterChanged(value.first),
          ),
        ],
      );
}
