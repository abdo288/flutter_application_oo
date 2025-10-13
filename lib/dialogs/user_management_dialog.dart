import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/snackbar_utils.dart';
import '../utils/responsive_breakpoints.dart';

/// وضع إدارة المستخدم
enum UserManagementMode {
  create,
  edit,
}

/// حوار إدارة المستخدم
class UserManagementDialog extends StatefulWidget {
  const UserManagementDialog({
    super.key,
    required this.mode,
    this.user,
  });

  final UserManagementMode mode;
  final AppUser? user;

  @override
  State<UserManagementDialog> createState() => _UserManagementDialogState();
}

class _UserManagementDialogState extends State<UserManagementDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final AuthService _authService = AuthService.instance;

  UserRole _selectedRole = UserRole.seller;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.mode == UserManagementMode.edit && widget.user != null) {
      _emailController.text = widget.user!.email;
      _displayNameController.text = widget.user!.displayName ?? '';
      _selectedRole = widget.user!.role;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// حفظ المستخدم
  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.mode == UserManagementMode.create) {
        await _createUser();
      } else {
        await _updateUser();
      }

      if (mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        SnackbarUtils.showSuccess(
          context,
          widget.mode == UserManagementMode.create
              ? 'تم إنشاء المستخدم بنجاح'
              : 'تم تحديث المستخدم بنجاح',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'خطأ في حفظ المستخدم: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// إنشاء مستخدم جديد
  Future<void> _createUser() async {
    // إنشاء المستخدم في Firebase Auth
    final fb_auth.UserCredential userCredential =
        await fb_auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    // إنشاء وثيقة المستخدم في Firestore
    await _authService.upsertUserDoc(
      uid: userCredential.user!.uid,
      email: _emailController.text.trim(),
      displayName: _displayNameController.text.trim().isEmpty
          ? null
          : _displayNameController.text.trim(),
      role: _selectedRole,
    );

    // تسجيل خروج المستخدم الجديد (لأنه تم تسجيل دخوله تلقائياً)
    await fb_auth.FirebaseAuth.instance.signOut();

    // إعادة تسجيل دخول المدير الحالي
    // TODO: إعادة تسجيل دخول المدير الحالي
  }

  /// تحديث مستخدم موجود
  Future<void> _updateUser() async {
    if (widget.user == null) return;

    // تحديث البيانات في Firestore
    await _authService.upsertUserDoc(
      uid: widget.user!.uid,
      email: _emailController.text.trim(),
      displayName: _displayNameController.text.trim().isEmpty
          ? null
          : _displayNameController.text.trim(),
      role: _selectedRole,
    );

    // إذا تم تغيير كلمة المرور
    if (_passwordController.text.isNotEmpty) {
      // في التطبيق الحقيقي، ستحتاج إلى استخدام Cloud Functions لتغيير كلمة المرور
      // لأن Firebase Auth لا يسمح بتغيير كلمات مرور المستخدمين الآخرين مباشرة
      debugPrint('تغيير كلمة مرور المستخدم: ${widget.user!.email}');
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: ConstrainedBox(
          constraints: context.dialogConstraints,
          child: Container(
            padding: context.responsivePadding,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // العنوان
                  Row(
                    children: <Widget>[
                      Icon(
                        widget.mode == UserManagementMode.create
                            ? Icons.person_add
                            : Icons.edit,
                        color: Colors.purple,
                        size: context.isSmallScreen ? 20 : 24,
                      ),
                      SizedBox(width: context.responsiveSpacing * 0.5),
                      Expanded(
                        child: Text(
                          widget.mode == UserManagementMode.create
                              ? 'إضافة مستخدم جديد'
                              : 'تعديل المستخدم',
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(20),
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                        icon: Icon(Icons.close,
                            size: context.isSmallScreen ? 20 : 24),
                      ),
                    ],
                  ),

                  SizedBox(height: context.responsiveSpacing),

                  // حقل البريد الإلكتروني
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(fontSize: context.responsiveFontSize(16)),
                    decoration: InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      labelStyle:
                          TextStyle(fontSize: context.responsiveFontSize(16)),
                      prefixIcon: Icon(Icons.email,
                          size: context.isSmallScreen ? 20 : 24),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.borderRadius),
                      ),
                      contentPadding: context.responsivePadding,
                      isDense: context.isSmallScreen,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: widget.mode == UserManagementMode.create,
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'البريد الإلكتروني مطلوب';
                      }
                      if (!value.trim().contains('@') ||
                          !value.trim().contains('.')) {
                        return 'البريد الإلكتروني غير صحيح';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: context.responsiveSpacing),

                  // حقل الاسم المعروض
                  TextFormField(
                    controller: _displayNameController,
                    style: TextStyle(fontSize: context.responsiveFontSize(16)),
                    decoration: InputDecoration(
                      labelText: 'الاسم المعروض (اختياري)',
                      labelStyle:
                          TextStyle(fontSize: context.responsiveFontSize(16)),
                      prefixIcon: Icon(Icons.person,
                          size: context.isSmallScreen ? 20 : 24),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.borderRadius),
                      ),
                      contentPadding: context.responsivePadding,
                      isDense: context.isSmallScreen,
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),

                  SizedBox(height: context.responsiveSpacing),

                  // حقل كلمة المرور
                  TextFormField(
                    controller: _passwordController,
                    style: TextStyle(fontSize: context.responsiveFontSize(16)),
                    decoration: InputDecoration(
                      labelText: widget.mode == UserManagementMode.create
                          ? 'كلمة المرور'
                          : 'كلمة المرور الجديدة (اختياري)',
                      labelStyle:
                          TextStyle(fontSize: context.responsiveFontSize(16)),
                      prefixIcon: Icon(Icons.lock,
                          size: context.isSmallScreen ? 20 : 24),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          size: context.isSmallScreen ? 18 : 20,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.borderRadius),
                      ),
                      contentPadding: context.responsivePadding,
                      isDense: context.isSmallScreen,
                    ),
                    obscureText: _obscurePassword,
                    validator: (String? value) {
                      if (widget.mode == UserManagementMode.create) {
                        if (value == null || value.isEmpty) {
                          return 'كلمة المرور مطلوبة';
                        }
                        if (value.length < 6) {
                          return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                        }
                      } else if (value != null &&
                          value.isNotEmpty &&
                          value.length < 6) {
                        return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: context.responsiveSpacing),

                  // حقل تأكيد كلمة المرور
                  if (widget.mode == UserManagementMode.create ||
                      _passwordController.text.isNotEmpty) ...<Widget>[
                    TextFormField(
                      controller: _confirmPasswordController,
                      style:
                          TextStyle(fontSize: context.responsiveFontSize(16)),
                      decoration: InputDecoration(
                        labelText: 'تأكيد كلمة المرور',
                        labelStyle:
                            TextStyle(fontSize: context.responsiveFontSize(16)),
                        prefixIcon: Icon(Icons.lock_outline,
                            size: context.isSmallScreen ? 20 : 24),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: context.isSmallScreen ? 18 : 20,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.borderRadius),
                        ),
                        contentPadding: context.responsivePadding,
                        isDense: context.isSmallScreen,
                      ),
                      obscureText: _obscureConfirmPassword,
                      validator: (String? value) {
                        if (widget.mode == UserManagementMode.create) {
                          if (value == null || value.isEmpty) {
                            return 'تأكيد كلمة المرور مطلوب';
                          }
                          if (value != _passwordController.text) {
                            return 'كلمة المرور غير متطابقة';
                          }
                        } else if (_passwordController.text.isNotEmpty) {
                          if (value == null || value.isEmpty) {
                            return 'تأكيد كلمة المرور مطلوب';
                          }
                          if (value != _passwordController.text) {
                            return 'كلمة المرور غير متطابقة';
                          }
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: context.responsiveSpacing),
                  ],

                  // اختيار الدور
                  Text(
                    'الدور',
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(16),
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: context.responsiveSpacing * 0.5),
                  context.shouldUseVerticalLayout
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            RadioListTile<UserRole>(
                              title: Text(
                                'بائع',
                                style: TextStyle(
                                    fontSize: context.responsiveFontSize(16)),
                              ),
                              subtitle: Text(
                                'يمكنه إدارة المبيعات والمخزون',
                                style: TextStyle(
                                    fontSize: context.responsiveFontSize(14)),
                              ),
                              value: UserRole.seller,
                              groupValue: _selectedRole,
                              onChanged: (UserRole? value) {
                                setState(() {
                                  _selectedRole = value!;
                                });
                              },
                              activeColor: Colors.blue,
                            ),
                            RadioListTile<UserRole>(
                              title: Text(
                                'مدير',
                                style: TextStyle(
                                    fontSize: context.responsiveFontSize(16)),
                              ),
                              subtitle: Text(
                                'صلاحيات كاملة',
                                style: TextStyle(
                                    fontSize: context.responsiveFontSize(14)),
                              ),
                              value: UserRole.admin,
                              groupValue: _selectedRole,
                              onChanged: (UserRole? value) {
                                setState(() {
                                  _selectedRole = value!;
                                });
                              },
                              activeColor: Colors.purple,
                            ),
                          ],
                        )
                      : Row(
                          children: <Widget>[
                            Expanded(
                              child: RadioListTile<UserRole>(
                                title: Text(
                                  'بائع',
                                  style: TextStyle(
                                      fontSize: context.responsiveFontSize(16)),
                                ),
                                subtitle: Text(
                                  'يمكنه إدارة المبيعات والمخزون',
                                  style: TextStyle(
                                      fontSize: context.responsiveFontSize(14)),
                                ),
                                value: UserRole.seller,
                                groupValue: _selectedRole,
                                onChanged: (UserRole? value) {
                                  setState(() {
                                    _selectedRole = value!;
                                  });
                                },
                                activeColor: Colors.blue,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<UserRole>(
                                title: Text(
                                  'مدير',
                                  style: TextStyle(
                                      fontSize: context.responsiveFontSize(16)),
                                ),
                                subtitle: Text(
                                  'صلاحيات كاملة',
                                  style: TextStyle(
                                      fontSize: context.responsiveFontSize(14)),
                                ),
                                value: UserRole.admin,
                                groupValue: _selectedRole,
                                onChanged: (UserRole? value) {
                                  setState(() {
                                    _selectedRole = value!;
                                  });
                                },
                                activeColor: Colors.purple,
                              ),
                            ),
                          ],
                        ),

                  SizedBox(height: context.responsiveSpacing),

                  // أزرار الإجراءات
                  context.shouldUseVerticalLayout
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            ElevatedButton(
                              onPressed: _isLoading ? null : _saveUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                    vertical: context.responsiveSpacing),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Text(
                                      widget.mode == UserManagementMode.create
                                          ? 'إنشاء'
                                          : 'تحديث',
                                      style: TextStyle(
                                          fontSize:
                                              context.responsiveFontSize(16)),
                                    ),
                            ),
                            SizedBox(height: context.responsiveSpacing * 0.5),
                            OutlinedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      if (Navigator.of(context).canPop()) {
                                        Navigator.of(context).pop();
                                      }
                                    },
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    vertical: context.responsiveSpacing),
                              ),
                              child: Text(
                                'إلغاء',
                                style: TextStyle(
                                    fontSize: context.responsiveFontSize(16)),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        if (Navigator.of(context).canPop()) {
                                          Navigator.of(context).pop();
                                        }
                                      },
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                      vertical: context.responsiveSpacing),
                                ),
                                child: Text(
                                  'إلغاء',
                                  style: TextStyle(
                                      fontSize: context.responsiveFontSize(16)),
                                ),
                              ),
                            ),
                            SizedBox(width: context.responsiveSpacing),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _saveUser,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                      vertical: context.responsiveSpacing),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : Text(
                                        widget.mode == UserManagementMode.create
                                            ? 'إنشاء'
                                            : 'تحديث',
                                        style: TextStyle(
                                            fontSize:
                                                context.responsiveFontSize(16)),
                                      ),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
      );
}
