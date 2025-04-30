import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';

enum MessageStatus {
  sending,    // Message is being sent
  sent,       // Message has been sent to the server
  delivered,  // Message has been delivered to recipient device
  read,       // Message has been read by the recipient
  failed,     // Message failed to send
}

/// Widget that shows a message's status (sending, sent, delivered, read, failed)
class MessageStatusIndicator extends StatelessWidget {
  final MessageStatus status;
  final Color? color;
  final double size;

  const MessageStatusIndicator({
    Key? key,
    required this.status,
    this.color,
    this.size = 14.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.sending:
        return _buildSendingIndicator();
      case MessageStatus.sent:
        return _buildIcon(Icons.check, color ?? Colors.grey.shade600);
      case MessageStatus.delivered:
        return _buildIcon(Icons.done_all, color ?? Colors.grey.shade600);
      case MessageStatus.read:
        return _buildIcon(Icons.done_all, color ?? AppTheme.primaryColor);
      case MessageStatus.failed:
        return _buildIcon(Icons.error_outline, Colors.red);
      default:
        return const SizedBox();
    }
  }

  Widget _buildIcon(IconData icon, Color iconColor) {
    return Icon(
      icon,
      color: iconColor,
      size: size,
    );
  }

  Widget _buildSendingIndicator() {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.0,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Colors.grey.shade400,
        ),
      ),
    );
  }
}

/// Widget that shows typing indicator animation
class TypingIndicator extends StatelessWidget {
  final String? typingUserName;
  final bool showText;
  final Color bubbleColor;
  final Color dotsColor;

  const TypingIndicator({
    Key? key,
    this.typingUserName,
    this.showText = true,
    this.bubbleColor = const Color(0xFFEDEDED),
    this.dotsColor = const Color(0xFF8A8A8A),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 3),
                _buildDot(100),
                const SizedBox(width: 3),
                _buildDot(200),
              ],
            ),
          ),
          if (showText && typingUserName != null)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                '$typingUserName is typing...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDot(int delay) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: dotsColor,
        shape: BoxShape.circle,
      ),
    )
    .animate(onPlay: (controller) => controller.repeat())
    .fadeOut(
      begin: 1.0,
      end: 0.3,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    )
    .then(delay: Duration(milliseconds: delay))
    .fadeIn(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }
}

/// Widget that shows when a message was read
class ReadReceiptTimestamp extends StatelessWidget {
  final DateTime? readAt;
  final Color textColor;
  final double fontSize;

  const ReadReceiptTimestamp({
    Key? key,
    required this.readAt,
    this.textColor = Colors.grey,
    this.fontSize = 11.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (readAt == null) {
      return const SizedBox();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.visibility,
          size: fontSize + 2,
          color: textColor,
        ),
        const SizedBox(width: 4),
        Text(
          _formatReadTime(readAt!),
          style: TextStyle(
            fontSize: fontSize,
            color: textColor,
          ),
        ),
      ],
    );
  }

  String _formatReadTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      // Format as time only for today
      return 'Read today at ${_formatTimeOnly(time)}';
    } else if (messageDate == yesterday) {
      // Format as "Yesterday at HH:MM"
      return 'Read yesterday at ${_formatTimeOnly(time)}';
    } else {
      // Format as "MMM D at HH:MM"
      return 'Read on ${_formatDateAndTime(time)}';
    }
  }

  String _formatTimeOnly(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDateAndTime(DateTime time) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[time.month - 1];
    final day = time.day;
    final timeStr = _formatTimeOnly(time);
    return '$month $day at $timeStr';
  }
}