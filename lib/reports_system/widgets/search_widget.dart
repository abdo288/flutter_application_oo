import 'package:flutter/material.dart';

/// Widget للبحث
class SearchWidget extends StatefulWidget {
  const SearchWidget({
    super.key,
    required this.onSearchChanged,
    this.hintText = 'البحث...',
    this.debounceDuration = const Duration(milliseconds: 500),
    this.showClearButton = true,
    this.showFilterButton = false,
    this.onFilterPressed,
  });

  final ValueChanged<String> onSearchChanged;
  final String hintText;
  final Duration debounceDuration;
  final bool showClearButton;
  final bool showFilterButton;
  final VoidCallback? onFilterPressed;

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  late TextEditingController _controller;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isSearching ? Colors.blue : Colors.grey[300]!,
        ),
      ),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: Colors.grey[500],
          ),
          prefixIcon: Icon(
            Icons.search,
            color: _isSearching ? Colors.blue : Colors.grey[500],
          ),
          suffixIcon: _buildSuffixIcon(),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: _onSearchChanged,
        onTap: () {
          setState(() {
            _isSearching = true;
          });
        },
        onSubmitted: (String value) {
          setState(() {
            _isSearching = false;
          });
        },
      ),
    );

  Widget? _buildSuffixIcon() {
    if (_controller.text.isNotEmpty && widget.showClearButton) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            onPressed: _clearSearch,
            icon: const Icon(Icons.clear),
            iconSize: 20,
            color: Colors.grey[500],
          ),
          if (widget.showFilterButton) ...<Widget>[
            IconButton(
              onPressed: widget.onFilterPressed,
              icon: const Icon(Icons.filter_list),
              iconSize: 20,
              color: Colors.grey[500],
            ),
          ],
        ],
      );
    } else if (widget.showFilterButton) {
      return IconButton(
        onPressed: widget.onFilterPressed,
        icon: const Icon(Icons.filter_list),
        iconSize: 20,
        color: Colors.grey[500],
      );
    }
    return null;
  }

  void _onSearchChanged(String value) {
    widget.onSearchChanged(value);
  }

  void _clearSearch() {
    _controller.clear();
    widget.onSearchChanged('');
    setState(() {
      _isSearching = false;
    });
  }
}

/// Widget للبحث المتقدم
class AdvancedSearchWidget extends StatefulWidget {
  const AdvancedSearchWidget({
    super.key,
    required this.onSearchChanged,
    this.filters = const <SearchFilter>[],
    this.title = 'البحث المتقدم',
  });

  final ValueChanged<Map<String, dynamic>> onSearchChanged;
  final List<SearchFilter> filters;
  final String title;

  @override
  State<AdvancedSearchWidget> createState() => _AdvancedSearchWidgetState();
}

class _AdvancedSearchWidgetState extends State<AdvancedSearchWidget> {
  final Map<String, dynamic> _searchValues = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    for (final SearchFilter filter in widget.filters) {
      _searchValues[filter.key] = filter.defaultValue;
    }
  }

  @override
  Widget build(BuildContext context) => Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // العنوان
            Row(
              children: <Widget>[
                const Icon(Icons.search, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text('إعادة تعيين'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // الفلاتر
            ...widget.filters.map(_buildFilter),

            const SizedBox(height: 16),

            // أزرار الإجراءات
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('إلغاء'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _applySearch,
                  child: const Text('بحث'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

  Widget _buildFilter(SearchFilter filter) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            filter.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _buildFilterWidget(filter),
        ],
      ),
    );

  Widget _buildFilterWidget(SearchFilter filter) {
    switch (filter.type) {
      case SearchFilterType.text:
        return TextField(
          decoration: InputDecoration(
            hintText: filter.hintText,
            border: const OutlineInputBorder(),
          ),
          onChanged: (String value) {
            _searchValues[filter.key] = value;
          },
        );

      case SearchFilterType.dropdown:
        return DropdownButtonFormField<String>(
          initialValue: _searchValues[filter.key] as String?,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: filter.options?.map((String option) => DropdownMenuItem(
              value: option,
              child: Text(option),
            )).toList(),
          onChanged: (String? value) {
            setState(() {
              _searchValues[filter.key] = value;
            });
          },
        );

      case SearchFilterType.date:
        return InkWell(
          onTap: () async {
            final DateTime? date = await showDatePicker(
              context: context,
              initialDate:
                  _searchValues[filter.key] as DateTime? ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() {
                _searchValues[filter.key] = date;
              });
            }
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(
              _searchValues[filter.key] != null
                  ? '${(_searchValues[filter.key] as DateTime).day}/${(_searchValues[filter.key] as DateTime).month}/${(_searchValues[filter.key] as DateTime).year}'
                  : 'اختر التاريخ',
            ),
          ),
        );

      case SearchFilterType.range:
        return Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'من',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (String value) {
                  _searchValues['${filter.key}_min'] = double.tryParse(value);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'إلى',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (String value) {
                  _searchValues['${filter.key}_max'] = double.tryParse(value);
                },
              ),
            ),
          ],
        );
    }
  }

  void _applySearch() {
    widget.onSearchChanged(_searchValues);
    Navigator.of(context).pop();
  }

  void _resetFilters() {
    setState(() {
      for (final SearchFilter filter in widget.filters) {
        _searchValues[filter.key] = filter.defaultValue;
      }
    });
  }
}

/// فلتر البحث
class SearchFilter {
  const SearchFilter({
    required this.key,
    required this.label,
    required this.type,
    this.hintText,
    this.options,
    this.defaultValue,
  });

  final String key;
  final String label;
  final SearchFilterType type;
  final String? hintText;
  final List<String>? options;
  final dynamic defaultValue;
}

/// نوع فلتر البحث
enum SearchFilterType {
  text,
  dropdown,
  date,
  range,
}
