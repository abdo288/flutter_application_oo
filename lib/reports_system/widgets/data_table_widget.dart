import 'package:flutter/material.dart';

/// Widget للجداول
class DataTableWidget extends StatelessWidget {
  const DataTableWidget({
    super.key,
    required this.columns,
    required this.rows,
    this.title,
    this.onSort,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.showCheckboxColumn = false,
    this.selectedRows = const <int>{},
    this.onRowSelected,
    this.pagination,
    this.onPageChanged,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final String? title;
  final ValueChanged<int>? onSort;
  final int? sortColumnIndex;
  final bool sortAscending;
  final bool showCheckboxColumn;
  final Set<int> selectedRows;
  final ValueChanged<int>? onRowSelected;
  final PaginationInfo? pagination;
  final ValueChanged<int>? onPageChanged;

  @override
  Widget build(BuildContext context) => Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null) ...<Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
          ],

          // الجدول
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columns: columns,
                  rows: rows,
                  sortColumnIndex: sortColumnIndex,
                  sortAscending: sortAscending,
                  onSelectAll: showCheckboxColumn ? _onSelectAll : null,
                  checkboxHorizontalMargin: showCheckboxColumn ? 12 : null,
                ),
              ),
            ),
          ),

          // الترقيم
          if (pagination != null) ...<Widget>[
            const Divider(height: 1),
            _buildPagination(),
          ],
        ],
      ),
    );

  void _onSelectAll(bool? value) {
    // TODO: تنفيذ تحديد الكل
  }

  Widget _buildPagination() => Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          // معلومات الصفحة
          Text(
            'عرض ${pagination!.startItem} إلى ${pagination!.endItem} من ${pagination!.totalItems} عنصر',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),

          // أزرار التنقل
          Row(
            children: <Widget>[
              IconButton(
                onPressed: pagination!.currentPage > 1
                    ? () => onPageChanged?.call(pagination!.currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'الصفحة السابقة',
              ),

              // أرقام الصفحات
              ...List.generate(
                pagination!.totalPages.clamp(0, 5),
                (int index) {
                  final int pageNumber = pagination!.currentPage - 2 + index;
                  if (pageNumber < 1 || pageNumber > pagination!.totalPages) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => onPageChanged?.call(pageNumber),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: pageNumber == pagination!.currentPage
                              ? Colors.blue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            pageNumber.toString(),
                            style: TextStyle(
                              color: pageNumber == pagination!.currentPage
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: pageNumber == pagination!.currentPage
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              IconButton(
                onPressed: pagination!.currentPage < pagination!.totalPages
                    ? () => onPageChanged?.call(pagination!.currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'الصفحة التالية',
              ),
            ],
          ),
        ],
      ),
    );
}

/// معلومات الترقيم
class PaginationInfo {
  const PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
  });

  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;

  int get startItem => (currentPage - 1) * itemsPerPage + 1;
  int get endItem => (currentPage * itemsPerPage).clamp(0, totalItems);
}

/// Widget للجدول المبسط
class SimpleTableWidget extends StatelessWidget {
  const SimpleTableWidget({
    super.key,
    required this.headers,
    required this.rows,
    this.title,
    this.headerStyle,
    this.cellStyle,
  });

  final List<String> headers;
  final List<List<String>> rows;
  final String? title;
  final TextStyle? headerStyle;
  final TextStyle? cellStyle;

  @override
  Widget build(BuildContext context) => Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null) ...<Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
          ],
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              border: TableBorder.all(
                color: Colors.grey.withOpacity(0.3),
              ),
              columnWidths: <int, TableColumnWidth>{
                for (int i = 0; i < headers.length; i++)
                  i: const FlexColumnWidth(),
              },
              children: <TableRow>[
                // رؤوس الأعمدة
                TableRow(
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                  ),
                  children: headers.map((String header) => Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        header,
                        style: headerStyle ??
                            const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    )).toList(),
                ),

                // البيانات
                ...rows.map((List<String> row) => TableRow(
                    children: row.map((String cell) => Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          cell,
                          style: cellStyle,
                          textAlign: TextAlign.center,
                        ),
                      )).toList(),
                  )),
              ],
            ),
          ),
        ],
      ),
    );
}
