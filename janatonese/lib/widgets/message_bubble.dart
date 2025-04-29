import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../utils/app_theme.dart';
import 'file_attachment.dart';
import 'message_status.dart';

class Message {
  final String id;
  final String text;
  final String senderId;
  final DateTime timestamp;
  final List<AttachmentData> attachments;
  final MessageStatus status;
  final DateTime? readAt;
  
  Message({
    required this.id,
    required this.text,
    required this.senderId,
    required this.timestamp,
    this.attachments = const [],
    this.status = MessageStatus.sent,
    this.readAt,
  });
}

class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(String emoji)? onReactionSelected;
  
  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.onTap,
    this.onLongPress,
    this.onReactionSelected,
  }) : super(key: key);
  
  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> with SingleTickerProviderStateMixin {
  bool _isReactionMenuOpen = false;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: widget.onTap,
          onLongPress: () {
            setState(() {
              _isReactionMenuOpen = !_isReactionMenuOpen;
            });
            
            if (widget.onLongPress != null) {
              widget.onLongPress!();
            }
          },
          child: Container(
            margin: EdgeInsets.only(
              top: 4,
              bottom: 4,
              left: widget.isMe ? 64 : 16,
              right: widget.isMe ? 16 : 64,
            ),
            child: Column(
              crossAxisAlignment:
                  widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Main bubble
                _buildMessageBubble(),
                
                // Timestamp and delivery status
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 4.0, right: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTimestamp(widget.message.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (widget.isMe) ...[
                        const SizedBox(width: 4),
                        MessageStatusIndicator(
                          status: widget.message.status,
                          size: 12,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Read receipt (only shown for sent messages that have been read)
                if (widget.isMe && 
                    widget.message.status == MessageStatus.read && 
                    widget.message.readAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0, right: 4.0),
                    child: ReadReceiptTimestamp(
                      readAt: widget.message.readAt,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        // Emoji reaction menu
        if (_isReactionMenuOpen)
          Padding(
            padding: EdgeInsets.only(
              left: widget.isMe ? 0 : 16,
              right: widget.isMe ? 16 : 0,
              bottom: 8,
            ),
            child: ContextualEmojiReactions(
              onReactionSelected: (emoji) {
                setState(() {
                  _isReactionMenuOpen = false;
                });
                
                if (widget.onReactionSelected != null) {
                  widget.onReactionSelected!(emoji);
                }
              },
            ),
          ).animate().fadeIn(duration: 200.ms).scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.0, 1.0),
            curve: Curves.easeOutBack,
            duration: 300.ms,
          ),
      ],
    );
  }
  
  Widget _buildMessageBubble() {
    final hasAttachments = widget.message.attachments.isNotEmpty;
    
    return Container(
      padding: EdgeInsets.all(hasAttachments ? 8 : 12),
      decoration: BoxDecoration(
        color: widget.isMe
            ? AppTheme.primaryColor.withOpacity(0.9)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16).copyWith(
          bottomRight: widget.isMe ? const Radius.circular(4) : null,
          bottomLeft: !widget.isMe ? const Radius.circular(4) : null,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 1),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attachments
          if (hasAttachments) ...[
            _buildAttachments(),
            if (widget.message.text.isNotEmpty)
              const SizedBox(height: 8),
          ],
          
          // Message text
          if (widget.message.text.isNotEmpty)
            Text(
              widget.message.text,
              style: TextStyle(
                color: widget.isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildAttachments() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.message.attachments.map((attachment) {
        return FileAttachmentPreview(
          attachment: attachment,
          isPreview: false,
        );
      }).toList(),
    );
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      // Format as time only for today
      return _formatTimeOnly(timestamp);
    } else if (messageDate == yesterday) {
      // Format as "Yesterday at HH:MM"
      return 'Yesterday';
    } else if (now.difference(timestamp).inDays < 7) {
      // Format as weekday for messages within a week
      final weekdayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return weekdayNames[timestamp.weekday - 1];
    } else {
      // Format as short date for older messages
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String _formatTimeOnly(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}