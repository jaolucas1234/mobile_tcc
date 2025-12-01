import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  String sexo = 'F';
  String dia = '1';
  String mes = 'Janeiro';
  String ano = '2005';

  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();

  bool carregando = false;

  Future<void> _cadastrar() async {
    final nome = nomeController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final senha = senhaController.text.trim();

    String sexoFormatado;
    if (sexo == 'F') {
      sexoFormatado = 'FEMININO';
    } else {
      sexoFormatado = 'MASCULINO';
    }

    String nascimentoIso =
        '${ano.padLeft(4, '0')}-${_mesNumero(mes).padLeft(2, '0')}-${dia.padLeft(2, '0')}T00:00:00.000Z';

    if (nome.isEmpty || email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos obrigatórios!")),
      );
      return;
    }

    setState(() => carregando = true);

    try {
      final url = Uri.parse("https://backend-tcc-iota.vercel.app/user");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nome": nome,
          "email": email,
          "senha": senha,
          "genero": sexoFormatado,
          "nascimento": nascimentoIso,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cadastro realizado com sucesso!")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Erro no cadastro.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro: $e")));
    } finally {
      setState(() => carregando = false);
    }
  }

  String _mesNumero(String mes) {
    switch (mes) {
      case 'Janeiro':
        return '01';
      case 'Fevereiro':
        return '02';
      case 'Março':
        return '03';
      case 'Abril':
        return '04';
      case 'Maio':
        return '05';
      case 'Junho':
        return '06';
      case 'Julho':
        return '07';
      case 'Agosto':
        return '08';
      case 'Setembro':
        return '09';
      case 'Outubro':
        return '10';
      case 'Novembro':
        return '11';
      case 'Dezembro':
        return '12';
      default:
        return '01';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cadastro"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 350,
          decoration: BoxDecoration(
            color: Colors.blue[400],
            borderRadius: BorderRadius.circular(10),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'CADASTRE-SE ABAIXO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person),
                    hintText: 'Nome completo',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.email),
                    hintText: 'E-mail',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: senhaController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.lock),
                    hintText: 'Senha',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Data de nascimento:',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DropdownButton<String>(
                      value: dia,
                      items: List.generate(31, (index) {
                        return DropdownMenuItem(
                          value: '${index + 1}',
                          child: Text('${index + 1}'),
                        );
                      }),
                      onChanged: (value) => setState(() => dia = value!),
                    ),
                    DropdownButton<String>(
                      value: mes,
                      items:
                          [
                                'Janeiro',
                                'Fevereiro',
                                'Março',
                                'Abril',
                                'Maio',
                                'Junho',
                                'Julho',
                                'Agosto',
                                'Setembro',
                                'Outubro',
                                'Novembro',
                                'Dezembro',
                              ]
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                      onChanged: (value) => setState(() => mes = value!),
                    ),
                    DropdownButton<String>(
                      value: ano,
                      items: List.generate(100, (index) {
                        int year = 2023 - index;
                        return DropdownMenuItem(
                          value: '$year',
                          child: Text('$year'),
                        );
                      }),
                      onChanged: (value) => setState(() => ano = value!),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Text('Sexo:', style: TextStyle(color: Colors.white)),
                Row(
                  children: [
                    Radio<String>(
                      value: 'F',
                      groupValue: sexo,
                      onChanged: (value) => setState(() => sexo = value!),
                    ),
                    const Text(
                      'Feminino',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 20),
                    Radio<String>(
                      value: 'M',
                      groupValue: sexo,
                      onChanged: (value) => setState(() => sexo = value!),
                    ),
                    const Text(
                      'Masculino',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                  ),
                  onPressed: carregando ? null : _cadastrar,
                  child:
                      carregando
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('CADASTRAR-SE'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
