import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../dialogs/delete_confirmation_dialog.dart';
import '../dialogs/user_management_dialog.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/snackbar_utils.dart';

/// شاشة إدارة المستخدمين للمدير
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService.instance;

  List<AppUser> _users = <AppUser>[];
  bool _isLoading = true;
  String _searchQuery = '';
  UserRole? _filterRole;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// تحميل قائمة المستخدمين
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _authService.usersStream().listen((List<AppUser> users) {
        if (mounted) {
          setState(() {
            _users = users;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackbarUtils.showError(context, 'خطأ في تحميل المستخدمين: $e');
      }
    }
  }

  /// فلترة المستخدمين
  List<AppUser> get _filteredUsers {
    List<AppUser> filtered = _users;

    // فلترة حسب النص
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((AppUser user) {
        final String searchLower = _searchQuery.toLowerCase();
        return user.email.toLowerCase().contains(searchLower) ||
            (user.displayName?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    }

    // فلترة حسب الدور
    if (_filterRole != null) {
      filtered =
          filtered.where((AppUser user) => user.role == _filterRole).toList();
    }

    return filtered;
  }

  /// إنشاء مستخدم جديد
  Future<void> _createUser() async {
    final AppUser? newUser = await showDialog<AppUser>(
      context: context,
      builder: (BuildContext context) => const UserManagementDialog(
        mode: UserManagementMode.create,
      ),
    );

    if (newUser != null) {
      SnackbarUtils.showSuccess(context, 'تم إنشاء المستخدم بنجاح');
    }
  }

  /// تعديل مستخدم
  Future<void> _editUser(AppUser user) async {
    final AppUser? updatedUser = await showDialog<AppUser>(
      context: context,
      builder: (BuildContext context) => UserManagementDialog(
        mode: UserManagementMode.edit,
        user: user,
      ),
    );

    if (updatedUser != null) {
      SnackbarUtils.showSuccess(context, 'تم تحديث المستخدم بنجاح');
    }
  }

  /// إعادة تعيين كلمة المرور
  Future<void> _resetPassword(AppUser user) async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => DeleteConfirmationDialog(
            title: 'إعادة تعيين كلمة المرور',
            message: 'هل أنت متأكد من إعادة تعيين كلمة مرور ${user.email}؟',
            onConfirm: () => Navigator.of(context).pop(true),
          ),
        ) ??
        false;

    if (confirmed) {
      try {
        // في التطبيق الحقيقي، ستحتاج إلى استخدام Cloud Functions لإعادة تعيين كلمة المرور
        // لأن Firebase Auth لا يسمح بإعادة تعيين كلمات مرور المستخدمين الآخرين مباشرة
        SnackbarUtils.showInfo(context,
            'سيتم إرسال رابط إعادة تعيين كلمة المرور إلى ${user.email}');

        // TODO: تنفيذ Cloud Function لإعادة تعيين كلمة المرور
        debugPrint('إعادة تعيين كلمة مرور للمستخدم: ${user.email}');
      } catch (e) {
        SnackbarUtils.showError(context, 'خطأ في إعادة تعيين كلمة المرور: $e');
      }
    }
  }

  /// حذف مستخدم
  Future<void> _deleteUser(AppUser user) async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => DeleteConfirmationDialog(
            title: 'حذف المستخدم',
            message:
                'هل أنت متأكد من حذف المستخدم ${user.email}؟\nهذا الإجراء لا يمكن التراجع عنه.',
            onConfirm: () => Navigator.of(context).pop(true),
          ),
        ) ??
        false;

    if (confirmed) {
      try {
        // حذف المستخدم من Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();
        SnackbarUtils.showSuccess(context, 'تم حذف المستخدم بنجاح');
      } catch (e) {
        SnackbarUtils.showError(context, 'خطأ في حذف المستخدم: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المستخدمين'),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            tabs: const <Widget>[
              Tab(text: 'جميع المستخدمين', icon: Icon(Icons.people)),
              Tab(text: 'المديرين', icon: Icon(Icons.admin_panel_settings)),
              Tab(text: 'البائعين', icon: Icon(Icons.person)),
            ],
          ),
          actions: <Widget>[
            IconButton(
              onPressed: _createUser,
              icon: const Icon(Icons.person_add),
              tooltip: 'إضافة مستخدم جديد',
            ),
          ],
        ),
        body: Column(
          children: <Widget>[
            // شريط البحث والفلترة
            _buildSearchAndFilterBar(),

            // محتوى التبويبات
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  _buildUsersList(_filteredUsers),
                  _buildUsersList(_filteredUsers
                      .where((AppUser user) => user.isAdmin)
                      .toList()),
                  _buildUsersList(_filteredUsers
                      .where((AppUser user) => user.isSeller)
                      .toList()),
                ],
              ),
            ),
          ],
        ),
      );

  /// بناء شريط البحث والفلترة
  Widget _buildSearchAndFilterBar() => Container(
        padding: const EdgeInsets.all(AppConstants.mediumPadding),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        child: Row(
          children: <Widget>[
            // حقل البحث
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'البحث في المستخدمين...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.mediumPadding,
                    vertical: AppConstants.smallPadding,
                  ),
                ),
                onChanged: (String value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            const SizedBox(width: AppConstants.mediumPadding),

            // فلتر الدور
            DropdownButton<UserRole?>(
              value: _filterRole,
              hint: const Text('جميع الأدوار'),
              items: const <DropdownMenuItem<UserRole?>>[
                DropdownMenuItem<UserRole?>(
                  child: Text('جميع الأدوار'),
                ),
                DropdownMenuItem<UserRole?>(
                  value: UserRole.admin,
                  child: Text('مدير'),
                ),
                DropdownMenuItem<UserRole?>(
                  value: UserRole.seller,
                  child: Text('بائع'),
                ),
              ],
              onChanged: (UserRole? value) {
                setState(() {
                  _filterRole = value;
                });
              },
            ),
          ],
        ),
      );

  /// بناء قائمة المستخدمين
  Widget _buildUsersList(List<AppUser> users) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppConstants.mediumPadding),
            Text(
              'لا توجد مستخدمين',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.mediumPadding),
      itemCount: users.length,
      itemBuilder: (BuildContext context, int index) {
        final AppUser user = users[index];
        return _buildUserCard(user);
      },
    );
  }

  /// بناء بطاقة المستخدم
  Widget _buildUserCard(AppUser user) => Card(
        margin: const EdgeInsets.only(bottom: AppConstants.mediumPadding),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: user.isAdmin ? Colors.purple : Colors.blue,
            child: Icon(
              user.isAdmin ? Icons.admin_panel_settings : Icons.person,
              color: Colors.white,
            ),
          ),
          title: Text(
            user.displayName?.isNotEmpty == true
                ? user.displayName!
                : user.email,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(user.email),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          user.isAdmin ? Colors.purple[100] : Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user.isAdmin ? 'مدير' : 'بائع',
                      style: TextStyle(
                        color: user.isAdmin
                            ? Colors.purple[800]
                            : Colors.blue[800],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (user.createdAt != null) ...<Widget>[
                    const SizedBox(width: 8),
                    Text(
                      'منذ ${_formatDate(user.createdAt!)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (String action) {
              switch (action) {
                case 'edit':
                  _editUser(user);
                  break;
                case 'reset_password':
                  _resetPassword(user);
                  break;
                case 'delete':
                  _deleteUser(user);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('تعديل'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'reset_password',
                child: ListTile(
                  leading: Icon(Icons.lock_reset),
                  title: Text('إعادة تعيين كلمة المرور'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('حذف', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      );

  /// تنسيق التاريخ
  String _formatDate(DateTime date) {
    final Duration difference = DateTime.now().difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }
}
