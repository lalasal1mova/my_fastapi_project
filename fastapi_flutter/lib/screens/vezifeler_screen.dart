import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'isciler_screen.dart';
import 'hesab_screen.dart';
import 'kayd_edilenler_screen.dart';

class VezifelerScreen extends StatefulWidget {
  const VezifelerScreen({super.key});

  @override
  State<VezifelerScreen> createState() => _VezifelerScreenState();
}

class _VezifelerScreenState extends State<VezifelerScreen> {
  List vezifeler = [];
  List filtered = [];
  String rol = "user";
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadVezifeler();
    loadRol();
  }

  void loadRol() async {
    final r = await getRol();
    setState(() => rol = r ?? "user");
  }

  void loadVezifeler() async {
    final data = await getVezifeler();
    setState(() {
      vezifeler = data;
      filtered = data;
    });
  }

  void onSearch(String query) {
    setState(() {
      filtered = vezifeler
          .where((v) =>
              v["ad"].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void showAddVezifeDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Yeni Vəzifə"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Vəzifə adı"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Ləğv et"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              await addVezife(controller.text);
              Navigator.pop(context);
              loadVezifeler();
            },
            child: const Text("Əlavə et"),
          ),
        ],
      ),
    );
  }

  void showUpdateVezifeDialog(int id, String oldAd) {
    final controller = TextEditingController(text: oldAd);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Vəzifəni yenilə"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Vəzifə adı"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Ləğv et"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              await updateVezife(id, controller.text);
              Navigator.pop(context);
              loadVezifeler();
            },
            child: const Text("Yenilə"),
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
              await deleteVezife(id);
              Navigator.pop(context);
              loadVezifeler();
            },
            child: const Text("Bəli", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/logo2.png'),
          ),
        ),
        actions: [
          if (rol == "admin")
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF1B3A6B)),
              onPressed: showAddVezifeDialog,
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
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 16),
              itemBuilder: (_, i) {
                final v = filtered[i];
                return ListTile(
                  title: Text(
                    v["ad"],
                    style: const TextStyle(fontSize: 15),
                  ),
                  trailing: rol == "admin"
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Color(0xFF1B3A6B), size: 20),
                              onPressed: () =>
                                  showUpdateVezifeDialog(v["id"], v["ad"]),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red, size: 20),
                              onPressed: () => confirmDelete(v["id"]),
                            ),
                          ],
                        )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => IscilerScreen(
                          vezifeId: v["id"],
                          vezifeName: v["ad"],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}