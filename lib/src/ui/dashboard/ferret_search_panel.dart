import 'package:flutter/material.dart';

import '../ferret_filter.dart';

/// Search field and filter chips for the dashboard.
class FerretSearchPanel extends StatelessWidget {
  const FerretSearchPanel({
    super.key,
    required this.searchController,
    required this.searchFocus,
    required this.filter,
    required this.onQueryChanged,
    required this.onFilterChanged,
  });

  final TextEditingController searchController;
  final FocusNode searchFocus;
  final FerretFilter filter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<FerretFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: searchController,
            focusNode: searchFocus,
            decoration: InputDecoration(
              hintText: 'Search method, host, URL, status…',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
            onChanged: onQueryChanged,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              FilterChip(
                label: const Text('Failed'),
                selected: filter.failedOnly,
                onSelected: (v) {
                  onFilterChanged(filter.copyWith(failedOnly: v));
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Slow'),
                selected: filter.slowOnly,
                onSelected: (v) {
                  onFilterChanged(filter.copyWith(slowOnly: v));
                },
              ),
              const SizedBox(width: 8),
              for (final method in const [
                'GET',
                'POST',
                'PUT',
                'PATCH',
                'DELETE',
              ]) ...[
                FilterChip(
                  label: Text(method),
                  selected: filter.methods.contains(method),
                  onSelected: (v) {
                    final next = <String>{...filter.methods};
                    if (v) {
                      next.add(method);
                    } else {
                      next.remove(method);
                    }
                    onFilterChanged(filter.copyWith(methods: next));
                  },
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
