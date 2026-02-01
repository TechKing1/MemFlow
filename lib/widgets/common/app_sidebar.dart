import 'package:flutter/material.dart';

class AppSidebar extends StatefulWidget {
  final String currentRoute;

  const AppSidebar({Key? key, required this.currentRoute}) : super(key: key);

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = true;
  bool _showText = true; // Controls text visibility after animation

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      width: _isExpanded ? 240 : 80,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1419),
        border: Border(right: BorderSide(color: Color(0xFF1E293B), width: 1)),
      ),
      onEnd: () {
        // Show text only after expansion animation completes
        if (_isExpanded && !_showText) {
          setState(() {
            _showText = true;
          });
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo and toggle button
          Padding(
            padding: EdgeInsets.all(_isExpanded ? 24 : 16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D9FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Color(0xFF00D9FF),
                    size: 20,
                  ),
                ),
                if (_showText) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MemForensics',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Memory Analysis',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Toggle button
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _isExpanded ? 12 : 16,
              vertical: 8,
            ),
            child: IconButton(
              icon: Icon(
                _isExpanded ? Icons.chevron_left : Icons.chevron_right,
                color: const Color(0xFF64748B),
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  if (_isExpanded) {
                    // Hide text immediately when collapsing
                    _showText = false;
                  }
                  _isExpanded = !_isExpanded;
                  // Text will show after expansion via onEnd callback
                });
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          const Divider(color: Color(0xFF1E293B), height: 1),
          const SizedBox(height: 16),
          // Menu items
          _buildMenuItem(
            context,
            Icons.dashboard_outlined,
            'Dashboard',
            '/dashboard',
          ),
          _buildMenuItem(
            context,
            Icons.upload_file_outlined,
            'Upload Case',
            '/upload',
          ),
          _buildMenuItem(
            context,
            Icons.description_outlined,
            'Reports',
            '/reports',
          ),
          _buildMenuItem(
            context,
            Icons.settings_outlined,
            'Settings',
            '/settings',
          ),
          _buildMenuItem(context, Icons.help_outline, 'Help & About', '/help'),
          const Spacer(),
          // System status
          if (_showText)
            Padding(
              padding: const EdgeInsets.all(16),
              child: AnimatedOpacity(
                opacity: _showText ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'System Status',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Operational',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    final isActive = widget.currentRoute == route;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: _isExpanded ? 12 : 16,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF00D9FF).withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: _showText
          ? InkWell(
              onTap: () {
                if (route != widget.currentRoute) {
                  Navigator.pushReplacementNamed(context, route);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: AnimatedOpacity(
                  opacity: _showText ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: isActive
                            ? const Color(0xFF00D9FF)
                            : const Color(0xFF64748B),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isActive
                                ? const Color(0xFF00D9FF)
                                : const Color(0xFF94A3B8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : Tooltip(
              message: label,
              child: IconButton(
                icon: Icon(
                  icon,
                  color: isActive
                      ? const Color(0xFF00D9FF)
                      : const Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: () {
                  if (route != widget.currentRoute) {
                    Navigator.pushReplacementNamed(context, route);
                  }
                },
              ),
            ),
    );
  }
}
