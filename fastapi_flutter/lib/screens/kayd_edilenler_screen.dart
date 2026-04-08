import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'isci_detail_screen.dart';

class KaydEdilenlerScreen extends StatefulWidget {
  const KaydEdilenlerScreen({super.key});

  @override
  State<KaydEdilenlerScreen> createState() => _KaydEdilenlerScreenState();
}

class _KaydEdilenlerScreenState extends State<KaydEdilenlerScreen> {
  List savedIsciler = [];

  @override
  void initState() {
    super.initState();
    loadSaved();
  }

  void loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString("saved_isciler");
    if (data != null) {
      setState(() => savedIsciler = jsonDecode(data));
    }
  }

  void toggleSave(Map isci) async {
    final prefs = await SharedPreferences.getInstance();
    savedIsciler.removeWhere((i) => i["id"] == isci["id"]);
    await prefs.setString("saved_isciler", jsonEncode(savedIsciler));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B3A6B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Saxlanılanlar",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [],
      ),
      body: savedIsciler.isEmpty
          ? const Center(
              child: Text(
                "Heç bir işçi saxlanılmayıb",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.separated(
              itemCount: savedIsciler.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 16),
              itemBuilder: (_, i) {
                final isci = savedIsciler[i];
                return ListTile(
                  title: Text("${isci["ad"]} ${isci["soyad"]}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.bookmark, color: Color(0xFF1B3A6B)),
                    onPressed: () => toggleSave(isci),
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => IsciDetailScreen(
                          isciId: isci["id"],
                          isciName: "${isci["ad"]} ${isci["soyad"]}",
                          isSaved: true,
                          onSaveToggle: () => toggleSave(isci),
                        ),
                      ),
                    );
                    loadSaved();
                  },
                );
              },
            ),
    );
  }
}