import 'package:flutter/material.dart';

class StatusFilterDropdown extends StatelessWidget {
  final String selectedStatus;
  final Function(String?) onStatusChanged;

  const StatusFilterDropdown({
    Key? key,
    required this.selectedStatus,
    required this.onStatusChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedStatus,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
          dropdownColor: const Color(0xFF1E293B),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Status')),
            DropdownMenuItem(value: 'queued', child: Text('Queued')),
            DropdownMenuItem(value: 'processing', child: Text('Processing')),
            DropdownMenuItem(value: 'completed', child: Text('Completed')),
            DropdownMenuItem(value: 'failed', child: Text('Failed')),
          ],
          onChanged: onStatusChanged,
        ),
      ),
    );
  }
}
