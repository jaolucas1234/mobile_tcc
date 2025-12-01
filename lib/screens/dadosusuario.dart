import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/localStorage.dart';

enum Sexo { MASCULINO, FEMININO }

class DadosUsuarioScreen extends StatefulWidget {
  const DadosUsuarioScreen({super.key});

  @override
  State<DadosUsuarioScreen> createState() => _DadosUsuarioScreenState();
}

class _DadosUsuarioScreenState extends State<DadosUsuarioScreen> {
  List<Map<String, dynamic>> _dadosFisicos = [];
  List<Map<String, dynamic>> _dadosMentais = [];
  bool _carregando = true;
  final String _baseUrl = 'https://backend-tcc-iota.vercel.app';
  final LocalStorageService _localStorage = LocalStorageService();

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final String? userId = await _localStorage.getUserId();
      final String? token = await _localStorage.getUserToken();

      if (userId == null || token == null) {
        setState(() {
          _carregando = false;
        });
        return;
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final responseFisicos = await http.get(
        Uri.parse('$_baseUrl/dadosfisicos'),
        headers: headers,
      );

      final responseMentais = await http.get(
        Uri.parse('$_baseUrl/dadosmentais'),
        headers: headers,
      );

      setState(() {
        if (responseFisicos.statusCode == 200) {
          final List<dynamic> data = json.decode(responseFisicos.body);
          _dadosFisicos =
              data
                  .cast<Map<String, dynamic>>()
                  .where((item) => item['id_user'].toString() == userId)
                  .toList();
        }

        if (responseMentais.statusCode == 200) {
          final List<dynamic> data = json.decode(responseMentais.body);
          _dadosMentais =
              data
                  .cast<Map<String, dynamic>>()
                  .where((item) => item['id_user'].toString() == userId)
                  .toList();
        }

        _carregando = false;
      });
    } catch (error) {
      print('Erro ao carregar dados: $error');
      setState(() {
        _carregando = false;
      });
    }
  }

  Map<String, dynamic>? get _dadosFisicosIniciais {
    if (_dadosFisicos.isEmpty) return null;

    final listaOrdenada = List<Map<String, dynamic>>.from(_dadosFisicos);
    listaOrdenada.sort(
      (a, b) => a['id_dadosfisicos'].compareTo(b['id_dadosfisicos']),
    );
    return listaOrdenada.first;
  }

  Map<String, dynamic>? get _dadosFisicosAtuais {
    if (_dadosFisicos.isEmpty) return null;

    final listaOrdenada = List<Map<String, dynamic>>.from(_dadosFisicos);
    listaOrdenada.sort(
      (a, b) => b['id_dadosfisicos'].compareTo(a['id_dadosfisicos']),
    );
    return listaOrdenada.first;
  }

  Map<String, dynamic>? get _dadosMentaisIniciais {
    if (_dadosMentais.isEmpty) return null;

    final listaOrdenada = List<Map<String, dynamic>>.from(_dadosMentais);
    listaOrdenada.sort(
      (a, b) => a['id_dadosmentais'].compareTo(b['id_dadosmentais']),
    );
    return listaOrdenada.first;
  }

  Map<String, dynamic>? get _dadosMentaisAtuais {
    if (_dadosMentais.isEmpty) return null;

    final listaOrdenada = List<Map<String, dynamic>>.from(_dadosMentais);
    listaOrdenada.sort(
      (a, b) => b['id_dadosmentais'].compareTo(a['id_dadosmentais']),
    );
    return listaOrdenada.first;
  }

  double _calcularIMC(double altura, double peso) {
    if (altura == 0.0) return 0.0;
    return peso / (altura * altura);
  }

  String _classificarIMC(double imc) {
    if (imc < 18.5) return 'Abaixo do peso';
    if (imc < 25) return 'Peso normal';
    if (imc < 30) return 'Sobrepeso';
    if (imc < 35) return 'Obesidade Grau I';
    if (imc < 40) return 'Obesidade Grau II';
    return 'Obesidade Grau III';
  }

  Color _corIMC(double imc) {
    if (imc < 18.5) return Colors.orange;
    if (imc < 25) return Colors.green;
    if (imc < 30) return Colors.yellow[700]!;
    if (imc < 35) return Colors.orange;
    return Colors.red;
  }

  void _editarDadoFisico(String campo, String valorAtual) {
    String valorParaEditar = valorAtual;
    if (campo == 'altura') {
      valorParaEditar = valorAtual.replaceAll(' m', '');
    } else if (campo == 'peso') {
      valorParaEditar = valorAtual.replaceAll(' kg', '');
    } else if (campo == 'idade') {
      valorParaEditar = valorAtual.replaceAll(' anos', '');
    }

    _mostrarDialogoEdicao(campo, valorParaEditar, true);
  }

  void _editarDadoMental(String campo, String valorAtual) {
    String valorParaEditar = valorAtual.replaceAll(' horas', '');
    _mostrarDialogoEdicao(campo, valorParaEditar, false);
  }

  void _mostrarDialogoEdicao(String campo, String valorAtual, bool isFisico) {
    final controller = TextEditingController(text: valorAtual);

    TextInputType keyboardType = TextInputType.text;
    String hintText = 'Digite o novo valor';

    if (isFisico) {
      switch (campo) {
        case 'altura':
          keyboardType = TextInputType.numberWithOptions(decimal: true);
          hintText = 'Ex: 1.75';
          break;
        case 'peso':
          keyboardType = TextInputType.numberWithOptions(decimal: true);
          hintText = 'Ex: 70.5';
          break;
        case 'idade':
          keyboardType = TextInputType.number;
          hintText = 'Ex: 25';
          break;
        case 'exeReg':
        case 'obj':
        case 'deli':
          keyboardType = TextInputType.text;
          hintText = 'Digite o novo valor';
          break;
        default:
          keyboardType = TextInputType.text;
          hintText = 'Digite o novo valor';
      }
    } else {
      if (campo == 'sonoPerDia' ||
          campo == 'trabPerDia' ||
          campo == 'tempHobby') {
        keyboardType = TextInputType.number;
        hintText = 'Ex: 8';
      } else {
        keyboardType = TextInputType.text;
        hintText = 'Digite o novo valor';
      }
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Editar ${_formatarNomeCampo(campo)}'),
            content: TextField(
              controller: controller,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                labelText: 'Novo valor',
                hintText: hintText,
                border: const OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  _atualizarDado(campo, controller.text, isFisico);
                  Navigator.pop(context);
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
    );
  }

  String _formatarNomeCampo(String campo) {
    switch (campo) {
      case 'altura':
        return 'Altura';
      case 'peso':
        return 'Peso';
      case 'idade':
        return 'Idade';
      case 'exeReg':
        return 'Exercícios Regulares';
      case 'obj':
        return 'Objetivo';
      case 'deli':
        return 'Delimitações';
      case 'sonoPerDia':
        return 'Sono por Dia';
      case 'trabPerDia':
        return 'Trabalho por Dia';
      case 'tempHobby':
        return 'Tempo para Hobbies';
      case 'transt':
        return 'Transtornos/Observações';
      default:
        return campo;
    }
  }

  Future<void> _atualizarDado(
    String campo,
    String novoValor,
    bool isFisico,
  ) async {
    try {
      final String? userId = await _localStorage.getUserId();
      final String? token = await _localStorage.getUserToken();

      if (userId == null || token == null) return;

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      if (isFisico) {
        final dadosAtuais = _dadosFisicosAtuais;
        if (dadosAtuais == null) return;

        final dadosAtualizados = {...dadosAtuais};

        if (campo == 'altura') {
          dadosAtualizados['altura'] = double.tryParse(novoValor) ?? 0.0;
        } else if (campo == 'peso') {
          dadosAtualizados['peso'] = double.tryParse(novoValor) ?? 0.0;
        } else if (campo == 'idade') {
          dadosAtualizados['idade'] = int.tryParse(novoValor) ?? 0;
        } else if (campo == 'exeReg') {
          dadosAtualizados['exeReg'] = novoValor;
        } else if (campo == 'obj') {
          dadosAtualizados['obj'] = novoValor;
        } else if (campo == 'deli') {
          dadosAtualizados['deli'] = novoValor.isEmpty ? null : novoValor;
        }

        final idDadosFisicos = dadosAtuais['id_dadosfisicos'];
        await http.put(
          Uri.parse('$_baseUrl/dadosfisicos/$idDadosFisicos'),
          headers: headers,
          body: json.encode(dadosAtualizados),
        );
      } else {
        final dadosAtuais = _dadosMentaisAtuais;
        if (dadosAtuais == null) return;

        final dadosAtualizados = {...dadosAtuais};

        if (campo == 'sonoPerDia') {
          dadosAtualizados['sonoPerDia'] = int.tryParse(novoValor) ?? 0;
        } else if (campo == 'trabPerDia') {
          dadosAtualizados['trabPerDia'] = int.tryParse(novoValor) ?? 0;
        } else if (campo == 'tempHobby') {
          dadosAtualizados['tempHobby'] = int.tryParse(novoValor) ?? 0;
        } else if (campo == 'transt') {
          dadosAtualizados['transt'] = novoValor.isEmpty ? null : novoValor;
        }

        final idDadosMentais = dadosAtuais['id_dadosmentais'];
        await http.put(
          Uri.parse('$_baseUrl/dadosmentais/$idDadosMentais'),
          headers: headers,
          body: json.encode(dadosAtualizados),
        );
      }

      _carregarDados();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dado atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      print('Erro ao atualizar dado: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _criarDadosAtuais() async {
    try {
      final String? userId = await _localStorage.getUserId();
      final String? token = await _localStorage.getUserToken();

      if (userId == null || token == null) return;

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      bool criouAlgum = false;

      if (_dadosFisicosIniciais != null && _dadosFisicos.length == 1) {
        final dadosFisicosAtuais = {
          'altura': _dadosFisicosIniciais!['altura'],
          'peso': _dadosFisicosIniciais!['peso'],
          'idade': _dadosFisicosIniciais!['idade'],
          'sexo': _dadosFisicosIniciais!['sexo'],
          'exeReg': _dadosFisicosIniciais!['exeReg'],
          'obj': _dadosFisicosIniciais!['obj'],
          'deli': _dadosFisicosIniciais!['deli'],
          'id_user': int.parse(userId!),
        };

        await http.post(
          Uri.parse('$_baseUrl/dadosfisicos'),
          headers: headers,
          body: json.encode(dadosFisicosAtuais),
        );
        criouAlgum = true;
      }

      if (_dadosMentaisIniciais != null && _dadosMentais.length == 1) {
        final dadosMentaisAtuais = {
          'sonoPerDia': _dadosMentaisIniciais!['sonoPerDia'],
          'trabPerDia': _dadosMentaisIniciais!['trabPerDia'],
          'tempHobby': _dadosMentaisIniciais!['tempHobby'],
          'transt': _dadosMentaisIniciais!['transt'],
          'id_user': int.parse(userId!),
        };

        await http.post(
          Uri.parse('$_baseUrl/dadosmentais'),
          headers: headers,
          body: json.encode(dadosMentaisAtuais),
        );
        criouAlgum = true;
      }

      if (criouAlgum) {
        _carregarDados();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Dados atuais criados com sucesso! Agora você pode editá-los.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      print('Erro ao criar dados atuais: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao criar dados atuais: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cadastrarDadosIniciais() {
    _mostrarFormularioDadosIniciais();
  }

  void _mostrarFormularioDadosIniciais() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => FormularioDadosIniciaisScreen(
            onSalvar: () {
              _carregarDados();
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Meu Progresso'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body:
          _carregando
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF5BA0E0)),
              )
              : _dadosFisicos.isEmpty && _dadosMentais.isEmpty
              ? _buildSemDados()
              : _buildComDados(),
    );
  }

  Widget _buildSemDados() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF5BA0E0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.person_outline,
              color: Color(0xFF5BA0E0),
              size: 50,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Complete seu Perfil',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Para acompanhar seu progresso, precisamos conhecer melhor você',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _cadastrarDadosIniciais,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5BA0E0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'Cadastrar Dados Iniciais',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComDados() {
    final temApenasIniciais =
        _dadosFisicos.length == 1 && _dadosMentais.length == 1;
    final temDadosAtuais = _dadosFisicos.length > 1 || _dadosMentais.length > 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (temApenasIniciais)
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF5BA0E0),
                      size: 40,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Criar Dados Atuais',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Clique para criar uma cópia editável dos seus dados',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: _criarDadosAtuais,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5BA0E0),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Criar Dados Atuais'),
                    ),
                  ],
                ),
              ),
            ),

          if (temApenasIniciais) const SizedBox(height: 20),

          if (_dadosFisicosIniciais != null) ...[
            _buildCardDadosFisicos(
              'Dados Físicos - Iniciais',
              _dadosFisicosIniciais!,
              false,
            ),
            const SizedBox(height: 20),
          ],

          if (temDadosAtuais && _dadosFisicosAtuais != null) ...[
            _buildCardDadosFisicos(
              'Dados Físicos - Atuais',
              _dadosFisicosAtuais!,
              true,
            ),
            const SizedBox(height: 20),
          ],

          if (_dadosMentaisIniciais != null) ...[
            _buildCardDadosMentais(
              'Dados Mentais - Iniciais',
              _dadosMentaisIniciais!,
              false,
            ),
            const SizedBox(height: 20),
          ],

          if (temDadosAtuais && _dadosMentaisAtuais != null) ...[
            _buildCardDadosMentais(
              'Dados Mentais - Atuais',
              _dadosMentaisAtuais!,
              true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardDadosFisicos(
    String titulo,
    Map<String, dynamic> dados,
    bool editavel,
  ) {
    final altura = dados['altura']?.toDouble() ?? 0.0;
    final peso = dados['peso']?.toDouble() ?? 0.0;
    final imc = _calcularIMC(altura, peso);
    final corIMC = _corIMC(imc);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5BA0E0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: Color(0xFF5BA0E0),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildInfoRowEditavel(
              'Altura',
              '${altura.toStringAsFixed(2)} m',
              editavel,
              'altura',
              true,
            ),

            _buildInfoRowEditavel(
              'Peso',
              '${peso.toStringAsFixed(1)} kg',
              editavel,
              'peso',
              true,
            ),

            _buildInfoRowEditavel(
              'Idade',
              '${dados['idade']} anos',
              editavel,
              'idade',
              true,
            ),

            _buildInfoRow(
              'Sexo',
              dados['sexo'] == 'MASCULINO' ? 'Masculino' : 'Feminino',
            ),

            _buildInfoRowEditavel(
              'Exercícios Regulares',
              dados['exeReg'] ?? '',
              editavel,
              'exeReg',
              true,
            ),

            _buildInfoRowEditavel(
              'Objetivo',
              dados['obj'] ?? '',
              editavel,
              'obj',
              true,
            ),

            if (dados['deli'] != null && dados['deli'].toString().isNotEmpty)
              _buildInfoRow('Delimitações', dados['deli']!),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: corIMC.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: corIMC.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        editavel ? 'IMC Atual' : 'IMC Inicial',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        imc.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: corIMC,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _classificarIMC(imc),
                    style: TextStyle(
                      fontSize: 16,
                      color: corIMC,
                      fontWeight: FontWeight.w500,
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

  Widget _buildCardDadosMentais(
    String titulo,
    Map<String, dynamic> dados,
    bool editavel,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5BA0E0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Color(0xFF5BA0E0),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildInfoRowEditavel(
              'Sono por Dia',
              '${dados['sonoPerDia']} horas',
              editavel,
              'sonoPerDia',
              false,
            ),
            _buildInfoRowEditavel(
              'Trabalho por Dia',
              '${dados['trabPerDia']} horas',
              editavel,
              'trabPerDia',
              false,
            ),
            _buildInfoRowEditavel(
              'Tempo para Hobbies',
              '${dados['tempHobby']} horas',
              editavel,
              'tempHobby',
              false,
            ),
            if (dados['transt'] != null &&
                dados['transt'].toString().isNotEmpty)
              _buildInfoRowEditavel(
                'Transtornos/Observações',
                dados['transt']!,
                editavel,
                'transt',
                false,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              titulo,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRowEditavel(
    String titulo,
    String valor,
    bool editavel,
    String campo,
    bool isFisico,
  ) {
    if (editavel) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: InkWell(
          onTap: () {
            if (isFisico) {
              _editarDadoFisico(campo, valor);
            } else {
              _editarDadoMental(campo, valor);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  titulo,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                Row(
                  children: [
                    Text(
                      valor,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.edit, size: 16, color: Colors.grey[400]),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return _buildInfoRow(titulo, valor);
    }
  }
}

class FormularioDadosIniciaisScreen extends StatefulWidget {
  final Function onSalvar;

  const FormularioDadosIniciaisScreen({super.key, required this.onSalvar});

  @override
  State<FormularioDadosIniciaisScreen> createState() =>
      _FormularioDadosIniciaisScreenState();
}

class _FormularioDadosIniciaisScreenState
    extends State<FormularioDadosIniciaisScreen> {
  final _formKey = GlobalKey<FormState>();
  final LocalStorageService _localStorage = LocalStorageService();
  final String _baseUrl = 'https://backend-tcc-iota.vercel.app';

  final TextEditingController _alturaController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _idadeController = TextEditingController();
  final TextEditingController _exeRegController = TextEditingController();
  final TextEditingController _objController = TextEditingController();
  final TextEditingController _deliController = TextEditingController();
  Sexo _sexo = Sexo.MASCULINO;

  final TextEditingController _sonoController = TextEditingController();
  final TextEditingController _trabalhoController = TextEditingController();
  final TextEditingController _hobbyController = TextEditingController();
  final TextEditingController _transtController = TextEditingController();

  bool _enviando = false;

  Future<void> _salvarDados() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _enviando = true;
    });

    try {
      final String? userId = await _localStorage.getUserId();
      final String? token = await _localStorage.getUserToken();

      if (userId == null || token == null) {
        throw Exception('Usuário não autenticado');
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final dadosFisicos = {
        'altura': double.parse(_alturaController.text),
        'peso': double.parse(_pesoController.text),
        'idade': int.parse(_idadeController.text),
        'sexo': _sexo.toString().split('.').last,
        'exeReg': _exeRegController.text,
        'obj': _objController.text,
        'deli': _deliController.text.isNotEmpty ? _deliController.text : null,
        'id_user': int.parse(userId),
      };

      final dadosMentais = {
        'sonoPerDia': int.parse(_sonoController.text),
        'trabPerDia': int.parse(_trabalhoController.text),
        'tempHobby': int.parse(_hobbyController.text),
        'transt':
            _transtController.text.isNotEmpty ? _transtController.text : null,
        'id_user': int.parse(userId),
      };

      await http.post(
        Uri.parse('$_baseUrl/dadosfisicos'),
        headers: headers,
        body: json.encode(dadosFisicos),
      );

      await http.post(
        Uri.parse('$_baseUrl/dadosmentais'),
        headers: headers,
        body: json.encode(dadosMentais),
      );

      widget.onSalvar();
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dados iniciais cadastrados com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      print('Erro ao salvar dados: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar dados: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _enviando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Dados Iniciais'),
        actions: [
          if (_enviando)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dados Físicos Iniciais',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _alturaController,
                decoration: const InputDecoration(
                  labelText: 'Altura (m)',
                  hintText: 'Ex: 1.75',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Informe a altura';
                  final altura = double.tryParse(value);
                  if (altura == null || altura < 0.5 || altura > 2.5) {
                    return 'Altura inválida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _pesoController,
                decoration: const InputDecoration(
                  labelText: 'Peso (kg)',
                  hintText: 'Ex: 70.5',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Informe o peso';
                  final peso = double.tryParse(value);
                  if (peso == null || peso < 1 || peso > 300) {
                    return 'Peso inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _idadeController,
                decoration: const InputDecoration(
                  labelText: 'Idade',
                  hintText: 'Ex: 25',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Informe a idade';
                  final idade = int.tryParse(value);
                  if (idade == null || idade < 1 || idade > 120) {
                    return 'Idade inválida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              const Text(
                'Sexo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Row(
                children: [
                  Radio<Sexo>(
                    value: Sexo.MASCULINO,
                    groupValue: _sexo,
                    onChanged: (value) {
                      setState(() {
                        _sexo = value!;
                      });
                    },
                  ),
                  const Text('Masculino'),
                  const SizedBox(width: 20),
                  Radio<Sexo>(
                    value: Sexo.FEMININO,
                    groupValue: _sexo,
                    onChanged: (value) {
                      setState(() {
                        _sexo = value!;
                      });
                    },
                  ),
                  const Text('Feminino'),
                ],
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _exeRegController,
                decoration: const InputDecoration(
                  labelText: 'Exercícios Regulares',
                  hintText: 'Ex: 3 vezes por semana',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe sua rotina de exercícios';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _objController,
                decoration: const InputDecoration(
                  labelText: 'Objetivo',
                  hintText: 'Ex: Perder peso, Ganhar massa muscular',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe seu objetivo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _deliController,
                decoration: const InputDecoration(
                  labelText: 'Delimitações (Opcional)',
                  hintText: 'Ex: Problemas no joelho, restrições alimentares',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 30),

              const Text(
                'Dados Mentais Iniciais',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _sonoController,
                decoration: const InputDecoration(
                  labelText: 'Sono por Dia (horas)',
                  hintText: 'Ex: 7',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Informe as horas de sono';
                  final sono = int.tryParse(value);
                  if (sono == null || sono < 0 || sono > 24) {
                    return 'Horas de sono inválidas';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _trabalhoController,
                decoration: const InputDecoration(
                  labelText: 'Trabalho por Dia (horas)',
                  hintText: 'Ex: 8',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Informe as horas de trabalho';
                  final trabalho = int.tryParse(value);
                  if (trabalho == null || trabalho < 0 || trabalho > 24) {
                    return 'Horas de trabalho inválidas';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _hobbyController,
                decoration: const InputDecoration(
                  labelText: 'Tempo para Hobbies (horas)',
                  hintText: 'Ex: 2',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Informe o tempo para hobbies';
                  final hobby = int.tryParse(value);
                  if (hobby == null || hobby < 0 || hobby > 24) {
                    return 'Tempo para hobbies inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _transtController,
                decoration: const InputDecoration(
                  labelText: 'Transtornos/Observações (Opcional)',
                  hintText: 'Ex: Ansiedade, estresse no trabalho',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _enviando ? null : _salvarDados,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5BA0E0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _enviando
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Text(
                            'Salvar Dados Iniciais',
                            style: TextStyle(fontSize: 16),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _alturaController.dispose();
    _pesoController.dispose();
    _idadeController.dispose();
    _exeRegController.dispose();
    _objController.dispose();
    _deliController.dispose();
    _sonoController.dispose();
    _trabalhoController.dispose();
    _hobbyController.dispose();
    _transtController.dispose();
    super.dispose();
  }
}
