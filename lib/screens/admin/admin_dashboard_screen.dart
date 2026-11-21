import 'package:flutter/material.dart';

import '../../route/route_constants.dart';
import '../auth/views/login_screen.dart';
import '../../services/local_database.dart';
import '../../services/marketplace_state.dart';
import '../../services/supabase_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _isAdmin = false;
  bool _busy = false;
  bool _locked = false;
  int _failedAttempts = 0;
  String? _error;
  late final Future<bool> _remoteAuthorization = SupabaseService.hasStaffAccess;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit(bool isSetup) async {
    if (_busy || _locked || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final database = LocalDatabase.instance;
      if (isSetup) {
        await database.createAdminAccount(_password.text);
        if (mounted) setState(() => _isAdmin = true);
      } else {
        final verified = await database.verifyAdminPassword(_password.text);
        if (verified) {
          _failedAttempts = 0;
          if (mounted) setState(() => _isAdmin = true);
        } else {
          _failedAttempts++;
          if (mounted) {
            setState(() {
              _error = 'كلمة المرور غير صحيحة';
              if (_failedAttempts >= 5) _locked = true;
            });
          }
        }
      }
      _password.clear();
      _confirmation.clear();
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'تعذر التحقق من الحساب. حاول مجددًا.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (SupabaseService.isConfigured) {
      return FutureBuilder<bool>(
        future: _remoteAuthorization,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(child: Text('تعذر التحقق من صلاحيات المشرف')),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data == true
              ? _buildDashboard()
              : _buildRemoteAccessRequired();
        },
      );
    }

    return FutureBuilder<bool>(
      future: LocalDatabase.instance.hasAdminAccount,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('تعذر تحميل حساب المشرف')),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!_isAdmin) return _buildLogin(snapshot.data!);
        return _buildDashboard();
      },
    );
  }

  Widget _buildRemoteAccessRequired() {
    final isSignedIn = SupabaseService.currentUser != null;
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة المشرف')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.admin_panel_settings_outlined,
                  size: 64, color: Color(0xFF0B5D5B)),
              const SizedBox(height: 16),
              Text(
                isSignedIn
                    ? 'لا تملك صلاحية دخول المشرف'
                    : 'سجّل الدخول للمتابعة',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                isSignedIn
                    ? 'يجب أن يمنحك مالك المشروع دور مشرف أو مدير في Supabase.'
                    : 'تحتاج إلى حساب مسجل قبل فتح لوحة المشرف.',
                textAlign: TextAlign.center,
              ),
              if (!isSignedIn) ...[
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const LoginScreen(
                        redirectRoute: adminDashboardScreenRoute,
                      ),
                    ),
                  ),
                  child: const Text('تسجيل الدخول'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogin(bool isSetup) {
    return Scaffold(
      appBar: AppBar(title: const Text('دخول المشرف')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.admin_panel_settings_outlined,
                      size: 64, color: Color(0xFF0B5D5B)),
                  const SizedBox(height: 16),
                  Text(
                    isSetup ? 'إنشاء حساب المشرف' : 'لوحة المشرف',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSetup
                        ? 'أنشئ كلمة مرور للمشرف. لا تفقدها؛ لا يمكن استعادتها محليًا.'
                        : 'أدخل كلمة مرور المشرف للمتابعة.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'كلمة مرور المشرف'),
                    validator: (value) {
                      if (value == null || value.length < 12) {
                        return 'استخدم 12 حرفًا على الأقل';
                      }
                      return null;
                    },
                  ),
                  if (isSetup) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmation,
                      obscureText: true,
                      decoration:
                          const InputDecoration(labelText: 'تأكيد كلمة المرور'),
                      validator: (value) => value != _password.text
                          ? 'كلمتا المرور غير متطابقتين'
                          : null,
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  if (_locked) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'تم إيقاف محاولات الدخول. أغلق التطبيق وافتحه للمحاولة مجددًا.',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy || _locked ? null : () => _submit(isSetup),
                    child: Text(_busy
                        ? 'جارٍ التحقق...'
                        : isSetup
                            ? 'إنشاء حساب المشرف'
                            : 'دخول'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة المشرف'),
          actions: [
            IconButton(
              tooltip: 'تسجيل الخروج',
              onPressed: () {
                if (SupabaseService.isConfigured) {
                  Navigator.pop(context);
                } else {
                  setState(() => _isAdmin = false);
                }
              },
              icon: const Icon(Icons.logout),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'الإعلانات'),
              Tab(text: 'المستخدمون'),
              Tab(text: 'الطلبات'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ListingsTab(onChanged: _refresh),
            _UsersTab(onChanged: _refresh),
            _OrdersTab(),
          ],
        ),
      ),
    );
  }

  void _refresh() {
    if (mounted) setState(() {});
  }
}

