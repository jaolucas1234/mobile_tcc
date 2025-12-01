import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ExerciciosSelecao extends StatefulWidget {
  final dynamic treino;
  final Function onExercicioAdicionado;

  const ExerciciosSelecao({
    super.key,
    required this.treino,
    required this.onExercicioAdicionado,
  });

  @override
  State<ExerciciosSelecao> createState() => _ExerciciosSelecaoState();
}

class _ExerciciosSelecaoState extends State<ExerciciosSelecao> {
  List<dynamic> exercicios = [];
  List<dynamic> exerciciosFiltrados = [];
  bool isLoading = true;
  String errorMessage = '';
  String searchQuery = '';
  String? tipoSelecionado;

  final List<String> tiposExercicio = [
    'Peito',
    'lombar',
    'dorsal',
    'trapezio',
    'abdomen',
    'biceps',
    'triceps',
    'Ombros',
    'quadriceps',
    'posterior',
    'gluteos',
    'panturrilha',
  ];

  @override
  void initState() {
    super.initState();
    _carregarExercicios();
  }

  Future<void> _carregarExercicios() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final response = await http.get(
        Uri.parse('https://backend-tcc-iota.vercel.app/exercicio'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dados = json.decode(response.body);
        setState(() {
          exercicios = dados;
          exerciciosFiltrados = dados;
          isLoading = false;
        });
      } else {
        throw Exception('Erro ao carregar exercícios: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Erro: $e';
      });
    }
  }

  void _filtrarExercicios() {
    setState(() {
      exerciciosFiltrados =
          exercicios.where((exercicio) {
            final nome = exercicio['nome']?.toString().toLowerCase() ?? '';
            final tipo = exercicio['tipo']?.toString().toLowerCase() ?? '';
            final query = searchQuery.toLowerCase();

            bool matchesSearch = nome.contains(query) || tipo.contains(query);
            bool matchesTipo =
                tipoSelecionado == null ||
                tipo == tipoSelecionado!.toLowerCase();

            return matchesSearch && matchesTipo;
          }).toList();
    });
  }

  void _selecionarExercicio(dynamic exercicio) {
    _abrirModalConfiguracao(exercicio);
  }

  void _abrirModalConfiguracao(dynamic exercicio) {
    final TextEditingController seriesController = TextEditingController();
    final TextEditingController repeticoesController = TextEditingController();
    final TextEditingController pesoController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
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
                    Text(
                      'Configurar ${exercicio['nome']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: seriesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Séries',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: repeticoesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Repetições',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: pesoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Peso (kg) - Opcional',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CANCELAR'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final series =
                              int.tryParse(seriesController.text) ?? 0;
                          final repeticoes =
                              int.tryParse(repeticoesController.text) ?? 0;
                          final peso = double.tryParse(pesoController.text);

                          if (series > 0 && repeticoes > 0) {
                            await _adicionarExercicioAoTreino(
                              exercicio,
                              series,
                              repeticoes,
                              peso,
                            );
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Séries e repetições devem ser maiores que 0',
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5BA0E0),
                        ),
                        child: const Text(
                          'ADICIONAR',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _adicionarExercicioAoTreino(
    dynamic exercicio,
    int series,
    int repeticoes,
    double? peso,
  ) async {
    try {
      final exerSelecData = {
        'id_exercicio': exercicio['id_exercicio'],
        'series': series,
        'repeticoes': repeticoes,
        'peso': peso,
      };

      final responseExerSelec = await http.post(
        Uri.parse('https://backend-tcc-iota.vercel.app/exerselec'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(exerSelecData),
      );

      if (responseExerSelec.statusCode == 200 ||
          responseExerSelec.statusCode == 201) {
        final exerSelec = json.decode(responseExerSelec.body);
        final idExerSelec = exerSelec['id_ExerSelec'];

        final treinosLinkData = {
          'id_ExerSelec': idExerSelec,
          'id_treino': widget.treino['id_treino'],
        };

        final responseTreinosLink = await http.post(
          Uri.parse('https://backend-tcc-iota.vercel.app/treinolink'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(treinosLinkData),
        );

        if (responseTreinosLink.statusCode == 200 ||
            responseTreinosLink.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Exercício adicionado ao treino!'),
              backgroundColor: Colors.green,
            ),
          );

          widget.onExercicioAdicionado();
          Navigator.pop(context);
        } else {
          throw Exception('Erro ao criar vínculo do treino');
        }
      } else {
        throw Exception('Erro ao criar exercício selecionado');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao adicionar exercício: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Exercício'),
        backgroundColor: const Color(0xFF5BA0E0),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) {
                    searchQuery = value;
                    _filtrarExercicios();
                  },
                  decoration: InputDecoration(
                    labelText: 'Pesquisar exercícios',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: tipoSelecionado,
                  decoration: InputDecoration(
                    labelText: 'Filtrar por tipo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todos os tipos'),
                    ),
                    ...tiposExercicio.map((tipo) {
                      return DropdownMenuItem(value: tipo, child: Text(tipo));
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      tipoSelecionado = value;
                    });
                    _filtrarExercicios();
                  },
                ),
              ],
            ),
          ),
          Expanded(child: _buildConteudoExercicios()),
        ],
      ),
    );
  }

  Widget _buildConteudoExercicios() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5BA0E0)),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 50, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erro: $errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _carregarExercicios,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (exerciciosFiltrados.isEmpty) {
      return const Center(child: Text('Nenhum exercício encontrado'));
    }

    return ListView.builder(
      itemCount: exerciciosFiltrados.length,
      itemBuilder: (context, index) {
        final exercicio = exerciciosFiltrados[index];
        final nome = exercicio['nome'] ?? 'Exercício sem nome';
        final tipo = exercicio['tipo'] ?? 'Sem tipo';
        final imagem = exercicio['img'] ?? exercicio['imagem'];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
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
                      ? const Icon(Icons.fitness_center)
                      : null,
            ),
            title: Text(nome),
            subtitle: Text('Tipo: $tipo'),
            trailing: const Icon(Icons.add),
            onTap: () => _selecionarExercicio(exercicio),
          ),
        );
      },
    );
  }
}
