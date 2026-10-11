
import 'package:flutter/material.dart';
import 'package:khmsat_services/screens/ai/controller/chat_history_store.dart';

/// قائمة سجل المحادثات
class HistorySheet extends StatefulWidget {
  final List<ChatSession> sessions;
  final String? currentId;
  final ValueChanged<ChatSession> onOpen;
  final VoidCallback onNew;
  final Future<List<ChatSession>> Function(String id) onDelete;

  const HistorySheet({
    required this.sessions,
    required this.currentId,
    required this.onOpen,
    required this.onNew,
    required this.onDelete,
  });

  @override
  State<HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<HistorySheet> {
  late final List<ChatSession> _items = List.of(widget.sessions);

  String _fmt(DateTime d) {
    final n = DateTime.now();
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    if (d.year == n.year && d.month == n.month && d.day == n.day) {
      return 'اليوم $hh:$mm';
    }
    return '${d.year}/${d.month.toString().padLeft(2, '0')}/'
        '${d.day.toString().padLeft(2, '0')}';
  }

  Future<bool> _confirmDelete(ChatSession s) async {
    final ok = await showDialog<bool>(
      context: context,
      // الحوار يُبنى فوق الـ Navigator فلا يرث الاتجاه، لذا نحدده صراحة
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف المحادثة'),
          content: Text('هل تريد حذف "${s.title}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.6;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'سجل المحادثات',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onNew();
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('محادثة جديدة'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: height),
            child: _items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('لا توجد محادثات محفوظة بعد')),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final s = _items[i];
                      final selected = s.id == widget.currentId;
                      return Dismissible(
                        key: ValueKey(s.id),
                        confirmDismiss: (_) => _confirmDelete(s),
                        onDismissed: (_) {
                          setState(
                            () => _items.removeWhere((e) => e.id == s.id),
                          );
                          widget.onDelete(s.id);
                        },
                        background: Container(
                          color: Colors.red.shade100,
                          alignment: AlignmentDirectional.centerStart,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: const Icon(Icons.delete_outline),
                        ),
                        secondaryBackground: Container(
                          color: Colors.red.shade100,
                          alignment: AlignmentDirectional.centerEnd,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: const Icon(Icons.delete_outline),
                        ),
                        child: ListTile(
                          selected: selected,
                          selectedTileColor:
                              const Color(0xFFD4AF37).withValues(alpha: 0.15),
                          leading: const Icon(Icons.chat_bubble_outline),
                          title: Text(
                            s.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(_fmt(s.updatedAt)),
                          onTap: () {
                            Navigator.pop(context);
                            widget.onOpen(s);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}