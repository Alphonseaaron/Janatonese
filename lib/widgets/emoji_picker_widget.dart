import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../utils/app_theme.dart';

class EmojiPickerWidget extends StatefulWidget {
  final TextEditingController textController;
  final FocusNode? focusNode;
  final Function(bool isOpen)? onEmojiPickerToggle;

  const EmojiPickerWidget({
    Key? key,
    required this.textController,
    this.focusNode,
    this.onEmojiPickerToggle,
  }) : super(key: key);

  @override
  State<EmojiPickerWidget> createState() => _EmojiPickerWidgetState();
}

class _EmojiPickerWidgetState extends State<EmojiPickerWidget> {
  bool _isEmojiPickerOpen = false;

  void _toggleEmojiPicker() {
    setState(() {
      _isEmojiPickerOpen = !_isEmojiPickerOpen;
      if (_isEmojiPickerOpen) {
        widget.focusNode?.unfocus();
      } else {
        widget.focusNode?.requestFocus();
      }
    });
    
    if (widget.onEmojiPickerToggle != null) {
      widget.onEmojiPickerToggle!(_isEmojiPickerOpen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          onPressed: _toggleEmojiPicker,
          icon: Icon(
            _isEmojiPickerOpen ? Icons.keyboard : Icons.emoji_emotions_outlined,
            color: _isEmojiPickerOpen 
                ? AppTheme.primaryColor 
                : Colors.grey.shade600,
          ),
          splashRadius: 20,
        ),
        if (_isEmojiPickerOpen)
          SizedBox(
            height: 250,
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                widget.textController.text = widget.textController.text + emoji.emoji;
                // Move cursor to the end
                widget.textController.selection = TextSelection.fromPosition(
                  TextPosition(offset: widget.textController.text.length),
                );
              },
              onBackspacePressed: () {
                if (widget.textController.text.isNotEmpty) {
                  final text = widget.textController.text;
                  widget.textController.text = text.substring(0, text.length - 1);
                  // Move cursor to the end
                  widget.textController.selection = TextSelection.fromPosition(
                    TextPosition(offset: widget.textController.text.length),
                  );
                }
              },
              config: Config(
                columns: 7,
                emojiSizeMax: 28,
                verticalSpacing: 0,
                horizontalSpacing: 0,
                initCategory: Category.RECENT,
                bgColor: Theme.of(context).scaffoldBackgroundColor,
                indicatorColor: AppTheme.primaryColor,
                iconColor: Colors.grey,
                iconColorSelected: AppTheme.primaryColor,
                progressIndicatorColor: AppTheme.primaryColor,
                backspaceColor: AppTheme.primaryColor,
                skinToneDialogBgColor: Colors.white,
                skinToneIndicatorColor: Colors.grey,
                enableSkinTones: true,
                showRecentsTab: true,
                recentsLimit: 28,
                noRecents: const Text(
                  'No Recents',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                tabIndicatorAnimDuration: kTabScrollDuration,
                categoryIcons: const CategoryIcons(),
                buttonMode: ButtonMode.MATERIAL,
              ),
            ),
          ),
      ],
    );
  }
}

class ContextualEmojiReactions extends StatelessWidget {
  final List<String> reactions;
  final Function(String emoji) onReactionSelected;
  final List<String> quickReactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  ContextualEmojiReactions({
    Key? key,
    this.reactions = const [],
    required this.onReactionSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...quickReactions.map((emoji) => _buildEmojiButton(emoji)),
          if (reactions.isNotEmpty) const SizedBox(width: 4),
          ...reactions.map((emoji) => _buildEmojiButton(emoji)),
        ],
      ),
    );
  }

  Widget _buildEmojiButton(String emoji) {
    return InkWell(
      onTap: () => onReactionSelected(emoji),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}