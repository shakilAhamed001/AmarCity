import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';

// Thin wrapper — kept so any existing Navigator.push(ChatScreen) still works
class ChatScreen extends StatelessWidget {
  final Map<String, dynamic> complaint;
  final String viewerRole;

  const ChatScreen({
    Key? key,
    required this.complaint,
    required this.viewerRole,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Complaint Chat',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(
              complaint['title'] ?? '',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        elevation: 0,
      ),
      body: ChatContent(complaint: complaint, viewerRole: viewerRole),
    );
  }
}

// Public reusable chat body — used in bottom sheet from complaint_detail_screen
class ChatContent extends StatefulWidget {
  final Map<String, dynamic> complaint;
  final String viewerRole;

  const ChatContent({
    Key? key,
    required this.complaint,
    required this.viewerRole,
  }) : super(key: key);

  @override
  State<ChatContent> createState() => _ChatContentState();
}

class _ChatContentState extends State<ChatContent> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final Map<String, Map<String, dynamic>> _profileCache = {};
  bool _isLoading = true;
  bool _isSending = false;
  RealtimeChannel? _channel;

  String get _complaintId => widget.complaint['id'].toString();
  String get _currentUserId => AuthService.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _getProfile(String userId) async {
    if (_profileCache.containsKey(userId)) return _profileCache[userId]!;
    try {
      final data = await supabase
          .from('profiles')
          .select('full_name, role')
          .eq('id', userId)
          .maybeSingle();
      final profile =
          data != null ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      _profileCache[userId] = profile;
      return profile;
    } catch (_) {
      return {};
    }
  }

  Future<void> _fetchMessages() async {
    try {
      final data = await supabase
          .from('complaint_messages')
          .select()
          .eq('complaint_id', _complaintId)
          .order('created_at', ascending: true);

      final list = (data as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final senderIds =
          list.map((m) => m['sender_id'].toString()).toSet();
      for (final id in senderIds) {
        await _getProfile(id);
      }

      if (mounted) {
        setState(() {
          _messages
            ..clear()
            ..addAll(list);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeRealtime() {
    _channel = supabase
        .channel('chat:$_complaintId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'complaint_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'complaint_id',
            value: _complaintId,
          ),
          callback: (payload) async {
            final newMsg = Map<String, dynamic>.from(payload.newRecord);
            final senderId = newMsg['sender_id']?.toString() ?? '';
            if (senderId == _currentUserId) return;
            final msgId = newMsg['id']?.toString();
            final alreadyExists =
                _messages.any((m) => m['id']?.toString() == msgId);
            if (alreadyExists) return;
            await _getProfile(senderId);
            if (mounted) {
              setState(() => _messages.add(newMsg));
              _scrollToBottom();
            }
          },
        )
        .subscribe();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _controller.clear();

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMsg = {
      'id': tempId,
      'complaint_id': _complaintId,
      'sender_id': _currentUserId,
      'sender_role': widget.viewerRole,
      'message': text,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      '_pending': true,
    };
    setState(() => _messages.add(optimisticMsg));
    _scrollToBottom();

    try {
      final inserted = await supabase
          .from('complaint_messages')
          .insert({
            'complaint_id': _complaintId,
            'sender_id': _currentUserId,
            'sender_role': widget.viewerRole,
            'message': text,
          })
          .select()
          .single();

      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m['id'] == tempId);
          if (idx != -1) {
            _messages[idx] = Map<String, dynamic>.from(inserted as Map);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _messages.removeWhere((m) => m['id'] == tempId));
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                  ? _buildEmptyState()
                  : _buildMessageList(),
        ),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildMessageList() {
    final items = <_ChatItem>[];
    String? lastDateLabel;

    for (final msg in _messages) {
      final dateLabel = _dateLabel(msg['created_at'] as String?);
      if (dateLabel != lastDateLabel) {
        items.add(_ChatItem(isDateSeparator: true, dateLabel: dateLabel));
        lastDateLabel = dateLabel;
      }
      items.add(_ChatItem(message: msg));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        if (item.isDateSeparator) return _buildDateSeparator(item.dateLabel!);
        return _buildMessageBubble(item.message!);
      },
    );
  }

  Widget _buildDateSeparator(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFD1D5DB))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ),
          const Expanded(child: Divider(color: Color(0xFFD1D5DB))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF1E40AF).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline,
                color: Color(0xFF1E40AF), size: 34),
          ),
          const SizedBox(height: 16),
          const Text('No messages yet',
              style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w600,
                  fontSize: 15)),
          const SizedBox(height: 6),
          const Text('Start the conversation below',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isMine = msg['sender_id'] == _currentUserId;
    final isPending = msg['_pending'] == true;
    final senderId = msg['sender_id']?.toString() ?? '';
    final profile = _profileCache[senderId] ?? {};
    final senderName = profile['full_name'] as String? ?? 'User';
    final senderRole = msg['sender_role'] as String? ?? '';
    final text = msg['message'] as String? ?? '';
    final time = _formatTime(msg['created_at'] as String?);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            _buildAvatar(senderName, senderRole),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMine)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(senderName,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151))),
                        const SizedBox(width: 6),
                        _buildRoleBadge(senderRole),
                      ],
                    ),
                  ),
                Opacity(
                  opacity: isPending ? 0.6 : 1.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMine
                          ? const Color(0xFF1E40AF)
                          : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMine ? 16 : 4),
                        bottomRight: Radius.circular(isMine ? 4 : 16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      text,
                      style: TextStyle(
                        color: isMine ? Colors.white : const Color(0xFF1F2937),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(time,
                          style: const TextStyle(
                              color: Color(0xFF9CA3AF), fontSize: 10)),
                      if (isPending) ...[
                        const SizedBox(width: 4),
                        const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5, color: Color(0xFF9CA3AF)),
                        ),
                      ] else if (isMine) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.done_all,
                            size: 12, color: Color(0xFF9CA3AF)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isMine) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name, String role) {
    final color = role == 'Officer'
        ? const Color(0xFF059669)
        : const Color(0xFF1E40AF);
    return Container(
      width: 32,
      height: 32,
      decoration:
          BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style:
              TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    final color = role == 'Officer'
        ? const Color(0xFF059669)
        : const Color(0xFF1E40AF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(role,
          style:
              TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle:
                    const TextStyle(color: Color(0xFFB4B4B4), fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFF1E40AF)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF1E40AF),
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _dateLabel(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDay = DateTime(dt.year, dt.month, dt.day);

    if (msgDay == today) return 'Today';
    if (msgDay == yesterday) return 'Yesterday';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _ChatItem {
  final bool isDateSeparator;
  final String? dateLabel;
  final Map<String, dynamic>? message;

  const _ChatItem({
    this.isDateSeparator = false,
    this.dateLabel,
    this.message,
  });
}
