import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  const ActionButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, '/upload');
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Upload New Case'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D9FF),
            foregroundColor: const Color(0xFF0A0E1A),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
          label: const Text('Export PDF'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF94A3B8),
            side: const BorderSide(color: Color(0xFF1E293B)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.code, size: 18),
          label: const Text('Export JSON'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF94A3B8),
            side: const BorderSide(color: Color(0xFF1E293B)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 200, maxWidth: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  'Search cases...',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 16),
              Icon(Icons.filter_list, color: Color(0xFF64748B), size: 18),
            ],
          ),
        ),
      ],
    );
  }
}
