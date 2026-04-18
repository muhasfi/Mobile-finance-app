import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/theme.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/shared_widgets.dart';

// ── Model ─────────────────────────────────────────────────────────────────────
class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  _ChatMessage({required this.text, required this.isUser}) : time = DateTime.now();
}

// ── State ─────────────────────────────────────────────────────────────────────
// Simpan messages + loading dalam satu state agar reactive
class _ChatState {
  final List<_ChatMessage> messages;
  final bool isLoading;
  const _ChatState({required this.messages, required this.isLoading});

  _ChatState copyWith({List<_ChatMessage>? messages, bool? isLoading}) =>
      _ChatState(
        messages:  messages  ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
      );
}

class _ChatNotifier extends StateNotifier<_ChatState> {
  _ChatNotifier() : super(_ChatState(
    messages: [
      _ChatMessage(
        text: 'Halo! 👋 Saya Fina AI, asisten keuangan kamu.\nAda yang bisa saya bantu hari ini?',
        isUser: false,
      ),
    ],
    isLoading: false,
  ));

  String? _conversationId;

  Future<void> send(String message) async {
    if (message.trim().isEmpty || state.isLoading) return;

    state = state.copyWith(
      messages: [...state.messages, _ChatMessage(text: message, isUser: true)],
      isLoading: true,
    );

    try {
      final res = await ApiService().post(ApiConstants.aiChat, data: {
        'message': message,
        if (_conversationId != null) 'conversation_id': _conversationId,
      });

      _conversationId = res['data']?['conversation_id'] as String?;
      final reply     = res['data']?['reply'] as String? ?? 'Maaf, tidak ada respons.';
      state = state.copyWith(
        messages: [...state.messages, _ChatMessage(text: reply, isUser: false)],
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        messages: [...state.messages,
          _ChatMessage(text: '⚠️ ${e.message}', isUser: false)],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        messages: [...state.messages,
          _ChatMessage(text: '⚠️ Terjadi kesalahan koneksi.', isUser: false)],
        isLoading: false,
      );
    }
  }

  Future<void> reset() async {
    try {
      await ApiService().post(ApiConstants.aiChatReset, data: {
        if (_conversationId != null) 'conversation_id': _conversationId,
      });
    } catch (_) {}
    _conversationId = null;
    state = _ChatState(
      messages: [
        _ChatMessage(
          text: 'Percakapan direset. Halo lagi! 👋 Ada yang bisa saya bantu?',
          isUser: false,
        ),
      ],
      isLoading: false,
    );
  }
}

final _chatProvider =
    StateNotifierProvider.autoDispose<_ChatNotifier, _ChatState>(
  (_) => _ChatNotifier());

// ─────────────────────────────────────────────────────────────────────────────
const _quickPrompts = [
  '💡 Insight bulan ini',
  '📊 Cek anggaran saya',
  '🎯 Tips hemat pengeluaran',
  '📈 Analisa pengeluaran terbesar',
  '🔄 Tagihan yang akan jatuh tempo',
];

// ─────────────────────────────────────────────────────────────────────────────
class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _State();
}

class _State extends ConsumerState<AiChatScreen> {
  final _ctrl       = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final msg = text ?? _ctrl.text;
    if (msg.trim().isEmpty) return;
    ref.read(_chatProvider.notifier).send(msg);
    _ctrl.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(_chatProvider);
    final messages  = chatState.messages;
    final loading   = chatState.isLoading;

    ref.listen(_chatProvider, (_, __) => _scrollToBottom());

    return Scaffold(
      backgroundColor: FinaColors.bg,
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [FinaColors.copper, Color(0xFF8B4A1A)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('🤖', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Fina AI',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            Row(children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(
                  color: FinaColors.green, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              const Text('Online',
                style: TextStyle(fontSize: 10, color: FinaColors.green)),
            ]),
          ]),
        ]),
        actions: [
          IconButton(
            onPressed: () => _confirmReset(context),
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Reset percakapan',
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: messages.length + (loading ? 1 : 0),
            itemBuilder: (_, i) {
              if (loading && i == messages.length) return const _TypingBubble();
              return _MessageBubble(msg: messages[i]);
            },
          ),
        ),
        if (messages.length <= 1) _QuickPrompts(onTap: _send),
        _InputBar(controller: _ctrl, onSend: _send, isLoading: loading),
      ]),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FinaColors.surface,
        title: const Text('Reset Percakapan?'),
        content: const Text('Riwayat chat akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(_chatProvider.notifier).reset();
            },
            child: const Text('Reset', style: TextStyle(color: FinaColors.red))),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 60),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  gradient: kCopperGradient,
                  borderRadius: BorderRadius.only(
                    topLeft:     Radius.circular(18),
                    topRight:    Radius.circular(18),
                    bottomLeft:  Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(msg.text,
                  style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.45)),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 60),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28, height: 28,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [FinaColors.copper, Color(0xFF8B4A1A)]),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('🤖', style: TextStyle(fontSize: 13)),
          ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: FinaColors.surface,
                border: Border.all(color: FinaColors.border),
                borderRadius: const BorderRadius.only(
                  topLeft:     Radius.circular(4),
                  topRight:    Radius.circular(18),
                  bottomLeft:  Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Text(msg.text,
                style: const TextStyle(fontSize: 13, color: FinaColors.text, height: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 60),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28, height: 28,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [FinaColors.copper, Color(0xFF8B4A1A)]),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('🤖', style: TextStyle(fontSize: 13)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: FinaColors.surface,
              border: Border.all(color: FinaColors.border),
              borderRadius: const BorderRadius.only(
                topLeft:     Radius.circular(4),
                topRight:    Radius.circular(18),
                bottomLeft:  Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final offset = ((_anim.value * 3) - i).clamp(0.0, 1.0);
                  final scale  = 0.6 + 0.4 * (offset < 0.5 ? offset * 2 : (1 - offset) * 2);
                  return Container(
                    width: 7, height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(200, 120, 58, 0.4 + scale * 0.6),
                      shape: BoxShape.circle,
                    ),
                    transform: Matrix4.identity()..scale(scale),
                    transformAlignment: Alignment.center,
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickPrompts extends StatelessWidget {
  final ValueChanged<String> onTap;
  const _QuickPrompts({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickPrompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => onTap(_quickPrompts[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: FinaColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: FinaColors.border),
            ),
            child: Text(_quickPrompts[i], style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w500, color: FinaColors.text2)),
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isLoading;
  const _InputBar({required this.controller, required this.onSend, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16, 10, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: FinaColors.bg,
        border: Border(top: BorderSide(color: FinaColors.border)),
      ),
      child: Row(children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            decoration: BoxDecoration(
              color: FinaColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: FinaColors.border),
            ),
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 13, color: FinaColors.text),
              maxLines: 4, minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: 'Tanya Fina sesuatu...',
                hintStyle: TextStyle(fontSize: 13, color: FinaColors.muted),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
                isDense: true,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: isLoading ? null : onSend,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: isLoading ? null : kCopperGradient,
              color: isLoading ? FinaColors.surface2 : null,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: FinaColors.copper))
                : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
          ),
        ),
      ]),
    );
  }
}
