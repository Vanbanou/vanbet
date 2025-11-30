import 'package:flutter/material.dart';

class InputDialog extends StatefulWidget {
  final String title;

  const InputDialog({
    super.key,
    required this.title,
  });

  @override
  ResultDialogState createState() => ResultDialogState();
}

class ResultDialogState extends State<InputDialog> {
  final ScrollController _scrollController = ScrollController();
  bool _isAtTop = true;
  bool _isAtBottom = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollPosition();
    });
  }

  void _checkScrollPosition() {
    final position = _scrollController.position;
    setState(() {
      _isAtTop = position.pixels == position.minScrollExtent;
      _isAtBottom = position.pixels == position.maxScrollExtent;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 370.0, // altura máxima
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Divider superior
            Visibility(
              visible: (!_isAtTop && !_isAtBottom) || !_isAtTop,
              child: const Divider(
                height: 1.5,
                thickness: 1.5,
              ),
            ),
            Flexible(
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  setState(() {
                    _isAtTop = scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.minScrollExtent;
                    _isAtBottom = scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.maxScrollExtent;
                  });
                  return true;
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  child: Column(children: [
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(label: Text("Montante (Kz)")),
                      textInputAction: TextInputAction.done,
                      onChanged: (value) {},
                    ),
                  ]),
                ),
              ),
            ),
            // Divider inferior
            Visibility(
              visible: (!_isAtBottom && !_isAtTop) || !_isAtBottom,
              child: const Divider(
                height: 1.5,
                thickness: 1.5,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Ok")),
      ],
    );
  }
}

class DetailItem {
  final String title;
  final String subtitle;

  DetailItem({
    required this.title,
    required this.subtitle,
  });
}
