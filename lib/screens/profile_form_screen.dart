// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'profile_screen.dart'; // Import after creating ProfileScreen
// import '../services/profile_api.dart'; // Assume you have this for API calls

// class ProfileFormScreen extends StatefulWidget {
//   const ProfileFormScreen({super.key});

//   @override
//   State<ProfileFormScreen> createState() => _ProfileFormScreenState();
// }

// class _ProfileFormScreenState extends State<ProfileFormScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _companyController = TextEditingController();
//   bool _isLoading = false;
//   final ProfileApi _profileApi = ProfileApi(); // Assume this handles create API

//  Future<void> _submitProfile() async {
//   if (!_formKey.currentState!.validate()) return;

//   setState(() {
//     _isLoading = true;
//   });

//   try {
//     // Token line hata diya - ApiUtils handle karega
//     final response = await _profileApi.createProfile(
//       _nameController.text,  // name
//       _emailController.text, // email
//       _phoneController.text, // phone
//       _addressController.text, // address
//       _companyController.text, // company
//     );

//     if (response.success && mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Profile created successfully!'),
//           backgroundColor: Colors.green,
//         ),
//       );
//       // Navigate to ProfileScreen
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const ProfileScreen()),
//       );
//     } else if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(response.message ?? 'Failed to create profile'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   } catch (e) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   } finally {
//     if (mounted) {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
// }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _addressController.dispose();
//     _companyController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isMobile = screenWidth < 600;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: const Color.fromRGBO(0, 140, 192, 1),
//         elevation: 0,
//         title: Text(
//           'Create Profile',
//           style: GoogleFonts.inter(
//             fontSize: isMobile ? 16 : 18,
//             fontWeight: FontWeight.w600,
//             color: Colors.white,
//           ),
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Padding(
//         padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
//         child: Form(
//           key: _formKey,
//           child: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Complete your profile to get started',
//                   style: GoogleFonts.inter(
//                     fontSize: isMobile ? 16 : 18,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 _buildTextField('Full Name', _nameController, Icons.person, true),
//                 const SizedBox(height: 16),
//                 _buildTextField('Email', _emailController, Icons.email, true),
//                 const SizedBox(height: 16),
//                 _buildTextField('Phone', _phoneController, Icons.phone, false),
//                 const SizedBox(height: 16),
//                 _buildTextField('Address', _addressController, Icons.location_on, false, maxLines: 3),
//                 const SizedBox(height: 16),
//                 _buildTextField('Company Name', _companyController, Icons.business, false),
//                 const SizedBox(height: 32),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: _isLoading ? null : _submitProfile,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color.fromRGBO(0, 140, 192, 1),
//                       padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: _isLoading
//                         ? const SizedBox(
//                             width: 20,
//                             height: 20,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                             ),
//                           )
//                         : Text(
//                             'Create Profile',
//                             style: GoogleFonts.inter(
//                               fontSize: isMobile ? 16 : 18,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.white,
//                             ),
//                           ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField(
//     String label,
//     TextEditingController controller,
//     IconData icon,
//     bool isRequired, {
//     int maxLines = 1,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(icon, color: const Color.fromRGBO(0, 140, 192, 1), size: 20),
//             const SizedBox(width: 8),
//             Text(
//               label,
//               style: GoogleFonts.inter(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.black87,
//               ),
//             ),
//             if (isRequired) ...[
//               const SizedBox(width: 4),
//               Text(
//                 '*',
//                 style: GoogleFonts.inter(color: Colors.red, fontSize: 14),
//               ),
//             ],
//           ],
//         ),
//         const SizedBox(height: 8),
//         TextFormField(
//           controller: controller,
//           maxLines: maxLines,
//           decoration: InputDecoration(
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: const BorderSide(color: Color.fromRGBO(0, 140, 192, 1)),
//             ),
//             contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//             fillColor: Colors.grey.shade50,
//             filled: true,
//           ),
//           validator: (value) {
//             if (isRequired && (value == null || value.isEmpty)) {
//               return 'Please enter $label';
//             }
//             if (label == 'Email' && value != null && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
//               return 'Please enter a valid email';
//             }
//             if (label == 'Phone' && value != null && !RegExp(r'^\d{10}$').hasMatch(value)) {
//               return 'Please enter a valid 10-digit phone';
//             }
//             return null;
//           },
//         ),
//       ],
//     );
//   }
// }