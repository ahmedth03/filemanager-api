import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/message.dart';

// ---------------------------------------------------------------------------
// MessageBubble
// ---------------------------------------------------------------------------

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isSent,
    this.showAvatar = false,
    this.senderAvatar,
    this.senderName,
  });

  final Message message;

  /// True when the current user sent this message (right-aligned, blue).
  final bool isSent;

  /// Whether to show the sender's avatar (for received messages).
  final bool showAvatar;
  final String? senderAvatar;
  final String? senderName;

  static const double _maxBubbleWidth = 280.0;
  static const double _avatarSize = 32.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSent && showAvatar) _buildAvatar(),
          if (!isSent && !showAvatar) const SizedBox(width: _avatarSize + 8),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxBubbleWidth),
            child: Column(
              crossAxisAlignment: isSent
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                _buildBubbleContent(context),
                const SizedBox(height: 3),
                _buildMeta(),
              ],
            ),
          ),
          const SizedBox(width: 6),
          if (isSent) const SizedBox(width: _avatarSize + 8),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: _avatarSize / 2,
      backgroundColor: AppColors.primaryLight,
      backgroundImage:
          senderAvatar != null ? NetworkImage(senderAvatar!) : null,
      child: senderAvatar == null
          ? Text(
              _initial(senderName ?? '?'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            )
          : null,
    );
  }

  Widget _buildBubbleContent(BuildContext context) {
    final bubbleColor = isSent ? AppColors.primary : Colors.white;
    final textColor = isSent ? Colors.white : AppColors.textPrimary;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isSent ? 18 : 4),
      bottomRight: Radius.circular(isSent ? 4 : 18),
    );

    if (message.isImage) {
      return _buildImageBubble(borderRadius);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message.content,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          color: textColor,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildImageBubble(BorderRadius borderRadius) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: CachedNetworkImage(
        imageUrl: message.content,
        width: 220,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 220,
          height: 160,
          color: AppColors.shimmerBase,
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 220,
          height: 160,
          color: AppColors.background,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_outlined,
                  color: AppColors.textHint, size: 40),
              SizedBox(height: 8),
              Text(
                'تعذر تحميل الصورة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeta() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isSent) _buildStatusIcon(),
        if (isSent) const SizedBox(width: 4),
        Text(
          DateFormat('HH:mm').format(message.createdAt.toLocal()),
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIcon() {
    // Optimistic messages (not yet confirmed) show a clock
    final isOptimistic = message.id.startsWith('optimistic_');
    if (isOptimistic) {
      return const Icon(Icons.access_time, size: 13, color: AppColors.textHint);
    }

    if (message.isRead) {
      // Double blue tick
      return const Icon(Icons.done_all, size: 13, color: AppColors.primaryLight);
    } else {
      // Single grey tick (sent but not read)
      return const Icon(Icons.done, size: 13, color: AppColors.textHint);
    }
  }

  String _initial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }
}

// ---------------------------------------------------------------------------
// TypingBubble — animated "جاري الكتابة..."
// ---------------------------------------------------------------------------

class TypingBubble extends StatefulWidget {
  const TypingBubble({super.key});

  @override
  State<TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<TypingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _dot1;
  late Animation<double> _dot2;
  late Animation<double> _dot3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _dot1 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );
    _dot2 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeInOut),
      ),
    );
    _dot3 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.9, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4, right: 60),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'جاري الكتابة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) {
                    return Row(
                      children: [
                        _buildDot(_dot1.value),
                        const SizedBox(width: 2),
                        _buildDot(_dot2.value),
                        const SizedBox(width: 2),
                        _buildDot(_dot3.value),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(double opacity) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.textSecondary.withOpacity(opacity.clamp(0.3, 1.0)),
      ),
    );
  }
}
