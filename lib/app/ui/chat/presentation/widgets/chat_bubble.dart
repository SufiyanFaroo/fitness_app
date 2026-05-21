import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final Timestamp timestamp;
  final String messageType;
  final String? mediaUrl;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.timestamp,
    required this.messageType,
    this.mediaUrl,
  });

  void _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(
                  colors: [Color(0xff92A3FD), Color(0xff9DCEFF)],
                )
              : null,
          color: isMe ? null : const Color(0xFFF7F8F8),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe
                ? const Radius.circular(16)
                : const Radius.circular(0),
            bottomRight: isMe
                ? const Radius.circular(0)
                : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // 🖼️ Conditional Render: High-Speed Image View Attachment
            if (messageType == "image" && mediaUrl != null)
              GestureDetector(
                onTap:
                    () {}, // Action to expand full screen image view if required
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: mediaUrl!,
                    placeholder: (context, url) => const SizedBox(
                      height: 150,
                      width: 200,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.broken_image),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // 🔗 Conditional Render: Clickable Hyperlink Text Wrapper
            if (messageType == "link")
              GestureDetector(
                onTap: () => _launchURL(text),
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            // 💬 Standard View Payload Rule
            if (messageType == "text")
              Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

            const SizedBox(height: 4),
            Text(
              DateFormat('hh:mm a').format(timestamp.toDate()),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.black38,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
