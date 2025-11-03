import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileApplicationSettingScreen extends StatefulWidget {
  const ProfileApplicationSettingScreen({super.key});

  @override
  State<ProfileApplicationSettingScreen> createState() => _ProfileApplicationSettingScreenState();
}

class _ProfileApplicationSettingScreenState extends State<ProfileApplicationSettingScreen> {
  File? _logoFile;
  File? _signatureFile;
  final picker = ImagePicker();

  final TextEditingController _invoicePrefixController = TextEditingController();
  final TextEditingController _challanFormatController = TextEditingController();
  final TextEditingController _challanSequenceController = TextEditingController(text: "1");
  final TextEditingController _termsController = TextEditingController();

  Future<void> _pickImage(bool isLogo) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isLogo) {
          _logoFile = File(pickedFile.path);
        } else {
          _signatureFile = File(pickedFile.path);
        }
      });
    }
  }

  void _resetSequence() {
    setState(() {
      _challanSequenceController.text = "1";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Application Settings"),
        titleTextStyle: TextStyle(
          color: Color.fromRGBO(0, 140, 192, 1),
        ),
        // backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Logo Section ---
            const Text("App Logo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Center(
              child: GestureDetector(
                onTap: () => _pickImage(true),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _logoFile != null ? FileImage(_logoFile!) : null,
                  child: _logoFile == null
                      ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Invoice Prefix ---
            TextField(
              controller: _invoicePrefixController,
              decoration: const InputDecoration(
                labelText: "Invoice Prefix",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // --- Challan Number Format ---
            TextField(
              controller: _challanFormatController,
              decoration: const InputDecoration(
                labelText: "Challan Number Format",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // --- Challan Sequence ---
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _challanSequenceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Challan Sequence (Next No.)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _resetSequence,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Reset"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Terms and Conditions ---
            const Text("Terms & Conditions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _termsController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "Enter terms and conditions here...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // --- Signature Upload ---
            const Text("Upload Signature", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Center(
              child: GestureDetector(
                onTap: () => _pickImage(false),
                child: Container(
                  height: 120,
                  width: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    image: _signatureFile != null
                        ? DecorationImage(
                            image: FileImage(_signatureFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _signatureFile == null
                      ? const Center(child: Icon(Icons.upload_file, size: 40, color: Colors.grey))
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // --- Save Button ---
            Center(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Settings Saved Successfully")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromRGBO(0, 140, 192, 1),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Save Settings", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
