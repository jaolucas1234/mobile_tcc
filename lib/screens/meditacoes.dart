import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'parte_mental.dart';
import 'meditacaouser.dart';

class MeditacoesScreen extends StatefulWidget {
  const MeditacoesScreen({super.key});

  @override
  State<MeditacoesScreen> createState() => _MeditacoesScreenState();
}

class _MeditacoesScreenState extends State<MeditacoesScreen> {
  List<Meditacao> _meditacoes = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _carregarMeditacoes();
  }

  Future<void> _carregarMeditacoes() async {
    try {
      print('📡 Carregando meditações...');

      final response = await http.get(
        Uri.parse('https://backend-tcc-iota.vercel.app/meditacao'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📥 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🎯 Dados recebidos: $data');

        if (data is List) {
          setState(() {
            _meditacoes = data.map((item) => Meditacao.fromJson(item)).toList();
            _isLoading = false;
          });
        } else if (data['meditacoes'] is List) {
          setState(() {
            _meditacoes =
                (data['meditacoes'] as List)
                    .map((item) => Meditacao.fromJson(item))
                    .toList();
            _isLoading = false;
          });
        } else {
          throw Exception('Estrutura de dados inválida');
        }
      } else {
        throw Exception('Erro ao carregar: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _mostrarDetalhesMeditacao(Meditacao meditacao) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildModalDetalhes(meditacao),
    );
  }

  void _iniciarMeditacaoComTempo(Meditacao meditacao, int tempoSegundos) {
    print('🔍🔍🔍 VERIFICANDO ID DA MEDITAÇÃO:');
    print('   ID original: ${meditacao.id}');
    print('   Tipo: ${meditacao.id.runtimeType}');
    print('   É vazio? ${meditacao.id.isEmpty}');
    print('   Tamanho: ${meditacao.id.length}');

    final int idMeditacao;

    if (meditacao.id.isEmpty) {
      print('⚠️ ATENÇÃO: ID está vazio! Usando valor padrão 1');
      idMeditacao = 1;
    } else {
      idMeditacao = int.tryParse(meditacao.id) ?? 1;
      print('✅ ID convertido: $idMeditacao');
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MeditacaoUser(
              meditacao: {
                'id': idMeditacao,
                'titulo': meditacao.titulo,
                'descricao': meditacao.descricao,
                'descricaoCompleta': meditacao.descricaoCompleta,
                'duracao': tempoSegundos ~/ 60,
                'duracao_segundos': tempoSegundos,
                'nivel': meditacao.nivel,
                'categoria': meditacao.categoria,
                'beneficios': meditacao.beneficios,
                'audioUrl': meditacao.audioUrl,
              },
            ),
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ParteMental()),
            );
          },
        ),
        title: const Text(
          'Meditações Guiadas',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_hasError) {
      return _buildError();
    }

    if (_meditacoes.isEmpty) {
      return _buildEmpty();
    }

    return _buildListaMeditacoes();
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF5BA0E0)),
          SizedBox(height: 16),
          Text(
            'Carregando meditações...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Erro ao carregar meditações',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Verifique sua conexão e tente novamente',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _carregarMeditacoes,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5BA0E0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.self_improvement, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma meditação disponível',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Volte mais tarde para novas meditações',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _carregarMeditacoes,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5BA0E0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Recarregar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaMeditacoes() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: _meditacoes.length,
        itemBuilder: (context, index) {
          final meditacao = _meditacoes[index];
          return _buildCardMeditacao(meditacao);
        },
      ),
    );
  }

  Widget _buildCardMeditacao(Meditacao meditacao) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _mostrarDetalhesMeditacao(meditacao),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF5BA0E0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconForCategory(meditacao.categoria),
                  color: const Color(0xFF5BA0E0),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meditacao.titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meditacao.descricao,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.timer, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${meditacao.duracao} min',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.people, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          meditacao.nivel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF5BA0E0),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalDetalhes(Meditacao meditacao) {
    int _tempoSelecionado = meditacao.duracao * 60;
    final List<int> _temposPredefinidos = [60, 300, 600, 900, 1800];

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5BA0E0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconForCategory(meditacao.categoria),
                      color: const Color(0xFF5BA0E0),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meditacao.titulo,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${meditacao.duracao} min • ${meditacao.nivel}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                'Descrição',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                meditacao.descricaoCompleta,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Benefícios',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    meditacao.beneficios.map((beneficio) {
                      return Chip(
                        label: Text(
                          beneficio,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: const Color(0xFF5BA0E0),
                      );
                    }).toList(),
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.timer, color: Color(0xFF5BA0E0), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Duração da meditação',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Escolha por quanto tempo deseja meditar:',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          _temposPredefinidos.map((tempo) {
                            final minutos = tempo ~/ 60;
                            final isSelected = _tempoSelecionado == tempo;

                            return ChoiceChip(
                              label: Text(
                                '$minutos min',
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _tempoSelecionado = tempo;
                                });
                              },
                              selectedColor: const Color(0xFF5BA0E0),
                              backgroundColor: Colors.grey.shade200,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            );
                          }).toList(),
                    ),

                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5BA0E0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF5BA0E0).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.access_time,
                            color: const Color(0xFF5BA0E0),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tempo selecionado: ${_tempoSelecionado ~/ 60} minutos',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5BA0E0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _iniciarMeditacaoComTempo(meditacao, _tempoSelecionado);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5BA0E0),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Começar Meditação',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getIconForCategory(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'ansiedade':
        return Icons.psychology;
      case 'sono':
        return Icons.nightlight_round;
      case 'foco':
        return Icons.center_focus_strong;
      case 'relaxamento':
        return Icons.spa;
      default:
        return Icons.self_improvement;
    }
  }
}

class Meditacao {
  final String id;
  final String titulo;
  final String descricao;
  final String descricaoCompleta;
  final int duracao;
  final String nivel;
  final String categoria;
  final List<String> beneficios;
  final String audioUrl;

  Meditacao({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.descricaoCompleta,
    required this.duracao,
    required this.nivel,
    required this.categoria,
    required this.beneficios,
    required this.audioUrl,
  });

  factory Meditacao.fromJson(Map<String, dynamic> json) {
    return Meditacao(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? 'Meditação',
      descricao: json['descricao']?.toString() ?? 'Descrição da meditação',
      descricaoCompleta:
          json['descricaoCompleta']?.toString() ??
          json['descricao']?.toString() ??
          'Descrição completa da meditação',
      duracao: _parseDuracao(json['duracao']),
      nivel: json['nivel']?.toString() ?? 'Iniciante',
      categoria: json['categoria']?.toString() ?? 'Geral',
      beneficios: _parseBeneficios(json['beneficios']),
      audioUrl: json['audioUrl']?.toString() ?? '',
    );
  }

  static int _parseDuracao(dynamic duracao) {
    if (duracao is int) return duracao;
    if (duracao is String) return int.tryParse(duracao) ?? 10;
    return 10;
  }

  static List<String> _parseBeneficios(dynamic beneficios) {
    if (beneficios is List) {
      return beneficios.map((e) => e.toString()).toList();
    }
    if (beneficios is String) {
      return beneficios.split(',').map((e) => e.trim()).toList();
    }
    return ['Relaxamento', 'Foco', 'Bem-estar'];
  }
}
