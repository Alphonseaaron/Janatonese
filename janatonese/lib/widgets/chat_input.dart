import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'emoji_picker_widget.dart';
import 'file_attachment.dart';

class ChatInputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final Function(String) onSendMessage;
  final Function(List<AttachmentData>) onAttachmentsSelected;
  final bool isTyping;
  final Function(bool) onTypingStatusChanged;

  const ChatInputField({
    Key? key,
    required this.controller,
    this.focusNode,
    required this.onSendMessage,
    required this.onAttachmentsSelected,
    required this.isTyping,
    required this.onTypingStatusChanged,
  }) : super(key: key);

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  bool _isEmojiPickerOpen = false;
  bool _hasText = false;
  
  // For typing indicator
  DateTime? _lastTypingNotification;
  
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateTextState);
  }
  
  @override
  void dispose() {
    widget.controller.removeListener(_updateTextState);
    super.dispose();
  }
  
  void _updateTextState() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
    
    // Check if typing status needs to be sent
    // Only send typing notification if text is not empty 
    // and last notification was more than 2 seconds ago
    if (hasText) {
      final now = DateTime.now();
      if (_lastTypingNotification == null || 
          now.difference(_lastTypingNotification!).inSeconds >= 2) {
        _lastTypingNotification = now;
        
        if (!widget.isTyping) {
          widget.onTypingStatusChanged(true);
        }
      }
    } else if (widget.isTyping) {
      widget.onTypingStatusChanged(false);
    }
  }
  
  void _handleSendPressed() {
    final text = widget.controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSendMessage(text);
      widget.controller.clear();
      
      // Reset typing status
      if (widget.isTyping) {
        widget.onTypingStatusChanged(false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8.0,
        vertical: 8.0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 5,
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Attachment button
                FileAttachmentPicker(
                  onAttachmentsSelected: widget.onAttachmentsSelected,
                ),
                
                // Text field
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: widget.controller,
                            focusNode: widget.focusNode,
                            maxLines: 5,
                            minLines: 1,
                            decoration: const InputDecoration(
                              hintText: 'Type a message',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                            ),
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ),
                        
                        // Emoji button
                        EmojiPickerWidget(
                          textController: widget.controller,
                          focusNode: widget.focusNode,
                          onEmojiPickerToggle: (isOpen) {
                            setState(() {
                              _isEmojiPickerOpen = isOpen;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Send button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  child: _hasText
                      ? IconButton(
                          icon: const Icon(Icons.send),
                          color: AppTheme.primaryColor,
                          onPressed: _handleSendPressed,
                        )
                      : IconButton(
                          icon: const Icon(Icons.mic),
                          color: Colors.grey.shade600,
                          onPressed: () {
                            // Voice recording feature would go here
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Voice recording coming soon'),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
            if (_isEmojiPickerOpen)
              SizedBox(
                height: 250,
                child: EmojiPickerWidget(
                  textController: widget.controller,
                  focusNode: widget.focusNode,
                ),
              ),
          ],
        ),
      ),
    );
  }
}