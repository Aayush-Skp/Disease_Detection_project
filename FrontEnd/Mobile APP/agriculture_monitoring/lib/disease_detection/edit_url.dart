import 'package:flutter/material.dart';

class EditPage extends StatefulWidget {
  final String currentUrl;
  final String sourceUrl;

  EditPage({required this.currentUrl, required this.sourceUrl});

  @override
  _EditPageState createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  late TextEditingController _controller;
  late TextEditingController _sourceController;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentUrl);
    _sourceController = TextEditingController(text: widget.sourceUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF141514),
      appBar: AppBar(
          backgroundColor: const Color(0xFF3C3D37),
          title: Text(
            "Configuration",
            style: TextStyle(color: Colors.white),
          )),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                  labelText: "Edit Server IP",
                  labelStyle: TextStyle(color: Colors.grey)),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _sourceController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                  labelText: "Edit Source IP",
                  labelStyle: TextStyle(color: Colors.grey)),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3C3D37)),
              onPressed: () {
                Navigator.pop(
                  context,
                  {
                    'currentUrl': _controller.text,
                    'sourceUrl': _sourceController.text,
                  },
                );
              },
              child: Text(
                "Save",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
