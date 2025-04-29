import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../utils/app_theme.dart';

class AttachmentData {
  final String id;
  final String name;
  final String path;
  final int size;
  final String type;
  final DateTime timestamp;
  String? url; // Remote URL after upload

  AttachmentData({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.type,
    required this.timestamp,
    this.url,
  });

  // Check if the attachment is an image
  bool get isImage => 
      type.contains('image') || 
      ['.jpg', '.jpeg', '.png', '.gif', '.webp'].any(
        (ext) => name.toLowerCase().endsWith(ext)
      );

  // Check if the attachment is a document
  bool get isDocument => 
      ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt'].any(
        (ext) => name.toLowerCase().endsWith(ext)
      );

  // Check if the attachment is a video
  bool get isVideo => 
      type.contains('video') || 
      ['.mp4', '.mov', '.avi', '.mkv', '.webm'].any(
        (ext) => name.toLowerCase().endsWith(ext)
      );

  // Check if the attachment is an audio file
  bool get isAudio => 
      type.contains('audio') || 
      ['.mp3', '.wav', '.ogg', '.m4a'].any(
        (ext) => name.toLowerCase().endsWith(ext)
      );

  // Get human-readable file size
  String get formattedSize {
    final kb = size / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    } else {
      final mb = kb / 1024;
      return '${mb.toStringAsFixed(1)} MB';
    }
  }

  // Get file extension
  String get extension => path.extension(name).toLowerCase();

  // Get appropriate icon for the file type
  IconData get icon {
    if (isImage) return Icons.image;
    if (isVideo) return Icons.video_file;
    if (isAudio) return Icons.audio_file;
    if (isDocument) {
      if (name.endsWith('.pdf')) return Icons.picture_as_pdf;
      if (name.endsWith('.doc') || name.endsWith('.docx')) return Icons.description;
      if (name.endsWith('.xls') || name.endsWith('.xlsx')) return Icons.table_chart;
      if (name.endsWith('.ppt') || name.endsWith('.pptx')) return Icons.slideshow;
      return Icons.insert_drive_file;
    }
    return Icons.attachment;
  }

  // Get appropriate color for the file type
  Color get color {
    if (isImage) return Colors.blue;
    if (isVideo) return Colors.red;
    if (isAudio) return Colors.purple;
    if (isDocument) {
      if (name.endsWith('.pdf')) return Colors.red;
      if (name.endsWith('.doc') || name.endsWith('.docx')) return Colors.blue;
      if (name.endsWith('.xls') || name.endsWith('.xlsx')) return Colors.green;
      if (name.endsWith('.ppt') || name.endsWith('.pptx')) return Colors.orange;
      return Colors.grey;
    }
    return Colors.grey;
  }
}

class FileAttachmentPicker extends StatelessWidget {
  final Function(List<AttachmentData> attachments) onAttachmentsSelected;
  final bool allowMultiple;
  final int maxFiles;

  const FileAttachmentPicker({
    Key? key,
    required this.onAttachmentsSelected,
    this.allowMultiple = true,
    this.maxFiles = 5,
  }) : super(key: key);

  Future<void> _pickFiles(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: allowMultiple,
        allowCompression: true,
      );

      if (result != null) {
        List<AttachmentData> attachments = [];
        for (var i = 0; i < result.files.length && i < maxFiles; i++) {
          final file = result.files[i];
          if (file.path != null) {
            attachments.add(AttachmentData(
              id: DateTime.now().millisecondsSinceEpoch.toString() + '_$i',
              name: file.name,
              path: file.path!,
              size: file.size,
              type: file.extension ?? 'unknown',
              timestamp: DateTime.now(),
            ));
          }
        }
        onAttachmentsSelected(attachments);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking files: $e')),
      );
    }
  }

  Future<void> _pickImages(BuildContext context, {bool fromCamera = false}) async {
    try {
      final ImagePicker picker = ImagePicker();
      
      if (fromCamera) {
        final XFile? image = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
        );
        
        if (image != null) {
          final file = File(image.path);
          final fileSize = await file.length();
          
          onAttachmentsSelected([
            AttachmentData(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: path.basename(image.path),
              path: image.path,
              size: fileSize,
              type: 'image/${path.extension(image.path).replaceAll('.', '')}',
              timestamp: DateTime.now(),
            )
          ]);
        }
      } else {
        final List<XFile> images = await picker.pickMultiImage(
          imageQuality: 80,
        );
        
        if (images.isNotEmpty) {
          List<AttachmentData> attachments = [];
          
          for (var i = 0; i < images.length && i < maxFiles; i++) {
            final image = images[i];
            final file = File(image.path);
            final fileSize = await file.length();
            
            attachments.add(AttachmentData(
              id: DateTime.now().millisecondsSinceEpoch.toString() + '_$i',
              name: path.basename(image.path),
              path: image.path,
              size: fileSize,
              type: 'image/${path.extension(image.path).replaceAll('.', '')}',
              timestamp: DateTime.now(),
            ));
          }
          
          onAttachmentsSelected(attachments);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Attach Files',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImages(context, fromCamera: true);
                  },
                ),
                _AttachmentOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImages(context);
                  },
                ),
                _AttachmentOption(
                  icon: Icons.insert_drive_file,
                  label: 'Document',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    _pickFiles(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _showAttachmentOptions(context),
      icon: const Icon(Icons.attach_file),
      color: AppTheme.primaryColor,
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentOption({
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class FileAttachmentPreview extends StatelessWidget {
  final AttachmentData attachment;
  final VoidCallback? onRemove;
  final bool isPreview;

  const FileAttachmentPreview({
    Key? key,
    required this.attachment,
    this.onRemove,
    this.isPreview = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8.0, bottom: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (attachment.isImage)
                _buildImagePreview()
              else
                _buildFilePreview(),
                
              if (isPreview && onRemove != null)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: InkWell(
                      onTap: onRemove,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        // Image
        Image.file(
          File(attachment.path),
          height: 120,
          width: 120,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, _) => Container(
            height: 120,
            width: 120,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
        
        // Size indicator
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            color: Colors.black.withOpacity(0.5),
            child: Text(
              attachment.formattedSize,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilePreview() {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: attachment.color.withOpacity(0.1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            attachment.icon,
            size: 40,
            color: attachment.color,
          ),
          const SizedBox(height: 8),
          Text(
            attachment.name.length > 15
                ? '${attachment.name.substring(0, 12)}...'
                : attachment.name,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            attachment.formattedSize,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}