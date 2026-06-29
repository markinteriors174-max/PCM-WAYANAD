import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class ProjectHubChatTab extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  final bool isLoading;
  final TextEditingController messageController;
  final ScrollController scrollController;
  final VoidCallback onSendMessage;
  final String Function(dynamic) formatTimestamp;
  final String currentRole;

  const ProjectHubChatTab({
    super.key,
    required this.messages,
    required this.isLoading,
    required this.messageController,
    required this.scrollController,
    required this.onSendMessage,
    required this.formatTimestamp,
    required this.currentRole,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && messages.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.border));
    }

    return Column(
      children: [
        // Message list
        Expanded(
          child: messages.isEmpty
              ? _buildEmptyChatState()
              : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['sender'] == currentRole;
                    return _buildMessageBubble(context, msg, isMe);
                  },
                ),
        ),
        
        // Input bar
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2)),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 12,
              left: 12,
              right: 12,
              top: 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Type message here...',
                      hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.background.withValues(alpha: 0.4),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                      ),
                    ),
                    onSubmitted: (_) => onSendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.border,
                  radius: 22,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: onSendMessage,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(BuildContext context, Map<String, dynamic> msg, bool isMe) {
    final String content = msg['message'] ?? '';
    final String timeStr = formatTimestamp(msg['created_at']);
    final String status = msg['status'] ?? 'sent';

    IconData statusIcon = Icons.done;
    Color statusColor = isMe ? Colors.white70 : Colors.black38;

    if (status == 'delivered') {
      statusIcon = Icons.done_all;
    } else if (status == 'read') {
      statusIcon = Icons.done_all;
      statusColor = isMe ? Colors.cyanAccent : Colors.blue;
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primaryButton : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
          border: isMe ? null : Border.all(color: AppColors.border.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              offset: const Offset(1, 2),
              blurRadius: 3,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content,
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.labelColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.black38,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(statusIcon, size: 12, color: statusColor),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChatState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.forum_outlined, size: 48, color: Colors.black26),
          const SizedBox(height: 12),
          const Text(
            'No messages yet',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.labelColor, fontSize: 14),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Send a message to sync instructions or updates to the portal.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black45, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
