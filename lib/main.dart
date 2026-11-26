import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const ActivityApp());
}

class ActivityApp extends StatelessWidget {
  const ActivityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Registro de atividades',
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3155A5),
          brightness: Brightness.light,
        ),
        fontFamily: 'Segoe UI',
      ),
      home: const ActivityPage(),
    );
  }
}

class Activity {
  Activity({required this.date, required this.description});

  final DateTime date;
  final String description;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'description': description,
      };

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String,
    );
  }
}

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  final _dateController = TextEditingController();
  final _activityController = TextEditingController();
  final _dateFocusNode = FocusNode();
  final _activityFocusNode = FocusNode();

  DateTime _selectedDate = DateTime.now();
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<Activity> _activities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _setDate(DateTime.now());
    _loadActivities();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _activityController.dispose();
    _dateFocusNode.dispose();
    _activityFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    try {
      final file = await _storageFile();
      if (await file.exists()) {
        final decoded =
            jsonDecode(await file.readAsString()) as List<dynamic>;
        setState(() {
          _activities = decoded
              .map((raw) => Activity.fromJson(raw as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _saveActivities() async {
    final file = await _storageFile();
    await file.writeAsString(
      jsonEncode(_activities.map((item) => item.toJson()).toList()),
    );
  }

  Future<File> _storageFile() async {
    final baseDirectory =
        Platform.environment['LOCALAPPDATA'] ?? Directory.current.path;
    final directory = Directory(
      '$baseDirectory${Platform.pathSeparator}aula_12',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return File('${directory.path}${Platform.pathSeparator}activities.json');
  }

  void _setDate(DateTime date) {
    _selectedDate = date;
    _dateController.text =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
      helpText: 'Selecione o dia',
      cancelText: 'Cancelar',
      confirmText: 'OK',
    );
    if (date != null) {
      setState(() {
        _setDate(date);
        _selectedMonth = DateTime(date.year, date.month);
      });
    }
  }

  Future<void> _pickMonth() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
      helpText: 'Selecione o mês',
      cancelText: 'Cancelar',
      confirmText: 'OK',
    );
    if (date != null) {
      setState(() {
        _selectedMonth = DateTime(date.year, date.month);
      });
    }
  }

  Future<void> _saveActivity() async {
    final description = _activityController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite uma atividade.')),
      );
      _activityFocusNode.requestFocus();
      return;
    }

    setState(() {
      _activities.add(Activity(
        date: _selectedDate,
        description: description,
      ));
      _activities.sort((a, b) => b.date.compareTo(a.date));
      _activityController.clear();
      _selectedMonth = DateTime(_selectedDate.year, _selectedDate.month);
    });
    await _saveActivities();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Atividade salva com sucesso.')),
    );
  }

  String _monthName(int month) {
    const names = [
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
    ];
    return names[month - 1];
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final monthActivities = _activities
        .where((item) =>
            item.date.year == _selectedMonth.year &&
            item.date.month == _selectedMonth.month)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Projeto',
                    style: TextStyle(
                      color: Color(0xFF3155A5),
                      fontSize: 54,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Crie um sistema para cadastro de atividades desenvolvidas no dia:',
                    style: TextStyle(
                      color: Color(0xFF343943),
                      fontSize: 24,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildRequirement(
                    'Permita ao usuário digitar o dia.',
                    _buildDateField(),
                  ),
                  const SizedBox(height: 16),
                  _buildRequirement(
                    'Receba a atividade.',
                    _buildActivityField(),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: _saveActivity,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Salvar atividade'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF3155A5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Atividades do mês',
                          style: TextStyle(
                            color: Color(0xFF343943),
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _pickMonth,
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Text(
                          '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3155A5),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildActivities(monthActivities),
                  const SizedBox(height: 20),
                  const Text(
                    'Permita a seleção de meses anteriores.',
                    style: TextStyle(
                      color: Color(0xFF343943),
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirement(String title, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 11, right: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF343943),
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF343943),
                  fontSize: 22,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        field,
      ],
    );
  }

  Widget _buildDateField() {
    return TextField(
      controller: _dateController,
      focusNode: _dateFocusNode,
      readOnly: true,
      onTap: _pickDate,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.calendar_today_outlined),
        hintText: 'DD/MM/AAAA',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildActivityField() {
    return TextField(
      controller: _activityController,
      focusNode: _activityFocusNode,
      minLines: 2,
      maxLines: 4,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _saveActivity(),
      decoration: InputDecoration(
        hintText: 'Descreva a atividade desenvolvida',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildActivities(List<Activity> activities) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (activities.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE1E5EE)),
        ),
        child: const Text(
          'Nenhuma atividade cadastrada neste mês.',
          style: TextStyle(color: Color(0xFF697080), fontSize: 16),
        ),
      );
    }

    return Column(
      children: activities
          .map(
            (activity) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE1E5EE)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF0FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      activity.date.day.toString().padLeft(2, '0'),
                      style: const TextStyle(
                        color: Color(0xFF3155A5),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(activity.date),
                          style: const TextStyle(
                            color: Color(0xFF697080),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activity.description,
                          style: const TextStyle(
                            color: Color(0xFF343943),
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
