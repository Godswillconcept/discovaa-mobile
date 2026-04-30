import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:discovaa/features/messaging/domain/entities/conversation.dart';
import 'package:discovaa/features/messaging/presentation/providers/messaging_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:mime/mime.dart';
import 'package:discovaa/features/messaging/presentation/widgets/chat_header.dart';

class ChatPage extends ConsumerWidget {
  final Conversation conversation;

  const ChatPage({super.key, required this.conversation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagingState = ref.watch(messagingProvider);
    final messages = messagingState.messages[conversation.id] ?? [];
    final user = const types.User(id: 'user1');

    void handleAttachmentPressed() {
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
                            conversation.id,
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
                    final result = await FilePicker.pickFiles(
                      type: FileType.any,
                    );

                    if (result != null && result.files.single.path != null) {
                      final file = result.files.single;
                      ref
                          .read(messagingProvider.notifier)
                          .sendFileMessage(
                            conversation.id,
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

    void handleMessageTap(BuildContext _, types.Message message) async {
      if (message is types.FileMessage) {
        await OpenFilex.open(message.uri);
      } else if (message is types.ImageMessage) {
        await OpenFilex.open(message.uri);
      }
    }

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
            ChatHeader(conversation: conversation),
            Expanded(
              child: Chat(
                messages: messages,
                onSendPressed: (types.PartialText message) {
                  ref
                      .read(messagingProvider.notifier)
                      .sendMessage(conversation.id, message.text);
                },
                user: user,
                theme: DefaultChatTheme(
                  primaryColor: const Color(0xFF666666),
                  secondaryColor: const Color(0xFFE5E5EA),
                  backgroundColor: Colors.white,
                  inputBackgroundColor: Colors.white,
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
                onAttachmentPressed: handleAttachmentPressed,
                onMessageTap: handleMessageTap,
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
