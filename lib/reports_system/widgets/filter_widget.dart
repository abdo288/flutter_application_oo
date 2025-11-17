import 'package:flutter/material.dart';

import '../models/common/date_range.dart';
import '../models/enums/payment_enums.dart';
import '../models/report_filter.dart';

/// Widget للفلاتر
class FilterWidget extends StatefulWidget {
  const FilterWidget({
    super.key,
    required this.filter,
    required this.onFilterChanged,
    this.showDateRange = true,
    this.showPaymentMethods = true,
    this.showEmployees = true,
    this.showSearch = true,
    this.showSort = true,
  });

  final ReportFilter filter;
  final ValueChanged<ReportFilter> onFilterChanged;
  final bool showDateRange;
  final bool showPaymentMethods;
  final bool showEmployees;
  final bool showSearch;
  final bool showSort;

  @override
  State<FilterWidget> createState() => _FilterWidgetState();
}

class _FilterWidgetState extends State<FilterWidget> {
  late TextEditingController _searchController;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: widget.filter.searchQuery ?? '');
    _startDate = widget.filter.dateRange?.startDate ??
        DateTime.now().subtract(const Duration(days: 30));
    _endDate = widget.filter.dateRange?.endDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            // عنوان الفلاتر
            Row(
              children: <Widget>[
                const Icon(Icons.filter_list, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'فلاتر البحث',
                  style: TextStyle(
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

            // البحث
            if (widget.showSearch) ...<Widget>[
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'البحث',
                  hintText: 'ابحث في المبيعات...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (String value) => _updateFilter(),
              ),
              const SizedBox(height: 16),
            ],

            // النطاق الزمني
            if (widget.showDateRange) ...<Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: _buildDateField(
                      'من تاريخ',
                      _startDate,
                      (DateTime date) {
                        setState(() {
                          _startDate = date;
                        });
                        _updateFilter();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateField(
                      'إلى تاريخ',
                      _endDate,
                      (DateTime date) {
                        setState(() {
                          _endDate = date;
                        });
                        _updateFilter();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // طرق الدفع
            if (widget.showPaymentMethods) ...<Widget>[
              const Text(
                'طرق الدفع',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: PaymentMethod.values.map((PaymentMethod method) {
                  final bool isSelected =
                      widget.filter.paymentMethods?.contains(method) ?? false;
                  return FilterChip(
                    label: Text(_getPaymentMethodLabel(method)),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      final List<PaymentMethod> methods = List<PaymentMethod>.from(
                          widget.filter.paymentMethods ?? <dynamic>[]);
                      if (selected) {
                        methods.add(method);
                      } else {
                        methods.remove(method);
                      }
                      widget.onFilterChanged(
                        widget.filter.copyWith(paymentMethods: methods),
                      );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // الموظفين
            if (widget.showEmployees) ...<Widget>[
              const Text(
                'الموظفين',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              // TODO: جلب قائمة الموظفين من الخدمة
              const Text(
                'قائمة الموظفين ستظهر هنا',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // الترتيب
            if (widget.showSort) ...<Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: DropdownButtonFormField<SortField>(
                      initialValue: widget.filter.sortBy ?? SortField.date,
                      decoration: const InputDecoration(
                        labelText: 'ترتيب حسب',
                        border: OutlineInputBorder(),
                      ),
                      items: SortField.values.map((SortField field) => DropdownMenuItem(
                          value: field,
                          child: Text(_getSortFieldLabel(field)),
                        )).toList(),
                      onChanged: (SortField? value) {
                        if (value != null) {
                          widget.onFilterChanged(
                            widget.filter.copyWith(sortBy: value),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<SortOrder>(
                      initialValue: widget.filter.sortOrder ?? SortOrder.descending,
                      decoration: const InputDecoration(
                        labelText: 'الاتجاه',
                        border: OutlineInputBorder(),
                      ),
                      items: SortOrder.values.map((SortOrder order) => DropdownMenuItem(
                          value: order,
                          child: Text(_getSortOrderLabel(order)),
                        )).toList(),
                      onChanged: (SortOrder? value) {
                        if (value != null) {
                          widget.onFilterChanged(
                            widget.filter.copyWith(sortOrder: value),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );

  Widget _buildDateField(
      String label, DateTime date, ValueChanged<DateTime> onChanged) => InkWell(
      onTap: () async {
        final DateTime? selectedDate = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (selectedDate != null) {
          onChanged(selectedDate);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          '${date.day}/${date.month}/${date.year}',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );

  void _updateFilter() {
    widget.onFilterChanged(
      widget.filter.copyWith(
        searchQuery:
            _searchController.text.isEmpty ? null : _searchController.text,
        dateRange: DateRange(
          startDate: _startDate,
          endDate: _endDate,
        ),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _startDate = DateTime.now().subtract(const Duration(days: 30));
      _endDate = DateTime.now();
    });

    widget.onFilterChanged(
      ReportFilter(
        dateRange: DateRange(
          startDate: _startDate,
          endDate: _endDate,
        ),
        searchQuery: '',
        sortBy: SortField.date,
        sortOrder: SortOrder.descending,
      ),
    );
  }

  String _getPaymentMethodLabel(PaymentMethod method) => method.description;

  String _getSortFieldLabel(SortField field) => field.description;

  String _getSortOrderLabel(SortOrder order) => order.description;
}
