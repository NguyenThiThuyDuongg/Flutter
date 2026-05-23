import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() =>
      _AddContactScreenState();
}

class _AddContactScreenState
    extends State<AddContactScreen> {
  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  Future<void> saveContact() async {
    bool permission =
        await FlutterContacts.requestPermission();

    if (!permission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Chưa cấp quyền danh bạ"),
        ),
      );
      return;
    }

    final newContact = Contact(
      name: Name(
        first: _nameController.text,
      ),
      phones: [
        Phone(_phoneController.text),
      ],
      emails: [
        Email(_emailController.text),
      ],
    );

    await FlutterContacts.insertContact(newContact);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Thêm liên hệ thành công"),
        ),
      );

      Navigator.pop(context);
    }
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
          labelText: label,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thêm liên hệ"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildTextField(
              controller: _nameController,
              label: "Họ tên",
              icon: Icons.person,
            ),
            buildTextField(
              controller: _phoneController,
              label: "Số điện thoại",
              icon: Icons.phone,
            ),
            buildTextField(
              controller: _emailController,
              label: "Email",
              icon: Icons.email,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: saveContact,
                child: const Text(
                  "Lưu liên hệ",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}