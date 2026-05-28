import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const SuperColorApp());
}

class SuperColorApp extends StatelessWidget {
  const SuperColorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registro de Colores',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0D47A1),
        scaffoldBackgroundColor: const Color(0xFFF4F6FA),
      ),
      home: const HomePage(),
    );
  }
}

class ColorRecord {
  final Map<String, String> data;

  ColorRecord(this.data);

  String get searchableText {
    return data.values.join(' ').toLowerCase();
  }

  String value(String key) {
    return data[key] ?? '';
  }

  String get cliente => value('Cliente').isEmpty ? 'Sin cliente' : value('Cliente');
  String get codigo => value('Código');
  String get descripcion => value('Descripción');
  String get ubicacion => value('Ubicación física');
  String get pagina => value('Página');
  String get fecha => value('Fecha de registro');
  String get observaciones => value('Observaciones');
}

class DataService {
  static Future<List<ColorRecord>> loadRecords() async {
    final text = await rootBundle.loadString('assets/data/registros_colores.json');
    final List<dynamic> jsonData = jsonDecode(text);

    return jsonData.map((item) {
      final map = <String, String>{};

      if (item is Map) {
        item.forEach((key, value) {
          final k = key.toString().trim();
          final v = value?.toString().trim() ?? '';

          if (k.isNotEmpty && v.isNotEmpty) {
            map[k] = v;
          }
        });
      }

      return ColorRecord(map);
    }).where((record) {
      return record.data.values.any((value) => value.trim().isNotEmpty);
    }).toList();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final searchController = TextEditingController();
  List<ColorRecord> allRecords = [];
  List<ColorRecord> filteredRecords = [];
  bool loading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final records = await DataService.loadRecords();

      setState(() {
        allRecords = records;
        filteredRecords = records;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  void search() {
    final query = searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() {
        filteredRecords = allRecords;
      });
      return;
    }

    final words = query.split(' ').where((word) => word.trim().isNotEmpty).toList();

    setState(() {
      filteredRecords = allRecords.where((record) {
        final text = record.searchableText;
        return words.every((word) => text.contains(word));
      }).toList();
    });
  }

  void clearSearch() {
    searchController.clear();

    setState(() {
      filteredRecords = allRecords;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 850;

            return Column(
              children: [
                Header(total: allRecords.length, results: filteredRecords.length),
                Padding(
                  padding: EdgeInsets.all(isWide ? 28 : 14),
                  child: SearchBox(
                    controller: searchController,
                    onSearch: search,
                    onClear: clearSearch,
                  ),
                ),
                Expanded(
                  child: filteredRecords.isEmpty
                      ? const EmptyState()
                      : Padding(
                          padding: EdgeInsets.symmetric(horizontal: isWide ? 28 : 14),
                          child: isWide
                              ? GridView.builder(
                                  itemCount: filteredRecords.length,
                                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 520,
                                    mainAxisExtent: 235,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                  ),
                                  itemBuilder: (_, index) {
                                    return RecordCard(record: filteredRecords[index]);
                                  },
                                )
                              : ListView.separated(
                                  itemCount: filteredRecords.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (_, index) {
                                    return RecordCard(record: filteredRecords[index]);
                                  },
                                ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class Header extends StatelessWidget {
  final int total;
  final int results;

  const Header({
    super.key,
    required this.total,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Registro de Colores',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Busca por cliente, código, descripción, ubicación, página u observación',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              CounterBox(title: 'Total', value: total.toString()),
              CounterBox(title: 'Resultados', value: results.toString()),
            ],
          ),
        ],
      ),
    );
  }
}

class CounterBox extends StatelessWidget {
  final String title;
  final String value;

  const CounterBox({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 145,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.17),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  const SearchBox({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 600;

    if (isSmall) {
      return Column(
        children: [
          TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              hintText: 'Escribe lo que deseas buscar...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onSearch,
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: onClear,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              hintText: 'Escribe lo que deseas buscar...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: onSearch,
          icon: const Icon(Icons.search),
          label: const Text('Buscar'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: onClear,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}

class RecordCard extends StatelessWidget {
  final ColorRecord record;

  const RecordCard({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => DetailSheet(record: record),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.cliente,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              if (record.codigo.isNotEmpty) InfoLine(icon: Icons.qr_code_2, title: 'Código', value: record.codigo),
              if (record.descripcion.isNotEmpty) InfoLine(icon: Icons.palette_outlined, title: 'Descripción', value: record.descripcion),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (record.ubicacion.isNotEmpty) Tag(icon: Icons.place_outlined, text: record.ubicacion),
                  if (record.pagina.isNotEmpty) Tag(icon: Icons.menu_book_outlined, text: 'Página ${record.pagina}'),
                  if (record.fecha.isNotEmpty) Tag(icon: Icons.calendar_today_outlined, text: record.fecha),
                ],
              ),
              if (record.observaciones.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  record.observaciones,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF5F6368)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class InfoLine extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const InfoLine({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1976D2)),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.w900)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Tag extends StatelessWidget {
  final IconData icon;
  final String text;

  const Tag({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF5F6368)),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368), fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class DetailSheet extends StatelessWidget {
  final ColorRecord record;

  const DetailSheet({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final entries = record.data.entries.toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.80,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFDADCE0),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Detalle del registro',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final item = entries[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 135,
                            child: Text(
                              item.key,
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF5F6368)),
                            ),
                          ),
                          Expanded(
                            child: SelectableText(item.value),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No se encontraron resultados',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
    );
  }
}