class _ListingsTab extends StatefulWidget {
  const _ListingsTab({required this.onChanged});

  final VoidCallback onChanged;

  @override
  State<_ListingsTab> createState() => _ListingsTabState();
}

class _ListingsTabState extends State<_ListingsTab> {
  late Future<List<Map<String, Object?>>> _rows;

  @override
  void initState() {
    super.initState();
    _rows = _load();
  }

  Future<List<Map<String, Object?>>> _load() async {
    if (SupabaseService.isConfigured) {
      return SupabaseService.loadAdminListings();
    }
    final db = await LocalDatabase.instance.database;
    return db.query('listings', orderBy: "status = 'pending' DESC");
  }

  Future<void> _update(String id, {String? status, bool delete = false}) async {
    if (SupabaseService.isConfigured) {
      if (delete) {
        await SupabaseService.deleteListing(id);
      } else {
        await SupabaseService.moderateListing(id, status!);
      }
      if (!mounted) return;
      setState(() => _rows = _load());
      await MarketplaceScope.of(context).refreshListings();
      widget.onChanged();
      return;
    }

    final db = await LocalDatabase.instance.database;
    if (delete) {
      await db.delete('listings', where: 'id = ?', whereArgs: [id]);
      await db.delete('favorites', where: 'listingId = ?', whereArgs: [id]);
      await db.delete('cart', where: 'listingId = ?', whereArgs: [id]);
    } else {
      await db.update(
        'listings',
        {'status': status},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    if (!mounted) return;
    setState(() => _rows = _load());
    await MarketplaceScope.of(context).refreshListings();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, Object?>>>(
      future: _rows,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('تعذر تحميل الإعلانات'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snapshot.data!;
        if (rows.isEmpty) return const Center(child: Text('لا توجد إعلانات'));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final row = rows[index];
            final id = row['id'] as String;
            final status = row['status'] as String;
            final pending = status == 'pending';
            final statusLabel = switch (status) {
              'pending' => 'بانتظار المراجعة',
              'approved' => 'منشور',
              'rejected' => 'مرفوض',
              _ => status,
            };
            return Card(
              child: ListTile(
                title: Text(row['title'] as String),
                subtitle: Text(
                    '${row['category']} · ${row['price']} ر.س · $statusLabel'),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (action) async {
                    try {
                      if (action == 'approve') {
                        await _update(id, status: 'approved');
                      } else if (action == 'reject') {
                        await _update(id, status: 'rejected');
                      } else if (action == 'delete') {
                        await _update(id, delete: true);
                      }
                    } catch (error) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تعذر تحديث الإعلان. حاول مجددًا.'),
                          ),
                        );
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    if (pending)
                      const PopupMenuItem(
                          value: 'approve', child: Text('موافقة ونشر')),
                    if (pending)
                      const PopupMenuItem(
                          value: 'reject', child: Text('رفض الإعلان')),
                    const PopupMenuItem(
                        value: 'delete', child: Text('حذف الإعلان')),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _UsersTab extends StatefulWidget {
  const _UsersTab({required this.onChanged});

  final VoidCallback onChanged;

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  late Future<List<Map<String, Object?>>> _rows;

  @override
  void initState() {
    super.initState();
    _rows = _load();
  }

  Future<List<Map<String, Object?>>> _load() async {
    if (SupabaseService.isConfigured) {
      return SupabaseService.loadProfiles();
    }
    final db = await LocalDatabase.instance.database;
    return db.query('users', orderBy: 'createdAt DESC');
  }

  Future<void> _toggleUser(String userId, String email, bool isActive) async {
    if (SupabaseService.isConfigured) {
      await SupabaseService.setProfileActive(userId, !isActive);
      if (!mounted) return;
      setState(() => _rows = _load());
      widget.onChanged();
      return;
    }
    final db = await LocalDatabase.instance.database;
    await db.update(
      'users',
      {'isActive': isActive ? 0 : 1},
      where: 'email = ?',
      whereArgs: [email],
    );
    if (!mounted) return;
    setState(() => _rows = _load());
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, Object?>>>(
      future: _rows,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('تعذر تحميل المستخدمين'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snapshot.data!;
        if (rows.isEmpty) {
          return Center(
              child: Text(SupabaseService.isConfigured
                  ? 'لا توجد حسابات مسجلة بعد'
                  : 'لا توجد حسابات محلية مسجلة بعد'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final row = rows[index];
            final active = SupabaseService.isConfigured
                ? row['is_active'] as bool
                : row['isActive'] as int == 1;
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(row['email'] as String),
              subtitle: Text(
                  '${active ? 'نشط' : 'موقوف'} · ${SupabaseService.isConfigured ? row['role'] : 'محلي'}'),
              trailing: Switch(
                value: active,
                onChanged: SupabaseService.isConfigured &&
                        row['id'] == SupabaseService.currentUser?.id
                    ? null
                    : (_) async {
                        try {
                          await _toggleUser(
                            SupabaseService.isConfigured
                                ? row['id'] as String
                                : row['email'] as String,
                            row['email'] as String,
                            active,
                          );
                        } catch (error) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'تعذر تحديث حالة الحساب. حاول مجددًا.'),
                              ),
                            );
                          }
                        }
                      },
              ),
            );
          },
        );
      },
    );
  }
}

class _OrdersTab extends StatefulWidget {
  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  late Future<List<Map<String, Object?>>> _rows;

  @override
  void initState() {
    super.initState();
    _rows = _load();
  }

  Future<List<Map<String, Object?>>> _load() async {
    if (SupabaseService.isConfigured) {
      return SupabaseService.loadOrders();
    }
    final db = await LocalDatabase.instance.database;
    return db.query('orders', orderBy: 'createdAt DESC');
  }

  Future<void> _setStatus(String id, String status) async {
    if (SupabaseService.isConfigured) {
      await SupabaseService.setOrderStatus(id, status);
    } else {
      final db = await LocalDatabase.instance.database;
      await db.update('orders', {'status': status},
          where: 'id = ?', whereArgs: [id]);
    }
    if (mounted) setState(() => _rows = _load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, Object?>>>(
      future: _rows,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('تعذر تحميل الطلبات'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snapshot.data!;
        if (rows.isEmpty) return const Center(child: Text('لا توجد طلبات'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final row = rows[index];
            return ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(row['title'] as String),
              subtitle: Text(
                  '${row['status']} · ${row['total']} ر.س · ${row[SupabaseService.isConfigured ? 'created_at' : 'createdAt']}'),
              trailing: PopupMenuButton<String>(
                onSelected: (status) async {
                  try {
                    await _setStatus(row['id'] as String, status);
                  } catch (error) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تعذر تحديث حالة الطلب. حاول مجددًا.'),
                        ),
                      );
                    }
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                      value: 'قيد المراجعة', child: Text('قيد المراجعة')),
                  PopupMenuItem(
                      value: 'قيد التوصيل', child: Text('قيد التوصيل')),
                  PopupMenuItem(value: 'تم التسليم', child: Text('تم التسليم')),
                  PopupMenuItem(value: 'ملغي', child: Text('ملغي')),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
