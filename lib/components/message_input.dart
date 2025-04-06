import 'package:flutter/material.dart';
import 'package:zenx/utils/constants.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function() onToggleFunctionPanel;
  
  const MessageInput({
    Key? key,
    required this.onSendMessage,
    required this.onToggleFunctionPanel,
  }) : super(key: key);

  @override
  _MessageInputState createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _controller.text.isNotEmpty;
    });
  }

  void _handleSendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSendMessage(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[800]! : Colors.grey[200]!;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.smallPadding,
        vertical: AppTheme.smallPadding / 2,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '输入信息',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.inputRadius),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: backgroundColor,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
              ),
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSendMessage(),
            ),
          ),
          SizedBox(width: 8.0),
          CircleAvatar(
            backgroundColor: AppTheme.primaryBlue,
            child: IconButton(
              icon: Icon(
                _hasText ? Icons.send : Icons.add,
                color: Colors.white,
              ),
              onPressed: _hasText
                  ? _handleSendMessage
                  : widget.onToggleFunctionPanel,
            ),
          ),
        ],
      ),
    );
  }
} 