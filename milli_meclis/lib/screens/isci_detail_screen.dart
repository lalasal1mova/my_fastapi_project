import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'vezifeler_screen.dart';

class IsciDetailScreen extends StatefulWidget {
  final int isciId;
  final String isciName;
  final bool isSaved;
  final VoidCallback onSaveToggle;

  const IsciDetailScreen({
    super.key,
    required this.isciId,
    required this.isciName,
    required this.isSaved,
    required this.onSaveToggle,
  });

  @override
  State<IsciDetailScreen> createState() => _IsciDetailScreenState();
}

class _IsciDetailScreenState extends State<IsciDetailScreen> {
  Map? isci;
  late bool isSaved;
  String rol = "user";

  @override
  void initState() {
    super.initState();
    isSaved = widget.isSaved;
    loadIsci();
    loadRol();
  }

  void loadRol() async {
    final r = await getRol();
    setState(() => rol = r ?? "user");
  }

  void loadIsci() async {
    final data = await getIsci(widget.isciId);
    setState(() => isci = data);
  }

  void toggleSave() {
    widget.onSaveToggle();
    setState(() => isSaved = !isSaved);
  }

  void showUpdateDialog() {
    final adController = TextEditingController(text: isci!["ad"]);
    final soyadController = TextEditingController(text: isci!["soyad"]);
    final telefon1Controller = TextEditingController(text: isci!["telefon_nomresi1"] ?? "");
    final telefon2Controller = TextEditingController(text: isci!["telefon_nomresi2"] ?? "");
    final seher1Controller = TextEditingController(text: isci!["seher_nomresi1"] ?? "");
    final seher2Controller = TextEditingController(text: isci!["seher_nomresi2"] ?? "");
    final daxiliController = TextEditingController(text: isci!["daxili_nomre"] ?? "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("İşçini yenilə"),
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
              await updateIsci(widget.isciId, {
                "ad": adController.text,
                "soyad": soyadController.text,
                "vezife_id": isci!["vezife_id"],
                "telefon_nomresi1": telefon1Controller.text,
                "telefon_nomresi2": telefon2Controller.text,
                "seher_nomresi1": seher1Controller.text,
                "seher_nomresi2": seher2Controller.text,
                "daxili_nomre": daxiliController.text,
              });
              Navigator.pop(context);
              loadIsci();
            },
            child: const Text("Yenilə"),
          ),
        ],
      ),
    );
  }

  Widget infoCard(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF1B3A6B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value ?? "—",
            style: const TextStyle(fontSize: 16),
          ),
          const Divider(),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B3A6B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isciName,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (rol == "admin")
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF1B3A6B)),
              onPressed: showUpdateDialog,
            ),
          IconButton(
            icon: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: const Color(0xFF1B3A6B),
            ),
            onPressed: toggleSave,
          ),
        ],
      ),
      body: isci == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 8),
                infoCard("Vəzifə", isci!["vezife_adi"]),
                infoCard("Şəhər nömrəsi 1", isci!["seher_nomresi1"]),
                infoCard("Şəhər nömrəsi 2", isci!["seher_nomresi2"]),
                infoCard("Telefon nömrəsi 1", isci!["telefon_nomresi1"]),
                infoCard("Telefon nömrəsi 2", isci!["telefon_nomresi2"]),
                infoCard("Daxili nömrə", isci!["daxili_nomre"]),
              ],
            ),
    );
  }
}