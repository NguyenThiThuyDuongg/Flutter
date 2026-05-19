import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'add_contact_screen.dart';

class ContactsListScreen extends StatefulWidget {
  const ContactsListScreen({super.key});

  @override
  State<ContactsListScreen> createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends State<ContactsListScreen> {
  List<Contact> _contacts = [];

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  Future<void> loadContacts() async {
    bool permission = await FlutterContacts.requestPermission();

    if (permission) {
      List<Contact> contacts =
          await FlutterContacts.getContacts(
        withProperties: true,
      );

      setState(() {
        _contacts = contacts;
      });
    }
  }

  void goToAddContact() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddContactScreen(),
      ),
    );

    loadContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Danh bạ điện thoại"),
        backgroundColor: Colors.blue,
      ),
      body: _contacts.isEmpty
          ? const Center(
              child: Text(
                "Không có liên hệ",
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                Contact contact = _contacts[index];

                String phone = "";

                if (contact.phones.isNotEmpty) {
                  phone = contact.phones.first.number;
                }

                String email = "";

                if (contact.emails.isNotEmpty) {
                  email = contact.emails.first.address;
                }

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        contact.displayName.isNotEmpty
                            ? contact.displayName[0]
                            : "?",
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    title: Text(
                      contact.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(phone),
                        Text(email),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: goToAddContact,
        child: const Icon(Icons.add),
      ),
    );
  }
}