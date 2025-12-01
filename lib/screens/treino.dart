import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home.dart';
import 'exerselec.dart';
import 'parte_fisica.dart';

class TelaTreino extends StatefulWidget {
  final dynamic treino;

  const TelaTreino({super.key, required this.treino});

  @override
  State<TelaTreino> createState() => _TelaTreinoState();
}

class _TelaTreinoState extends State<TelaTreino> {
  List<dynamic> exerciciosDoTreino = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _carregarExerciciosDoTreino();
  }

  Future<void> _carregarExerciciosDoTreino() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final idTreino = widget.treino['id_treino'];
      print('Carregando exercícios do treino ID: $idTreino');

      final responseTreinosLink = await http.get(
        Uri.parse('https://backend-tcc-iota.vercel.app/treinolink'),
      );

      final responseExerSelec = await http.get(
        Uri.parse('https://backend-tcc-iota.vercel.app/exerselec'),
      );

      final responseExercicios = await http.get(
        Uri.parse('https://backend-tcc-iota.vercel.app/exercicio'),
      );

      if (responseTreinosLink.statusCode == 200 &&
          responseExerSelec.statusCode == 200 &&
          responseExercicios.statusCode == 200) {
        final todosTreinosLinks = json.decode(responseTreinosLink.body);
        final todosExerSelec = json.decode(responseExerSelec.body);
        final todosExercicios = json.decode(responseExercicios.body);

        final treinosLinksFiltrados =
            todosTreinosLinks.where((link) {
              return link['id_treino'] == idTreino;
            }).toList();

        print('Treinos links filtrados: ${treinosLinksFiltrados.length}');

        final List<dynamic> exercicios = [];

        for (var link in treinosLinksFiltrados) {
          final idExerSelec = link['id_ExerSelec'];

          final exerSelec = todosExerSelec.firstWhere(
            (es) => es['id_ExerSelec'] == idExerSelec,
            orElse: () => null,
          );

          if (exerSelec != null) {
            final idExercicio = exerSelec['id_exercicio'];

            final exercicio = todosExercicios.firstWhere(
              (ex) => ex['id_exercicio'] == idExercicio,
              orElse: () => null,
            );

            if (exercicio != null) {
              exercicios.add({
                ...exercicio,
                'series': exerSelec['series'],
                'repeticoes': exerSelec['repeticoes'],
                'peso': exerSelec['peso'],
                'id_ExerSelec': exerSelec['id_ExerSelec'],
                'id_link': link['id_link'],
              });
            }
          }
        }

        setState(() {
          exerciciosDoTreino = exercicios;
          isLoading = false;
        });

        print('Exercícios carregados: ${exercicios.length}');
      } else {
        throw Exception('Erro em uma das APIs');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Erro: $e';
      });
      print('Erro: $e');
    }
  }

  void _voltarParaHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ParteFisica()),
    );
  }

  void _editarExercicio(dynamic exercicio) {
    showDialog(
      context: context,
      builder:
          (context) => DialogEditarExercicio(
            exercicio: exercicio,
            onSalvar: (novasSeries, novasRepeticoes, novoPeso) {
              _atualizarExercicio(
                exercicio,
                novasSeries,
                novasRepeticoes,
                novoPeso,
              );
            },
          ),
    );
  }

  void _excluirExercicio(dynamic exercicio) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Excluir Exercício'),
            content: const Text(
              'Tem certeza que deseja excluir este exercício do treino?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmarExclusao(exercicio);
                },
                child: const Text(
                  'Excluir',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _atualizarExercicio(
    dynamic exercicio,
    int series,
    int repeticoes,
    double? peso,
  ) async {
    try {
      final response = await http.put(
        Uri.parse(
          'https://backend-tcc-iota.vercel.app/exerselec/${exercicio['id_ExerSelec']}',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'series': series,
          'repeticoes': repeticoes,
          'peso': peso,
        }),
      );

      if (response.statusCode == 200) {
        _carregarExerciciosDoTreino();
      } else {
        throw Exception('Erro ao atualizar exercício');
      }
    } catch (e) {
      print('Erro ao atualizar: $e');
    }
  }

  Future<void> _confirmarExclusao(dynamic exercicio) async {
    try {
      final response = await http.delete(
        Uri.parse(
          'https://backend-tcc-iota.vercel.app/treinolink/${exercicio['id_link']}',
        ),
      );

      if (response.statusCode == 200) {
        _carregarExerciciosDoTreino();
      } else {
        throw Exception('Erro ao excluir exercício');
      }
    } catch (e) {
      print('Erro ao excluir: $e');
    }
  }

  void _adicionarExercicio() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ExerciciosSelecao(
              treino: widget.treino,
              onExercicioAdicionado: _carregarExerciciosDoTreino,
            ),
      ),
    );
  }

  void _abrirModalExercicio(dynamic exercicio) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildModalExercicio(exercicio),
    );
  }

  Widget _buildModalExercicio(dynamic exercicio) {
    final nome = exercicio['nome'] ?? 'Exercício sem nome';
    final descricao = exercicio['descricao'] ?? 'Sem descrição disponível';
    final imagem = exercicio['img'] ?? exercicio['imagem'];
    final series = exercicio['series'];
    final repeticoes = exercicio['repeticoes'];
    final peso = exercicio['peso'];

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
              Expanded(
                child: Text(
                  nome,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (imagem != null && imagem.isNotEmpty)
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(imagem),
                  fit: BoxFit.cover,
                ),
              ),
            ),

          if (imagem != null && imagem.isNotEmpty) const SizedBox(height: 16),

          const Text(
            'Configuração do Treino:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoItem('Séries', series?.toString() ?? '0'),
              _buildInfoItem('Repetições', repeticoes?.toString() ?? '0'),
              _buildInfoItem('Peso', peso != null ? '${peso}kg' : 'Livre'),
            ],
          ),
          const SizedBox(height: 16),

          const Text(
            'Descrição:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            descricao,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _editarExercicio(exercicio);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'EDITAR',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _excluirExercicio(exercicio);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'EXCLUIR',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5BA0E0),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('FECHAR'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5BA0E0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nomeTreino = widget.treino['nome'] ?? 'Treino sem nome';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _voltarParaHome,
        ),
        title: Text(
          nomeTreino,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.brain),
              color: Colors.black,
              onPressed: () {},
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
              onPressed: _voltarParaHome,
            ),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.dumbbell),
              color: Colors.black,
              onPressed: () {},
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarExercicio,
        backgroundColor: const Color(0xFF5BA0E0),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
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
                  Text(
                    nomeTreino.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5BA0E0),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'EXERCÍCIOS DO TREINO',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.black54,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Expanded(child: _buildConteudoExercicios()),
          ],
        ),
      ),
    );
  }

  Widget _buildConteudoExercicios() {
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
              'Carregando exercícios...',
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
              onPressed: _carregarExerciciosDoTreino,
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

    if (exerciciosDoTreino.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, color: Colors.grey[300], size: 60),
            const SizedBox(height: 16),
            const Text(
              'Nenhum exercício neste treino',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Clique no botão + para adicionar exercícios',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        itemCount: exerciciosDoTreino.length,
        itemBuilder: (context, index) {
          final exercicio = exerciciosDoTreino[index];
          final nome = exercicio['nome'] ?? 'Exercício sem nome';
          final imagem = exercicio['img'] ?? exercicio['imagem'];
          final series = exercicio['series'];
          final repeticoes = exercicio['repeticoes'];
          final peso = exercicio['peso'];

          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                  image:
                      imagem != null && imagem.isNotEmpty
                          ? DecorationImage(
                            image: NetworkImage(imagem),
                            fit: BoxFit.cover,
                          )
                          : null,
                ),
                child:
                    imagem == null || imagem.isEmpty
                        ? const Icon(
                          Icons.fitness_center,
                          color: Colors.grey,
                          size: 24,
                        )
                        : null,
              ),
              title: Text(
                nome,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${series ?? 0} séries',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${repeticoes ?? 0} repetições',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        peso != null ? '${peso}kg' : 'Peso livre',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  _abrirModalExercicio(exercicio);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5BA0E0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'VER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class DialogEditarExercicio extends StatefulWidget {
  final dynamic exercicio;
  final Function(int, int, double?) onSalvar;

  const DialogEditarExercicio({
    super.key,
    required this.exercicio,
    required this.onSalvar,
  });

  @override
  State<DialogEditarExercicio> createState() => _DialogEditarExercicioState();
}

class _DialogEditarExercicioState extends State<DialogEditarExercicio> {
  late TextEditingController seriesController;
  late TextEditingController repeticoesController;
  late TextEditingController pesoController;

  @override
  void initState() {
    super.initState();
    seriesController = TextEditingController(
      text: widget.exercicio['series']?.toString() ?? '3',
    );
    repeticoesController = TextEditingController(
      text: widget.exercicio['repeticoes']?.toString() ?? '10',
    );
    pesoController = TextEditingController(
      text: widget.exercicio['peso']?.toString() ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Exercício'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: seriesController,
            decoration: const InputDecoration(labelText: 'Séries'),
            keyboardType: TextInputType.number,
          ),
          TextFormField(
            controller: repeticoesController,
            decoration: const InputDecoration(labelText: 'Repetições'),
            keyboardType: TextInputType.number,
          ),
          TextFormField(
            controller: pesoController,
            decoration: const InputDecoration(
              labelText: 'Peso (kg) - opcional',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final series = int.tryParse(seriesController.text) ?? 3;
            final repeticoes = int.tryParse(repeticoesController.text) ?? 10;
            final peso = double.tryParse(pesoController.text);

            widget.onSalvar(series, repeticoes, peso);
            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    seriesController.dispose();
    repeticoesController.dispose();
    pesoController.dispose();
    super.dispose();
  }
}
