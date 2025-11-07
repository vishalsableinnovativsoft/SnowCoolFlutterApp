import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:snow_trading_cool/widgets/custom_toast.dart';

class ProfileApplicationSettingScreen extends StatefulWidget {
  const ProfileApplicationSettingScreen({super.key});

  @override
  State<ProfileApplicationSettingScreen> createState() =>
      _ProfileApplicationSettingScreenState();
}

class _ProfileApplicationSettingScreenState
    extends State<ProfileApplicationSettingScreen> {
  File? _logoFile;
  File? _signatureFile;
  final picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _invoicePrefixController =
      TextEditingController();
  final TextEditingController _challanFormatController =
      TextEditingController();
  final TextEditingController _challanSequenceController =
      TextEditingController(text: "1");
  final TextEditingController _termsController = TextEditingController();

  int _termsCharCount = 0;
  static const int _termsMaxLength = 100;

  Future<void> _pickImage(bool isLogo) async {
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  if (pickedFile != null) {
    final extension = pickedFile.path.split('.').last.toLowerCase();
    if (extension == 'png' || extension == 'jpg' || extension == 'jpeg') {
      setState(() {
        if (isLogo) {
          _logoFile = File(pickedFile.path);
        } else {
          _signatureFile = File(pickedFile.path);
        }
      });
    } else {
      showErrorToast(context, "Only .png or .jpg images are allowed");
    }
  }
}


  void _resetSequence() {
    setState(() {
      _challanSequenceController.text = "1";
    });
  }

  @override
  void dispose() {
    _invoicePrefixController.dispose();
    _challanFormatController.dispose();
    _challanSequenceController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Application Settings"),
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color.fromRGBO(0, 140, 192, 1),
        ),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // --- Logo Section ---
              Text("Logo",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              Center(
                child: GestureDetector(
                  onTap: () => _pickImage(true),
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _logoFile != null
                        ? FileImage(_logoFile!)
                        : null,
                    child: _logoFile == null
                        ? const Icon(Icons.add_a_photo,
                            size: 40, color: Colors.grey)
                        : null,
                  ),
                ),
              ),
              if (_logoFile == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.0),
                  child: Text(
                      "Please select a PNG/JPG image.",
                      style: TextStyle(fontSize: 12, color: Colors.red)),
                ),
              const SizedBox(height: 18),

              // --- Invoice Prefix Field ---
              Text("Invoice Prefix", style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600)),
              TextFormField(
                controller: _invoicePrefixController,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  hintText: "e.g., INV-",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Invoice prefix cannot be empty";
                  }
                  if (!RegExp(r"^[A-Za-z]+\-\s*$").hasMatch(val)) {
                    return "Prefix must be letters and end with '-'";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- Challan Number Format ---
              Text("Challan Number Formatter", style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600)),
              TextFormField(
                controller: _challanFormatController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  hintText: "e.g., 0001",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Challan format is required";
                  }
                  if (!RegExp(r"^[0-9]+$").hasMatch(val)) {
                    return "Format must be numeric";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- Challan Sequence Field ---
              Text("Challan Sequence", style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600)),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _challanSequenceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                        hintText: "e.g., 1",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return "Sequence is required";
                        }
                        if (int.tryParse(val) == null || int.parse(val) < 1) {
                          return "Must be a number >= 1";
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: _resetSequence,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color.fromRGBO(0, 140, 192, 1), width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "Reset",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color.fromRGBO(0, 140, 192, 1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- Terms and Conditions ---
              Text("Terms & Conditions", style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600)),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  TextFormField(
                    controller: _termsController,
                    maxLines: 3,
                    maxLength: _termsMaxLength,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      hintText: "Enter terms & conditions...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      counterText: '',
                    ),
                    onChanged: (val) {
                      setState(() => _termsCharCount = val.length);
                    },
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return "Terms cannot be empty";
                      }
                      if (val.length > _termsMaxLength) {
                        return "Terms cannot exceed $_termsMaxLength characters";
                      }
                      return null;
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "${_termsMaxLength - _termsCharCount} characters left",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- Signature Upload ---
              Text("Upload Signature", style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600)),
              GestureDetector(
                onTap: () => _pickImage(false),
                child: Container(
                  height: 100,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1.3,
                    ),
                    image: _signatureFile != null
                        ? DecorationImage(
                            image: FileImage(_signatureFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _signatureFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.upload_file_rounded,
                                size: 36, color: Colors.blueGrey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              "Tap to upload signature (PNG/JPG)",
                              style: TextStyle(
                                  color: Colors.blueGrey.shade600, fontSize: 14),
                            ),
                          ],
                        )
                      : const Align(
                          alignment: Alignment.topRight,
                          child: Icon(Icons.edit, color: Colors.black54, size: 22),
                        ),
                ),
              ),
              if (_signatureFile == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.0),
                  child: Text(
                      "Please select a PNG/JPG image.",
                      style: TextStyle(fontSize: 12, color: Colors.red)),
                ),
              const SizedBox(height: 26),

              // --- Save Button ---
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate() &&
                        _logoFile != null &&
                        _signatureFile != null) {
                          showSuccessToast(context, "Settings Saved Successfully");
                      // Save logic here
                    } else {
                      showErrorToast(context, "Fill all fields and images");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(0, 140, 192, 1),
                    padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Save",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
