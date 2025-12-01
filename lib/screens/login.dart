import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'cadastrar.dart';
import 'home.dart';
import '../services/localStorage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  bool carregando = false;
  final LocalStorageService localStorage = LocalStorageService();

  @override
  void initState() {
    super.initState();
    _checkExistingLogin();
  }

  Future<void> _checkExistingLogin() async {
    final isLoggedIn = await localStorage.isUserLoggedIn();
    if (isLoggedIn) {
      final userId = await localStorage.getUserId();
      final userEmail = await localStorage.getUserEmail();
      print('USUÁRIO JÁ LOGADO - ID: $userId, Email: $userEmail');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  Future<void> _login() async {
    setState(() {
      carregando = true;
    });

    final email = emailController.text.trim();
    final senha = senhaController.text.trim();

    if (email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos!")),
      );
      setState(() => carregando = false);
      return;
    }

    try {
      final url = Uri.parse("https://backend-tcc-iota.vercel.app/login");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "senha": senha, "validade": 2000}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('RESPOSTA DO LOGIN: $data');

        if (data["token"] != null) {
          final String token = data["token"];

          final String? userId = data["id_user"]?.toString();

          if (userId != null && userId.isNotEmpty) {
            await localStorage.saveUserData(userId, token, email, "Usuário");

            print('✅ ID_USER SALVO: $userId');
            print('✅ TOKEN SALVO: $token');
            print('✅ EMAIL SALVO: $email');

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Login realizado com sucesso!")),
            );

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          } else {
            print('❌ id_user não veio na resposta do login');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Erro: ID do usuário não retornado"),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["message"] ?? "Credenciais inválidas")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ${response.statusCode}: ${response.body}"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro de conexão: $e")));
    }

    setState(() {
      carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Image(image: AssetImage("assets/logo.jpeg")),
            const SizedBox(height: 20),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Ex: seu.nome@email',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: senhaController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Senha',
                hintText: 'Ex: senha123',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: carregando ? null : _login,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.blue,
              ),
              child:
                  carregando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Entrar"),
            ),

            const SizedBox(height: 16),
            const Text('Não tenho uma conta'),
            const SizedBox(height: 8),

            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CadastroPage()),
                );
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: Colors.blue),
              ),
              child: const Text(
                "Cadastrar",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
