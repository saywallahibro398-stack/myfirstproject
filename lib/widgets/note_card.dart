import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/note.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({
    required this.note,
    required this.onTap,
    this.folderName,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final Note note;
  final String? folderName;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppPalette.fromHex(note.color),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppPalette.line),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(17, 14, 8, 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (onEdit != null || onDelete != null)
                    PopupMenuButton<String>(
                      tooltip: 'Note actions',
                      onSelected: (value) {
                        if (value == 'edit') onEdit?.call();
                        if (value == 'delete') onDelete?.call();
                      },
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                        if (onDelete != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                      ],
                      icon: const Icon(
                        Icons.more_horiz,
                        color: AppPalette.mutedInk,
                      ),
                    ),
                ],
              ),
              if (note.preview.isNotEmpty) ...[
                Text(
                  note.preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppPalette.mutedInk, height: 1.4),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  if (folderName != null) ...[
                    const Icon(
                      Icons.folder_outlined,
                      size: 14,
                      color: AppPalette.lavenderDeep,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        folderName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppPalette.mutedInk,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  const Spacer(),
                  Text(
                    _dateLabel(note.updatedAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppPalette.mutedInk,
                    ),
                  ),
                ],
              ),
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 9),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: note.tags
                      .take(3)
                      .map((tag) => _Tag(label: tag))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final local = date.toLocal();
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }
    return '${local.month}/${local.day}';
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .62),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 11, color: AppPalette.ink),
    ),
  );
}
