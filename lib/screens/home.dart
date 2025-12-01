import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'parte_fisica.dart';
import 'parte_mental.dart';
import '../services/localStorage.dart';
import 'login.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LocalStorageService localStorage = LocalStorageService();
  final String _baseUrl = 'https://backend-tcc-iota.vercel.app';

  String? userId;
  String? userEmail;
  Map<String, dynamic>? _diarioDoDia;
  bool _carregando = true;
  int? _diarioId;
  List<Map<String, dynamic>> _historicoDiarios = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _carregarDiarioDoDia();
    _carregarHistoricoDiarios();
  }

  Future<void> _loadUserData() async {
    final id = await localStorage.getUserId();
    final email = await localStorage.getUserEmail();

    setState(() {
      userId = id;
      userEmail = email;
    });

    print('ID do usuário logado: $userId');
    print('Email do usuário: $userEmail');
  }

  Future<void> _carregarDiarioDoDia() async {
    setState(() {
      _carregando = true;
    });

    try {
      final token = await localStorage.getUserToken();

      if (token == null) {
        setState(() {
          _carregando = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/diario'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final diarios = json.decode(response.body);

        final userId = await localStorage.getUserId();
        final hoje = DateTime.now();
        final hojeFormatado = DateTime(hoje.year, hoje.month, hoje.day);

        print('🔍 Estrutura dos diários recebidos:');
        if (diarios is List && diarios.isNotEmpty) {
          print('📊 Total de diários: ${diarios.length}');
          for (int i = 0; i < diarios.length; i++) {
            print('   Diário $i: ${diarios[i]}');
          }
        }

        if (diarios is List) {
          Map<String, dynamic>? diarioDoUsuario;

          try {
            for (var diario in diarios.cast<Map<String, dynamic>>()) {
              try {
                final diaDiario = DateTime.parse(diario['dia']).toLocal();
                final diaDiarioFormatado = DateTime(
                  diaDiario.year,
                  diaDiario.month,
                  diaDiario.day,
                );

                if (diario['id_user'].toString() == userId &&
                    diaDiarioFormatado == hojeFormatado) {
                  diarioDoUsuario = diario;
                  break;
                }
              } catch (e) {
                continue;
              }
            }
          } catch (e) {
            print('Erro ao processar diários: $e');
          }

          if (diarioDoUsuario != null) {
            setState(() {
              _diarioDoDia = diarioDoUsuario;

              _diarioId = _diarioDoDia!['id_diario'];
              print('✅ Diário carregado. ID: $_diarioId');
              print('📋 Campos disponíveis: ${_diarioDoDia!.keys}');
              _carregando = false;
            });
          } else {
            await _criarDiarioVazio();
          }
        } else {
          print('Resposta não é uma lista: $diarios');
          setState(() {
            _carregando = false;
          });
        }
      } else {
        print('Erro HTTP: ${response.statusCode}');
        setState(() {
          _carregando = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao carregar diário: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Erro ao buscar diário: $e');
      setState(() {
        _carregando = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro de conexão: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _carregarHistoricoDiarios() async {
    try {
      final token = await localStorage.getUserToken();
      final userId = await localStorage.getUserId();

      if (token == null || userId == null) return;

      final response = await http.get(
        Uri.parse('$_baseUrl/diario'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final diarios = json.decode(response.body);

        if (diarios is List) {
          final diariosDoUsuario =
              diarios
                  .cast<Map<String, dynamic>>()
                  .where((diario) => diario['id_user'].toString() == userId)
                  .toList();

          diariosDoUsuario.sort((a, b) {
            final dateA = DateTime.parse(a['dia']);
            final dateB = DateTime.parse(b['dia']);
            return dateB.compareTo(dateA);
          });

          setState(() {
            _historicoDiarios = diariosDoUsuario;
          });

          print('📅 Histórico carregado: ${_historicoDiarios.length} diários');
        }
      }
    } catch (e) {
      print('Erro ao carregar histórico: $e');
    }
  }

  Future<void> _criarDiarioVazio() async {
    try {
      final token = await localStorage.getUserToken();
      final userId = await localStorage.getUserId();

      if (token == null || userId == null) return;

      final response = await http.post(
        Uri.parse('$_baseUrl/diario'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'id_user': int.parse(userId),
          'exercicio_feitos': 0,
          'calorias_gastas': 0.0,
          'copos_bebidos': 0,
          'metros_andados': 0,
        }),
      );

      if (response.statusCode == 201 && mounted) {
        final novoDiario = json.decode(response.body);
        setState(() {
          _diarioDoDia = novoDiario;

          if (novoDiario.containsKey('id_diario')) {
            _diarioId = novoDiario['id_diario'];
            print('✅ Diário criado. ID: $_diarioId');
          } else {
            print('⚠️ Campo id_diario não encontrado no diário criado');
            print('📋 Campos disponíveis: ${novoDiario.keys}');
            _diarioId = null;
          }
          _carregando = false;
        });

        _carregarHistoricoDiarios();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Novo diário criado para hoje! 📝'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _carregando = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erro ao criar diário: ${response.statusCode} - ${response.body}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Erro ao criar diário: $e');
      setState(() {
        _carregando = false;
      });
    }
  }

  Future<void> _atualizarCoposAgua(int novosCopos) async {
    if (_diarioId == null) {
      print('❌ ID do diário não disponível para atualização');
      return;
    }

    try {
      final token = await localStorage.getUserToken();

      if (token == null) return;

      final response = await http.put(
        Uri.parse('$_baseUrl/diario/$_diarioId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'copos_bebidos': novosCopos,
          'exercicio_feitos': _diarioDoDia?['exercicio_feitos'] ?? 0,
          'calorias_gastas': _diarioDoDia?['calorias_gastas'] ?? 0.0,
          'metros_andados': _diarioDoDia?['metros_andados'] ?? 0,
          'id_user': _diarioDoDia?['id_user'] ?? int.parse(userId!),
        }),
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _diarioDoDia!['copos_bebidos'] = novosCopos;
        });
        print('✅ Copos atualizados para: $novosCopos');
      } else {
        print(
          '❌ Erro ao atualizar copos: ${response.statusCode} - ${response.body}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao atualizar copos: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Erro ao atualizar copos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro de conexão: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _atualizarExercicios(int novosExercicios) async {
    if (_diarioId == null) {
      print('❌ ID do diário não disponível para atualização');
      return;
    }

    try {
      final token = await localStorage.getUserToken();

      if (token == null) return;

      final response = await http.put(
        Uri.parse('$_baseUrl/diario/$_diarioId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'exercicio_feitos': novosExercicios,
          'copos_bebidos': _diarioDoDia?['copos_bebidos'] ?? 0,
          'calorias_gastas': _diarioDoDia?['calorias_gastas'] ?? 0.0,
          'metros_andados': _diarioDoDia?['metros_andados'] ?? 0,
          'id_user': _diarioDoDia?['id_user'] ?? int.parse(userId!),
        }),
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _diarioDoDia!['exercicio_feitos'] = novosExercicios;
        });
        print('✅ Exercícios atualizados para: $novosExercicios');
      } else {
        print(
          '❌ Erro ao atualizar exercícios: ${response.statusCode} - ${response.body}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erro ao atualizar exercícios: ${response.statusCode}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Erro ao atualizar exercícios: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro de conexão: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _aumentarCopos() async {
    if (_diarioDoDia == null) {
      print('❌ Diário não carregado');
      return;
    }

    final coposAtuais = _diarioDoDia!['copos_bebidos'] ?? 0;
    if (coposAtuais >= 15) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meta diária de água atingida! 🎉'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final novosCopos = coposAtuais + 1;

    await _atualizarCoposAgua(novosCopos);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('+1 copo de água! 💧 Total: $novosCopos/15'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _diminuirCopos() async {
    if (_diarioDoDia == null) return;

    final coposAtuais = _diarioDoDia!['copos_bebidos'] ?? 0;
    if (coposAtuais <= 0) return;

    final novosCopos = coposAtuais - 1;
    await _atualizarCoposAgua(novosCopos);
  }

  Future<void> _aumentarExercicios() async {
    if (_diarioDoDia == null) return;

    final exerciciosAtuais = _diarioDoDia!['exercicio_feitos'] ?? 0;
    final novosExercicios = exerciciosAtuais + 1;

    await _atualizarExercicios(novosExercicios);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('+1 exercício! 💪 Total: $novosExercicios'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _diminuirExercicios() async {
    if (_diarioDoDia == null) return;

    final exerciciosAtuais = _diarioDoDia!['exercicio_feitos'] ?? 0;
    if (exerciciosAtuais <= 0) return;

    final novosExercicios = exerciciosAtuais - 1;
    await _atualizarExercicios(novosExercicios);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('-1 exercício! Total: $novosExercicios'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _logout() async {
    try {
      print('Fazendo logout...');
      await localStorage.clearUserData();
      print('Dados limpos do localStorage');

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      print('Erro durante logout: $e');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black),
            onPressed: () {
              _showHistoricoDiarios(context);
            },
            tooltip: 'Histórico de Diários',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: _logout,
            tooltip: 'Sair',
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
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

            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF5BA0E0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: const EdgeInsets.all(12),
              child: IconButton(
                icon: const Icon(Icons.home, color: Colors.white),
                onPressed: () {},
              ),
            ),

            IconButton(
              icon: const FaIcon(FontAwesomeIcons.dumbbell),
              color: Colors.black,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ParteFisica()),
                );
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Image.asset('assets/logo.jpeg', height: 60),
                  const SizedBox(height: 8),
                  const Text(
                    'SEU RITMO NOSSA TECNOLOGIA',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.black54,
                      letterSpacing: 1,
                    ),
                  ),
                  if (userEmail != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Olá, $userEmail',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5BA0E0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 40),

            _buildItemDiarioComControleExercicios(
              'Exercícios físicos feitos hoje:',
              '${_diarioDoDia?['exercicio_feitos'] ?? 0}',
              valorAtual: _diarioDoDia?['exercicio_feitos'] ?? 0,
              onIncrement: _aumentarExercicios,
              onDecrement: _diminuirExercicios,
            ),
            const SizedBox(height: 30),

            _buildItemDiario(
              'Calorias gastas hoje:',
              '${_diarioDoDia?['calorias_gastas']?.toStringAsFixed(1) ?? '0.0'} kcal',
            ),
            const SizedBox(height: 30),

            _buildItemDiarioComControle(
              'Copos de água tomados:',
              '${_diarioDoDia?['copos_bebidos'] ?? 0}/15',
              valorAtual: _diarioDoDia?['copos_bebidos'] ?? 0,
              onIncrement: _aumentarCopos,
              onDecrement: _diminuirCopos,
            ),

            const SizedBox(height: 30),
            _buildItemDiario(
              'Metros andados hoje:',
              '${_diarioDoDia?['metros_andados'] ?? 0} m',
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _carregarDiarioDoDia,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF5BA0E0)),
                      ),
                      child:
                          _carregando
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Atualizar Diário',
                                style: TextStyle(color: Color(0xFF5BA0E0)),
                              ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () {
                      _showUserInfo(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: const Icon(Icons.info_outline, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemDiario(String titulo, String valor, {VoidCallback? onAdd}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(fontSize: 18, color: Color(0xFF5BA0E0)),
            ),
          ),
          Row(
            children: [
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF5BA0E0),
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onAdd != null) ...[
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle,
                    color: Color(0xFF5BA0E0),
                    size: 28,
                  ),
                  onPressed: onAdd,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemDiarioComControleExercicios(
    String titulo,
    String valor, {
    required int valorAtual,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(fontSize: 18, color: Color(0xFF5BA0E0)),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.remove_circle,
                  color: valorAtual > 0 ? Colors.red : Colors.grey,
                  size: 28,
                ),
                onPressed: valorAtual > 0 ? onDecrement : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF5BA0E0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              IconButton(
                icon: const Icon(
                  Icons.add_circle,
                  color: Colors.green,
                  size: 28,
                ),
                onPressed: onIncrement,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemDiarioComControle(
    String titulo,
    String valor, {
    required int valorAtual,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(fontSize: 18, color: Color(0xFF5BA0E0)),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.remove_circle,
                  color: valorAtual > 0 ? Colors.red : Colors.grey,
                  size: 28,
                ),
                onPressed: valorAtual > 0 ? onDecrement : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF5BA0E0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              IconButton(
                icon: Icon(
                  Icons.add_circle,
                  color: valorAtual < 15 ? Colors.green : Colors.grey,
                  size: 28,
                ),
                onPressed: valorAtual < 15 ? onIncrement : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showHistoricoDiarios(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.history, color: Color(0xFF5BA0E0)),
                SizedBox(width: 8),
                Text('Histórico de Diários'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child:
                  _historicoDiarios.isEmpty
                      ? const Center(child: Text('Nenhum diário encontrado.'))
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _historicoDiarios.length,
                        itemBuilder: (context, index) {
                          final diario = _historicoDiarios[index];
                          final data = DateTime.parse(diario['dia']);
                          final hoje = DateTime.now();
                          final isHoje =
                              data.year == hoje.year &&
                              data.month == hoje.month &&
                              data.day == hoje.day;

                          final dataFormatada =
                              '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: Icon(
                                isHoje ? Icons.today : Icons.calendar_today,
                                color: isHoje ? Colors.green : Colors.grey,
                              ),
                              title: Text(
                                isHoje ? 'Hoje' : dataFormatada,
                                style: TextStyle(
                                  fontWeight:
                                      isHoje
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  color: isHoje ? Colors.green : Colors.black,
                                ),
                              ),
                              subtitle: Text(
                                'Exercícios: ${diario['exercicio_feitos']} | '
                                'Água: ${diario['copos_bebidos']}/15 | '
                                'Calorias: ${diario['calorias_gastas']} kcal',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                _showDetalhesDiario(context, diario, isHoje);
                              },
                            ),
                          );
                        },
                      ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          ),
    );
  }

  void _showDetalhesDiario(
    BuildContext context,
    Map<String, dynamic> diario,
    bool isHoje,
  ) {
    final data = DateTime.parse(diario['dia']);
    final dataFormatada =
        '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

    String? ultimaAtualizacao;
    if (diario.containsKey('lastupdate')) {
      final updateTime = DateTime.parse(diario['lastupdate']);
      ultimaAtualizacao =
          '${updateTime.hour.toString().padLeft(2, '0')}:${updateTime.minute.toString().padLeft(2, '0')}';
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              isHoje ? 'Diário de Hoje' : 'Diário do dia $dataFormatada',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📝 Exercícios: ${diario['exercicio_feitos']}'),
                Text('💧 Copos de água: ${diario['copos_bebidos']}/15'),
                Text('🔥 Calorias: ${diario['calorias_gastas']} kcal'),
                Text('🚶 Metros: ${diario['metros_andados']} m'),
                if (ultimaAtualizacao != null)
                  Text('🕒 Última atualização: $ultimaAtualizacao'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          ),
    );
  }

  void _showUserInfo(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Informações da Conta'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (userEmail != null) Text('Email: $userEmail'),
                if (userId != null) Text('ID: $userId'),
                if (_diarioId != null) Text('ID do Diário: $_diarioId'),
                Text('Total de diários: ${_historicoDiarios.length}'),
                const SizedBox(height: 16),
                if (_diarioDoDia != null) ...[
                  const Text(
                    'Diário de Hoje:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('📝 Exercícios: ${_diarioDoDia!['exercicio_feitos']}'),
                  Text('💧 Copos de água: ${_diarioDoDia!['copos_bebidos']}'),
                  Text('🔥 Calorias: ${_diarioDoDia!['calorias_gastas']} kcal'),
                  Text('🚶 Metros: ${_diarioDoDia!['metros_andados']} m'),
                ] else if (_carregando) ...[
                  const Center(child: CircularProgressIndicator()),
                ] else ...[
                  const Text('Nenhum diário encontrado para hoje.'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          ),
    );
  }
}
