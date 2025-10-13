import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/update_log.dart';
import '../services/realtime_update_service.dart';
import '../utils/responsive_breakpoints.dart';

/// Widget لعرض سجل التحديثات الفورية
class RealtimeUpdatesLog extends StatefulWidget {
  const RealtimeUpdatesLog({super.key});

  @override
  State<RealtimeUpdatesLog> createState() => _RealtimeUpdatesLogState();
}

class _RealtimeUpdatesLogState extends State<RealtimeUpdatesLog> {
  final RealtimeUpdateService _realtimeService = RealtimeUpdateService.instance;

  List<UpdateLog> _filteredLogs = <UpdateLog>[];
  String _searchQuery = '';
  String? _selectedType;
  String? _selectedAction;
  bool? _selectedStatus;
  bool _showOnlyErrors = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    setState(() {
      _filteredLogs = _realtimeService.updateLogs;
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredLogs = _realtimeService
          .searchUpdateLogs(
        type: _selectedType,
        action: _selectedAction,
        isSuccessful: _selectedStatus,
      )
          .where((UpdateLog log) {
        // البحث النصي
        if (_searchQuery.isNotEmpty) {
          final String query = _searchQuery.toLowerCase();
          if (!log.message.toLowerCase().contains(query) &&
              !log.type.toLowerCase().contains(query) &&
              !log.action.toLowerCase().contains(query)) {
            return false;
          }
        }

        // تصفية الأخطاء فقط
        if (_showOnlyErrors && log.isSuccessful) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) => Card(
      margin: EdgeInsets.all(context.responsiveSpacing * 0.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Header
          Padding(
            padding: context.responsivePadding,
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.history,
                  color: Theme.of(context).colorScheme.primary,
                  size: context.isSmallScreen ? 20 : 24,
                ),
                SizedBox(width: context.responsiveSpacing * 0.5),
                Expanded(
                  child: Text(
                    'سجل التحديثات',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: context.responsiveFontSize(18),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: _loadLogs,
                  icon: Icon(Icons.refresh, size: context.isSmallScreen ? 20 : 24),
                  tooltip: 'تحديث السجل',
                ),
                PopupMenuButton<String>(
                  onSelected: _handleMenuAction,
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'export',
                      child: ListTile(
                        leading: Icon(Icons.download),
                        title: Text('تصدير السجل'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'clear',
                      child: ListTile(
                        leading: Icon(Icons.clear_all),
                        title: Text('مسح السجل'),
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filters
          _buildFilters(),

          // Logs List
          Expanded(
            child: _filteredLogs.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _filteredLogs.length,
                    itemBuilder: (BuildContext context, int index) {
                      final UpdateLog log = _filteredLogs[index];
                      return _buildLogItem(log);
                    },
                  ),
          ),
        ],
      ),
    );

  /// بناء فلاتر البحث
  Widget _buildFilters() => Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: <Widget>[
          // Search Bar
          TextField(
            decoration: const InputDecoration(
              hintText: 'البحث في السجل...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (String value) {
              setState(() {
                _searchQuery = value;
              });
              _applyFilters();
            },
          ),

          const SizedBox(height: 12),

          // Filter Chips
          Wrap(
            spacing: 8,
            children: <Widget>[
              // Type Filter
              FilterChip(
                label: Text(_selectedType ?? 'جميع الأنواع'),
                selected: _selectedType != null,
                onSelected: (bool selected) {
                  setState(() {
                    _selectedType = selected ? null : _selectedType;
                  });
                  _applyFilters();
                },
              ),

              // Action Filter
              FilterChip(
                label: Text(_selectedAction ?? 'جميع الإجراءات'),
                selected: _selectedAction != null,
                onSelected: (bool selected) {
                  setState(() {
                    _selectedAction = selected ? null : _selectedAction;
                  });
                  _applyFilters();
                },
              ),

              // Status Filter
              FilterChip(
                label: Text(_selectedStatus == null
                    ? 'جميع الحالات'
                    : _selectedStatus!
                        ? 'نجح فقط'
                        : 'فشل فقط'),
                selected: _selectedStatus != null,
                onSelected: (bool selected) {
                  setState(() {
                    _selectedStatus = selected ? null : _selectedStatus;
                  });
                  _applyFilters();
                },
              ),

              // Errors Only Filter
              FilterChip(
                label: const Text('الأخطاء فقط'),
                selected: _showOnlyErrors,
                onSelected: (bool selected) {
                  setState(() {
                    _showOnlyErrors = selected;
                  });
                  _applyFilters();
                },
              ),
            ],
          ),
        ],
      ),
    );

  /// بناء عنصر السجل
  Widget _buildLogItem(UpdateLog log) => Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: log.isSuccessful ? Colors.green : Colors.red,
          child: Icon(
            log.isSuccessful ? Icons.check : Icons.error,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          log.message,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: log.isSuccessful ? Colors.green[700] : Colors.red[700],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 4),
            Row(
              children: <Widget>[
                _buildChip(_getTypeName(log.type), Colors.blue),
                const SizedBox(width: 8),
                _buildChip(_getActionName(log.action), Colors.orange),
                const SizedBox(width: 8),
                _buildChip(log.formattedTime, Colors.grey),
              ],
            ),
            if (log.responseTime != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                'وقت الاستجابة: ${log.formattedResponseTime}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (log.errorMessage != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                'خطأ: ${log.errorMessage}',
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (String action) => _handleLogAction(action, log),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'details',
              child: ListTile(
                leading: Icon(Icons.info),
                title: Text('التفاصيل'),
                dense: true,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'copy',
              child: ListTile(
                leading: Icon(Icons.copy),
                title: Text('نسخ'),
                dense: true,
              ),
            ),
          ],
        ),
      ),
    );

  /// بناء شريحة صغيرة
  Widget _buildChip(String label, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );

  /// بناء حالة فارغة
  Widget _buildEmptyState() => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد تحديثات في السجل',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'ستظهر التحديثات هنا عند بدء المزامنة',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );

  /// معالجة إجراءات القائمة
  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportLogs();
        break;
      case 'clear':
        _clearLogs();
        break;
    }
  }

  /// معالجة إجراءات السجل
  void _handleLogAction(String action, UpdateLog log) {
    switch (action) {
      case 'details':
        _showLogDetails(log);
        break;
      case 'copy':
        _copyLog(log);
        break;
    }
  }

  /// تصدير السجل
  Future<void> _exportLogs() async {
    try {
      final List<Map<String, dynamic>> logs =
          _realtimeService.exportUpdateLogs();
      final String jsonString =
          const JsonEncoder.withIndent('  ').convert(logs);

      await Clipboard.setData(ClipboardData(text: jsonString));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم نسخ السجل إلى الحافظة'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تصدير السجل: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// مسح السجل
  void _clearLogs() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('مسح السجل'),
        content: const Text('هل أنت متأكد من مسح جميع التحديثات في السجل؟'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              _realtimeService.clearUpdateLogs();
              _loadLogs();
              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم مسح السجل'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('مسح'),
          ),
        ],
      ),
    );
  }

  /// عرض تفاصيل السجل
  void _showLogDetails(UpdateLog log) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('تفاصيل التحديث'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildDetailRow('الرسالة', log.message),
              _buildDetailRow('النوع', _getTypeName(log.type)),
              _buildDetailRow('الإجراء', _getActionName(log.action)),
              _buildDetailRow('الوقت', log.timestamp.toString()),
              _buildDetailRow('الحالة', log.isSuccessful ? 'نجح' : 'فشل'),
              if (log.responseTime != null)
                _buildDetailRow('وقت الاستجابة', log.formattedResponseTime),
              if (log.errorMessage != null)
                _buildDetailRow('رسالة الخطأ', log.errorMessage!),
              if (log.data != null) ...<Widget>[
                const SizedBox(height: 8),
                const Text('البيانات:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    const JsonEncoder.withIndent('  ').convert(log.data),
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  /// بناء صف التفاصيل
  Widget _buildDetailRow(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );

  /// نسخ السجل
  void _copyLog(UpdateLog log) {
    final String logText = '''
الرسالة: ${log.message}
النوع: ${_getTypeName(log.type)}
الإجراء: ${_getActionName(log.action)}
الوقت: ${log.timestamp}
الحالة: ${log.isSuccessful ? 'نجح' : 'فشل'}
${log.responseTime != null ? 'وقت الاستجابة: ${log.formattedResponseTime}' : ''}
${log.errorMessage != null ? 'رسالة الخطأ: ${log.errorMessage}' : ''}
''';

    Clipboard.setData(ClipboardData(text: logText));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ السجل إلى الحافظة'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// الحصول على اسم النوع
  String _getTypeName(String type) {
    switch (type) {
      case 'product':
        return 'منتجات';
      case 'inventory':
        return 'مخزون';
      case 'sale':
        return 'مبيعات';
      default:
        return type;
    }
  }

  /// الحصول على اسم الإجراء
  String _getActionName(String action) {
    switch (action) {
      case 'create':
        return 'إنشاء';
      case 'update':
        return 'تحديث';
      case 'delete':
        return 'حذف';
      case 'sync':
        return 'مزامنة';
      default:
        return action;
    }
  }
}
