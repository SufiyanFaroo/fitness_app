import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function(File) onSendImageAction;

  const MessageInput({
    super.key,
    required this.onSendMessage,
    required this.onSendImageAction,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  bool _isTyping = false;

  // ✅ MULTI-SOURCE MEDIA PICKER: Unified framework to pick from Gallery or capture with Camera natively
  Future<void> _handleMediaAttachmentAction(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? selectedFile = await picker.pickImage(
        source: source,
        imageQuality:
            50, // Compresses image to optimize bandwidth speeds over cloud sync pipelines
      );
      if (selectedFile != null) {
        widget.onSendImageAction(File(selectedFile.path));
      }
    } catch (e) {
      debugPrint("Error picking chat resource layout item: $e");
    }
  }

  // ✅ ATTACHMENT MENU DIALOG: Interactive sheet allowing the user to select media pipelines smoothly
  void _showAttachmentModalOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOptionTile(Icons.image_rounded, "Gallery", () {
                  Navigator.pop(context);
                  _handleMediaAttachmentAction(ImageSource.gallery);
                }),
                _buildAttachmentOptionTile(
                  Icons.camera_alt_rounded,
                  "Camera",
                  () {
                    Navigator.pop(context);
                    _handleMediaAttachmentAction(ImageSource.camera);
                  },
                ),
              ],
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOptionTile(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xff92A3FD).withOpacity(0.12),
              child: Icon(icon, color: const Color(0xff92A3FD), size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ DISPATCH ACTION SUBMIT: Validates text properties and triggers message dispatch arrays
  void _executeMessageSubmission() {
    final String cleanMessage = _controller.text.trim();
    if (cleanMessage.isNotEmpty) {
      widget.onSendMessage(cleanMessage);
      _controller.clear();
      setState(() => _isTyping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
      ),
      child: Row(
        children: [
          // 📎 LINKED ATTACHMENT MANAGER TRIGGER POINTER
          IconButton(
            icon: const Icon(
              Icons.attach_file_rounded,
              color: Color(0xff92A3FD),
            ),
            onPressed: () => _showAttachmentModalOptions(context),
          ),

          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (val) =>
                  setState(() => _isTyping = val.trim().isNotEmpty),
              onSubmitted: (_) =>
                  _executeMessageSubmission(), // ✅ ACTION TRIGERRED: Sends natively when user clicks 'Send' keyboard keys
              textInputAction: TextInputAction.send,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Type a professional message...",
                filled: true,
                fillColor: const Color(0xFFF7F8F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          GestureDetector(
            onTap: _executeMessageSubmission,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _isTyping
                    ? const LinearGradient(
                        colors: [Color(0xffC58BF2), Color(0xffEEA4CE)],
                      )
                    : null,
                color: _isTyping ? null : Colors.grey.shade300,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
