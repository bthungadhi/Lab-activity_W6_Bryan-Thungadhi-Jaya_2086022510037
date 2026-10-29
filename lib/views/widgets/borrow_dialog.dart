import 'package:flutter/material.dart';


class BorrowDialog extends StatefulWidget {
  const BorrowDialog({super.key, required this.bookTitle});

  final String bookTitle;

  @override
  State<BorrowDialog> createState() => _BorrowDialogState();
}

class _BorrowDialogState extends State<BorrowDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Borrow "${widget.bookTitle}"'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Student ID'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}