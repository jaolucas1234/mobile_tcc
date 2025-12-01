import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home.dart';
import '../services/localStorage.dart';
import 'exercicios.dart';
import 'treino.dart';
import 'parte_mental.dart';

class ParteFisica extends StatefulWidget {
  const ParteFisica({super.key});

  @override
  State<ParteFisica> createState() => _ParteFisicaState();
}

class _ParteFisicaState extends State<ParteFisica> {
  List<dynamic> treinos = [];
  bool isLoading = true;
  String errorMessage = '';
  final LocalStorageService localStorage = LocalStorageService();
  final TextEditingController _nomeTreinoController = TextEditingController();
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndTreinos();
  }

  @override
  void dispose() {
    _nomeTreinoController.dispose();
    super.dispose();
  }

  Future<void> _loadUserIdAndTreinos() async {
    final id = await localStorage.getUserId();
    setState(() {
      userId = id;
    });
    _carregarTreinos();
  }

  Future<void> _carregarTreinos() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      print('USER ID ATUAL: $userId');

      if (userId == null) {
        throw Exception('Usuário não identificado. Faça login novamente.');
      }

      final response = await http.get(
        Uri.parse('https://backend-tcc-iota.vercel.app/treino'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> todosOsTreinos = json.decode(response.body);
        print('TODOS OS TREINOS DA API: $todosOsTreinos');

        final treinosDoUsuario =
            todosOsTreinos.where((treino) {
              final treinoUserId =
                  treino['id_user']?.toString() ??
                  treino['userId']?.toString() ??
                  treino['user_id']?.toString();

              print(
                'Treino: ${treino['nome']} - UserID do treino: $treinoUserId - Meu ID: $userId',
              );

              return treinoUserId == userId;
            }).toList();

        print('✅ TREINOS DO USUÁRIO: ${treinosDoUsuario.length}');
        print('✅ TREINOS FILTRADOS: $treinosDoUsuario');

        setState(() {
          treinos = treinosDoUsuario;
          isLoading = false;
        });
      } else {
        throw Exception('Erro ao carregar treinos: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Erro: $e';
      });
    }
  }

  Future<void> _apagarTreino(dynamic treino) async {
    final nomeTreino = treino['nome'] ?? 'Treino sem nome';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Apagar Treino'),
            content: Text(
              'Tem certeza que deseja apagar o treino "$nomeTreino"? Todos os exercícios vinculados serão removidos.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _confirmarApagarTreino(treino);
                },
                child: const Text(
                  'Apagar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _confirmarApagarTreino(dynamic treino) async {
    try {
      final idTreino = treino['id_treino'];
      final nomeTreino = treino['nome'] ?? 'Treino sem nome';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
              const SizedBox(width: 16),
              Text('Apagando treino "$nomeTreino"...'),
            ],
          ),
          duration: const Duration(seconds: 30),
          backgroundColor: const Color(0xFF5BA0E0),
        ),
      );

      final responseTreinosLink = await http.get(
        Uri.parse('https://backend-tcc-iota.vercel.app/treinolink'),
      );

      if (responseTreinosLink.statusCode == 200) {
        final todosTreinosLinks = json.decode(responseTreinosLink.body);

        final treinosLinksParaDeletar =
            todosTreinosLinks
                .where((link) => link['id_treino'] == idTreino)
                .toList();

        print(
          'Encontrados ${treinosLinksParaDeletar.length} links para deletar',
        );

        for (var link in treinosLinksParaDeletar) {
          try {
            final response = await http.delete(
              Uri.parse(
                'https://backend-tcc-iota.vercel.app/treinolink/${link['id_link']}',
              ),
            );

            if (response.statusCode == 200) {
              print('✅ TreinoLink ${link['id_link']} deletado com sucesso');
            } else {
              print(
                '❌ Erro ao deletar treinoLink ${link['id_link']}: ${response.statusCode}',
              );
            }
          } catch (e) {
            print('❌ Erro ao deletar treinoLink ${link['id_link']}: $e');
          }
        }

        final responseTreino = await http.delete(
          Uri.parse('https://backend-tcc-iota.vercel.app/treino/$idTreino'),
        );

        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (responseTreino.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Treino "$nomeTreino" apagado com sucesso!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          _carregarTreinos();
        } else {
          throw Exception(
            'Erro ao deletar treino: ${responseTreino.statusCode}',
          );
        }
      } else {
        throw Exception(
          'Erro ao buscar treinos links: ${responseTreinosLink.statusCode}',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      print('Erro ao apagar treino: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao apagar treino: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _abrirModalNovoTreino() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildModalNovoTreino(),
    );
  }

  Widget _buildModalNovoTreino() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Criar Novo Treino',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () {
                  _nomeTreinoController.clear();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _nomeTreinoController,
            decoration: InputDecoration(
              labelText: 'Nome do Treino',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF5BA0E0)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _nomeTreinoController.clear();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'CANCELAR',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _salvarNovoTreino();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5BA0E0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'SALVAR',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Future<void> _salvarNovoTreino() async {
    if (_nomeTreinoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, informe o nome do treino!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Erro: Usuário não identificado. Faça login novamente.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
              SizedBox(width: 16),
              Text('Criando treino...'),
            ],
          ),
          duration: Duration(seconds: 30),
          backgroundColor: Color(0xFF5BA0E0),
        ),
      );

      final Map<String, dynamic> dadosTreino = {
        'nome': _nomeTreinoController.text,
        'id_user': int.parse(userId!),
      };

      print('DADOS DO TREINO A SER CRIADO: $dadosTreino');

      final response = await http.post(
        Uri.parse('https://backend-tcc-iota.vercel.app/treino'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(dadosTreino),
      );

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Treino criado com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        _nomeTreinoController.clear();
        Navigator.pop(context);
        _carregarTreinos();
      } else {
        throw Exception(
          'Erro ao criar treino: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao criar treino: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _irParaExercicios() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Exercicios()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.brain),
              color: Colors.black,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ParteMental()),
                );
              },
            ),
            IconButton(
              icon: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF5BA0E0),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(Icons.home, color: Colors.white),
              ),
              iconSize: 50,
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
            ),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.dumbbell),
              color: Colors.black,
              onPressed: () {},
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5BA0E0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: Colors.white,
                      size: 35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'SEU RITMO NOSSA TECNOLOGIA',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.black54,
                      letterSpacing: 1,
                    ),
                  ),
                  if (userId != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'ID: $userId',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'MEUS TREINOS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.grey[600]),
                    onPressed: _carregarTreinos,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            Expanded(child: _buildConteudoTreinos()),

            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _abrirModalNovoTreino,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5BA0E0),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'CRIAR NOVO TREINO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _irParaExercicios,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFF5BA0E0)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sports_gymnastics,
                            color: Color(0xFF5BA0E0),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'EXERCÍCIOS',
                            style: TextStyle(
                              color: Color(0xFF5BA0E0),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConteudoTreinos() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5BA0E0)),
            ),
            SizedBox(height: 16),
            Text(
              'Carregando seus treinos...',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[300], size: 50),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _carregarTreinos,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5BA0E0),
              ),
              child: const Text(
                'Tentar Novamente',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    if (treinos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, color: Colors.grey[300], size: 60),
            const SizedBox(height: 16),
            const Text(
              'Nenhum treino encontrado',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              userId != null
                  ? 'Crie seu primeiro treino!'
                  : 'Usuário não identificado',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: RefreshIndicator(
        onRefresh: _carregarTreinos,
        child: ListView.builder(
          itemCount: treinos.length,
          itemBuilder: (context, index) {
            final treino = treinos[index];
            final nomeTreino = treino['nome'] ?? 'Treino sem nome';

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  nomeTreino,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _apagarTreino(treino),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _verTreino(treino);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5BA0E0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'VER TREINO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _verTreino(dynamic treino) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TelaTreino(treino: treino)),
    );
  }
}
