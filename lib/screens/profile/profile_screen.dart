import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/auth_provider.dart';
import '../../api-routes/auth/auth_api_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final username = auth.username;
    final email = auth.email;
    final isAdmin = auth.isAdmin;
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'A';
    final joinedAt = user?['created_at'] as String?;
    final lastLogin = user?['last_login'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Row(
        children: [
          // ── Left panel ────────────────────────────────────────────────
          Container(
            width: 320,
            decoration: const BoxDecoration(
              color: Color(0xFF0F1419),
              border: Border(right: BorderSide(color: Color(0xFF1E293B), width: 1)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF94A3B8)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text('Back', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Avatar with glow
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF00D9FF), Color(0xFF0066FF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00D9FF).withOpacity(0.35),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(initial,
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(username,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                Text(email, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                const SizedBox(height: 16),
                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? const Color(0xFFF59E0B).withOpacity(0.12)
                        : const Color(0xFF00D9FF).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isAdmin
                          ? const Color(0xFFF59E0B).withOpacity(0.4)
                          : const Color(0xFF00D9FF).withOpacity(0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAdmin ? Icons.shield : Icons.person_outline,
                        size: 14,
                        color: isAdmin ? const Color(0xFFF59E0B) : const Color(0xFF00D9FF),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isAdmin ? 'Administrator' : 'DFIR Analyst',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isAdmin ? const Color(0xFFF59E0B) : const Color(0xFF00D9FF),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Sign out button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmLogout(context, auth),
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Sign Out',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Right panel ───────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Account Information',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  const Text('Your MemFlow analyst profile details',
                      style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                  const SizedBox(height: 32),

                  _SectionCard(
                    title: 'Profile Details',
                    icon: Icons.person_outlined,
                    children: [
                      _InfoRow(label: 'Username', value: username),
                      _InfoRow(label: 'Email Address', value: email),
                      _InfoRow(
                        label: 'Role',
                        value: isAdmin ? 'Administrator' : 'DFIR Analyst',
                        valueColor: isAdmin ? const Color(0xFFF59E0B) : const Color(0xFF00D9FF),
                      ),
                      _InfoRow(
                        label: 'Account Status',
                        value: user?['is_active'] == true ? 'Active' : 'Inactive',
                        valueColor: user?['is_active'] == true
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _SectionCard(
                    title: 'Activity',
                    icon: Icons.access_time_outlined,
                    children: [
                      _InfoRow(label: 'Account Created', value: _formatDate(joinedAt) ?? 'Unknown'),
                      _InfoRow(label: 'Last Login', value: _formatDate(lastLogin) ?? 'This session'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _SectionCard(
                    title: 'Security',
                    icon: Icons.lock_outline,
                    children: [
                      _ActionRow(
                        label: 'Change Password',
                        subtitle: 'Update your account password',
                        icon: Icons.key_outlined,
                        onTap: () => _showChangePassword(context, auth),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _SectionCard(
                    title: 'Permissions',
                    icon: Icons.verified_user_outlined,
                    children: [
                      _PermissionRow(label: 'Create & View Cases', granted: true),
                      _PermissionRow(label: 'Run Memory Analysis', granted: true),
                      _PermissionRow(label: 'View Reports', granted: true),
                      _PermissionRow(label: 'Delete Cases', granted: isAdmin),
                      _PermissionRow(label: 'Manage Users', granted: isAdmin),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _formatDate(String? iso) {
    if (iso == null) return null;
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1419),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Sign Out',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out of MemFlow?',
            style: TextStyle(color: Color(0xFF94A3B8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showChangePassword(BuildContext context, AuthProvider auth) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0F1419),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Change Password',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(currentCtrl, 'Current Password', obscure: true),
                const SizedBox(height: 12),
                _dialogField(newCtrl, 'New Password', obscure: true),
                const SizedBox(height: 12),
                _dialogField(confirmCtrl, 'Confirm New Password', obscure: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D9FF),
                foregroundColor: const Color(0xFF0A0E1A),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (newCtrl.text != confirmCtrl.text) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('New passwords do not match.'),
                          backgroundColor: Color(0xFFEF4444),
                        ));
                        return;
                      }
                      setDialogState(() => isLoading = true);
                      try {
                        await AuthApiRoutes.changePassword(
                          accessToken: auth.accessToken!,
                          currentPassword: currentCtrl.text,
                          newPassword: newCtrl.text,
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Password changed successfully.'),
                            backgroundColor: Color(0xFF10B981),
                          ));
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(e.toString().replaceFirst('Exception: ', '')),
                            backgroundColor: const Color(0xFFEF4444),
                          ));
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Color(0xFF0A0E1A))))
                  : const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String hint, {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF475569)),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1419),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF00D9FF)),
                const SizedBox(width: 10),
                Text(title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF1E293B)),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: valueColor ?? Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionRow({required this.label, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF00D9FF).withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF00D9FF)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final String label;
  final bool granted;

  const _PermissionRow({required this.label, required this.granted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: granted
                  ? const Color(0xFF10B981).withOpacity(0.12)
                  : const Color(0xFFEF4444).withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              granted ? Icons.check : Icons.close,
              size: 13,
              color: granted ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                fontSize: 13,
                color: granted ? Colors.white : const Color(0xFF475569),
              )),
        ],
      ),
    );
  }
}
