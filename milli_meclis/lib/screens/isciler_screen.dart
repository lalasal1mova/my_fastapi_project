import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';
import 'isci_detail_screen.dart';
import 'kayd_edilenler_screen.dart';
import 'vezifeler_screen.dart';
import 'hesab_screen.dart';

class IscilerScreen extends StatefulWidget {
  final int vezifeId;
  final String vezifeName;

  const IscilerScreen({
    super.key,
    required this.vezifeId,
    required this.vezifeName,
  });

  @override
  State<IscilerScreen> createState() => _IscilerScreenState();
}

class _IscilerScreenState extends State<IscilerScreen> {
  List isciler = [];
  List filtered = [];
  List savedIds = [];
  String rol = "user";
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadIsciler();
    loadSavedIds();
    loadRol();
  }

  void loadRol() async {
    final r = await getRol();
    setState(() => rol = r ?? "user");
  }

  void loadIsciler() async {
    final data = await getIsciler(widget.vezifeId);
    setState(() {
      isciler = data;
      filtered = data;
    });
  }

  void loadSavedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString("saved_isciler");
    if (data != null) {
      final list = jsonDecode(data) as List;
      setState(() => savedIds = list.map((i) => i["id"]).toList());
    }
  }

  void toggleSave(Map isci) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString("saved_isciler");
    List saved = data != null ? jsonDecode(data) : [];

    if (savedIds.contains(isci["id"])) {
      saved.removeWhere((i) => i["id"] == isci["id"]);
      savedIds.remove(isci["id"]);
    } else {
      saved.add(isci);
      savedIds.add(isci["id"]);
    }

    await prefs.setString("saved_isciler", jsonEncode(saved));
    setState(() {});
  }

  void onSearch(String query) {
    setState(() {
      filtered = isciler.where((i) {
        final fullName = "${i["ad"]} ${i["soyad"]}".toLowerCase();
        return fullName.contains(query.toLowerCase());
      }).toList();
    });
  }

  void showAddIsciDialog() {
    final adController = TextEditingController();
    final soyadController = TextEditingController();
    final telefon1Controller = TextEditingController();
    final telefon2Controller = TextEditingController();
    final seher1Controller = TextEditingController();
    final seher2Controller = TextEditingController();
    final daxiliController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Yeni İşçi"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: adController, decoration: const InputDecoration(labelText: "Ad")),
              TextField(controller: soyadController, decoration: const InputDecoration(labelText: "Soyad")),
              TextField(controller: telefon1Controller, decoration: const InputDecoration(labelText: "Telefon nömrəsi 1")),
              TextField(controller: telefon2Controller, decoration: const InputDecoration(labelText: "Telefon nömrəsi 2")),
              TextField(controller: seher1Controller, decoration: const InputDecoration(labelText: "Şəhər nömrəsi 1")),
              TextField(controller: seher2Controller, decoration: const InputDecoration(labelText: "Şəhər nömrəsi 2")),
              TextField(controller: daxiliController, decoration: const InputDecoration(labelText: "Daxili nömrə")),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Ləğv et"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (adController.text.isEmpty || soyadController.text.isEmpty) return;
              await addIsci({
                "ad": adController.text,
                "soyad": soyadController.text,
                "vezife_id": widget.vezifeId,
                "telefon_nomresi1": telefon1Controller.text,
                "telefon_nomresi2": telefon2Controller.text,
                "seher_nomresi1": seher1Controller.text,
                "seher_nomresi2": seher2Controller.text,
                "daxili_nomre": daxiliController.text,
              });
              Navigator.pop(context);
              loadIsciler();
            },
            child: const Text("Əlavə et"),
          ),
        ],
      ),
    );
  }

  void confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Silmək istəyirsiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Xeyr"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await deleteIsci(id);
              Navigator.pop(context);
              loadIsciler();
            },
            child: const Text("Bəli", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Map<String, List> groupByLetter(List list) {
    Map<String, List> grouped = {};
    for (var item in list) {
      final letter = item["ad"].toString()[0].toUpperCase();
      grouped.putIfAbsent(letter, () => []);
      grouped[letter]!.add(item);
    }
    return Map.fromEntries(
        grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupByLetter(filtered);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B3A6B)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (rol == "admin")
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF1B3A6B)),
              onPressed: showAddIsciDialog,
            ),
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Color(0xFF1B3A6B)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const KaydEdilenlerScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Color(0xFF1B3A6B)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HesabScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: searchController,
              onChanged: onSearch,
              decoration: InputDecoration(
                hintText: "Axtar",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text("İşçi tapılmadı"))
                : ListView.builder(
                    itemCount: grouped.keys.length,
                    itemBuilder: (_, i) {
                      final letter = grouped.keys.elementAt(i);
                      final list = grouped[letter]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Text(
                              letter,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B3A6B),
                              ),
                            ),
                          ),
                          ...list.map((isci) => Column(
                                children: [
                                  ListTile(
                                    title: Text(
                                      "${isci["ad"]} ${isci["soyad"]}",
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (rol == "admin")
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red, size: 20),
                                            onPressed: () =>
                                                confirmDelete(isci["id"]),
                                          ),
                                        IconButton(
                                          icon: Icon(
                                            savedIds.contains(isci["id"])
                                                ? Icons.bookmark
                                                : Icons.bookmark_border,
                                            color: const Color(0xFF1B3A6B),
                                          ),
                                          onPressed: () => toggleSave(isci),
                                        ),
                                      ],
                                    ),
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => IsciDetailScreen(
                                            isciId: isci["id"],
                                            isciName:
                                                "${isci["ad"]} ${isci["soyad"]}",
                                            isSaved:
                                                savedIds.contains(isci["id"]),
                                            onSaveToggle: () =>
                                                toggleSave(isci),
                                          ),
                                        ),
                                      );
                                      loadSavedIds();
                                    },
                                  ),
                                  const Divider(height: 1, indent: 16),
                                ],
                              )),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}