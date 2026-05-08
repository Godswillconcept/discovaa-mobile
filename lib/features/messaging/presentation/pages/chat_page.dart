import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:discovaa/core/network/websocket_client.dart';
import 'package:discovaa/features/messaging/domain/entities/conversation.dart';
import 'package:discovaa/features/messaging/presentation/providers/messaging_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:mime/mime.dart';
import 'package:discovaa/features/messaging/presentation/widgets/chat_header.dart';

class ChatPage extends ConsumerStatefulWidget {
  final Conversation conversation;

  const ChatPage({super.key, required this.conversation});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final user = const types.User(id: 'user1');
  Timer? _typingTimer;
  final bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Subscribe to conversation thread via WebSocket
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(messagingProvider.notifier)
          .subscribeToConversation(widget.conversation.id);
      // Mark messages as read
      ref.read(messagingProvider.notifier).markAsRead(widget.conversation.id);
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    // Stop typing indicator
    if (_isTyping) {
      ref
          .read(messagingProvider.notifier)
          .sendTypingStop(widget.conversation.id);
    }
    // Unsubscribe from conversation thread
    ref
        .read(messagingProvider.notifier)
        .unsubscribeFromConversation(widget.conversation.id);
    super.dispose();
  }

  void _handleAttachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: 144,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final result = await picker.pickImage(
                    imageQuality: 70,
                    maxWidth: 1440,
                    source: ImageSource.gallery,
                  );
                  if (result != null) {
                    final bytes = await result.readAsBytes();
                    final image = await decodeImageFromList(bytes);

                    ref
                        .read(messagingProvider.notifier)
                        .sendImageMessage(
                          widget.conversation.id,
                          result.path,
                          result.name,
                          bytes.length,
                          width: image.width.toDouble(),
                          height: image.height.toDouble(),
                        );
                  }
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Photo'),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final result = await FilePicker.pickFiles(type: FileType.any);

                  if (result != null && result.files.single.path != null) {
                    final file = result.files.single;
                    ref
                        .read(messagingProvider.notifier)
                        .sendFileMessage(
                          widget.conversation.id,
                          file.path!,
                          file.name,
                          file.size,
                          mimeType: lookupMimeType(file.path!),
                        );
                  }
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('File'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMessageTap(BuildContext _, types.Message message) async {
    if (message is types.FileMessage) {
      await OpenFilex.open(message.uri);
    } else if (message is types.ImageMessage) {
      await OpenFilex.open(message.uri);
    }
  }

  Widget _buildConnectionStatusIndicator(WebSocketConnectionState state) {
    Color color;
    String text;

    switch (state) {
      case WebSocketConnectionState.connected:
        color = Colors.green;
        text = 'Connected';
        break;
      case WebSocketConnectionState.connecting:
      case WebSocketConnectionState.reconnecting:
        color = Colors.orange;
        text = 'Connecting...';
        break;
      case WebSocketConnectionState.disconnected:
      case WebSocketConnectionState.error:
        color = Colors.red;
        text = 'Offline';
        break;
    }

    if (state == WebSocketConnectionState.connected) {
      return const SizedBox.shrink(); // Hide when connected
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isTyping) {
    if (!isTyping) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '${widget.conversation.artisanName} is typing...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagingState = ref.watch(messagingProvider);
    final messages = messagingState.messages[widget.conversation.id] ?? [];
    final connectionState = messagingState.connectionState;
    final isOtherTyping = messagingState.typingUsers.isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            ChatHeader(conversation: widget.conversation),
            _buildConnectionStatusIndicator(connectionState),
            _buildTypingIndicator(isOtherTyping),
            Expanded(
              child: Chat(
                messages: messages,
                onSendPressed: (types.PartialText message) {
                  ref
                      .read(messagingProvider.notifier)
                      .sendMessage(widget.conversation.id, message.text);
                },
                user: user,
                theme: DefaultChatTheme(
                  primaryColor: const Color(0xFF666666),
                  secondaryColor: const Color(0xFFE5E5EA),
                  backgroundColor: Colors.white,
                  inputBackgroundColor: const Color(0xFFF9FAFB),
                  inputTextColor: Colors.black,
                  inputTextCursorColor: Colors.black,
                  inputTextStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  messageBorderRadius: 18,
                  sentMessageBodyTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  receivedMessageBodyTextStyle: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  inputBorderRadius: const BorderRadius.all(
                    Radius.circular(24),
                  ),
                  inputMargin: EdgeInsets.zero,
                  inputPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  attachmentButtonIcon: const Icon(
                    Icons.attach_file,
                    color: Colors.black,
                  ),
                  sendButtonIcon: const Icon(
                    Icons.send_rounded,
                    color: Colors.black,
                  ),
                ),
                onAttachmentPressed: _handleAttachmentPressed,
                onMessageTap: _handleMessageTap,
                showUserAvatars: false,
                showUserNames: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
