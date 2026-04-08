import 'package:flutter/material.dart';
import '../services/api_service.dart';

class IstifadecilerScreen extends StatefulWidget {
  const IstifadecilerScreen({super.key});

  @override
  State<IstifadecilerScreen> createState() => _IstifadecilerScreenState();
}

class _IstifadecilerScreenState extends State<IstifadecilerScreen> {
  List istifadeciler = [];

  @override
  void initState() {
    super.initState();
    loadIstifadeciler();
  }

  void loadIstifadeciler() async {
    final data = await getIstifadeciler();
    setState(() => istifadeciler = data);
  }

  void showAddDialog() {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRol = "user";

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Yeni İstifadəçi"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: "İstifadəçi adı"),
              ),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Şifrə"),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text("Rol: "),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: selectedRol,
                    items: const [
                      DropdownMenuItem(value: "user", child: Text("İstifadəçi")),
                      DropdownMenuItem(value: "admin", child: Text("Admin")),
                    ],
                    onChanged: (val) {
                      setStateDialog(() => selectedRol = val!);
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Ləğv et"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (usernameController.text.isEmpty ||
                    passwordController.text.isEmpty) return;
                await addIstifadeci(
                  usernameController.text,
                  passwordController.text,
                  selectedRol,
                );
                Navigator.pop(context);
                loadIstifadeciler();
              },
              child: const Text("Əlavə et"),
            ),
          ],
        ),
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
              await deleteIstifadeci(id);
              Navigator.pop(context);
              loadIstifadeciler();
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B3A6B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "İstifadəçilər",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF1B3A6B)),
            onPressed: showAddDialog,
          ),
        ],
      ),
      body: istifadeciler.isEmpty
          ? const Center(child: Text("İstifadəçi tapılmadı"))
          : ListView.separated(
              itemCount: istifadeciler.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 16),
              itemBuilder: (_, i) {
                final u = istifadeciler[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF1B3A6B),
                    child: Text(
                      u["username"].toString()[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(u["username"]),
                  subtitle: Text(
                    u["rol"] == "admin" ? "Administrator" : "İstifadəçi",
                    style: TextStyle(
                      color: u["rol"] == "admin"
                          ? const Color(0xFF1B3A6B)
                          : Colors.grey,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => confirmDelete(u["id"]),
                  ),
                );
              },
            ),
    );
  }
}