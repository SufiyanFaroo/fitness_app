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

  Future<void> _pickGalleryAttachment() async {
    final ImagePicker picker = ImagePicker();
    final XFile? selectedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (selectedFile != null) {
      widget.onSendImageAction(File(selectedFile.path));
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
          // 📎 Native Attachment Button Integration
          IconButton(
            icon: const Icon(
              Icons.attach_file_rounded,
              color: Color(0xff92A3FD),
            ),
            onPressed: _pickGalleryAttachment,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (val) =>
                  setState(() => _isTyping = val.trim().isNotEmpty),
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
            onTap: () {
              if (_controller.text.trim().isNotEmpty) {
                widget.onSendMessage(_controller.text.trim());
                _controller.clear();
                setState(() => _isTyping = false);
              }
            },
            child: Container(
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
