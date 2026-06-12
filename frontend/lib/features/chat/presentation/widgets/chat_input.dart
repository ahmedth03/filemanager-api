import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/chat_provider.dart';

// ---------------------------------------------------------------------------
// ChatInput
// ---------------------------------------------------------------------------

class ChatInput extends ConsumerStatefulWidget {
  const ChatInput({
    super.key,
    required this.roomId,
    this.onSend,
  });

  final String roomId;

  /// Optional override for custom send logic (e.g. testing)
  final Future<void> Function(String text)? onSend;

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _hasText = false;
  bool _isSending = false;
  Timer? _typingStopTimer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _typingStopTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }

    if (hasText) {
      // Notify typing
      ref.read(chatProvider.notifier).onUserTyping(widget.roomId);

      // Auto stop typing signal after 3 seconds of inactivity
      _typingStopTimer?.cancel();
      _typingStopTimer = Timer(const Duration(seconds: 3), () {
        ref.read(chatProvider.notifier).onUserStopTyping(widget.roomId);
      });
    } else {
      _typingStopTimer?.cancel();
      ref.read(chatProvider.notifier).onUserStopTyping(widget.roomId);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    // Clear typing signals
    _typingStopTimer?.cancel();
    ref.read(chatProvider.notifier).onUserStopTyping(widget.roomId);

    _controller.clear();
    setState(() {
      _hasText = false;
    });

    try {
      if (widget.onSend != null) {
        await widget.onSend!(text);
      } else {
        await ref.read(chatProvider.notifier).sendMessage(text);
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0
            ? 8
            : 8 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Text field ─────────────────────────────────────────────────
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textDirection: TextDirection.rtl,
                maxLines: null,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
                decoration: const InputDecoration(
                  hintText: 'اكتب رسالتك...',
                  hintStyle: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: AppColors.textHint,
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ── Send button ────────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hasText ? AppColors.primary : AppColors.border,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: _hasText && !_isSending ? _send : null,
                child: Center(
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          color: _hasText ? Colors.white : AppColors.textHint,
                          size: 20,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
