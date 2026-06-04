import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:thisjowi/components/liquid_glass.dart';
import 'package:thisjowi/i18n/translations.dart';

class LegalDocumentsScreen extends StatefulWidget {
  const LegalDocumentsScreen({super.key});

  @override
  State<LegalDocumentsScreen> createState() => _LegalDocumentsScreenState();
}

class _LegalDocumentsScreenState extends State<LegalDocumentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<int, String> _cachedDocuments = {};
  final Map<int, bool> _loadingDocuments = {};
  bool _initialLoadDone = false;

  static const _documents = [
    ('privacy_policy.txt', 'privacy_policy_es.txt'),
    ('cookie_policy.txt', 'cookie_policy_es.txt'),
    ('terms_and_conditions.txt', 'terms_and_conditions_es.txt'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadDocument(_tabController.index);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialLoadDone) {
      _initialLoadDone = true;
      _loadDocument(0);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDocument(int index) async {
    if (_cachedDocuments.containsKey(index)) return;
    setState(() => _loadingDocuments[index] = true);
    final locale = Localizations.localeOf(context).languageCode;
    final files = _documents[index];
    final fileName = locale == 'es' ? files.$2 : files.$1;
    try {
      final data = await rootBundle.loadString('assets/$fileName');
      _cachedDocuments[index] = data;
    } catch (_) {
      final data = await rootBundle.loadString('assets/${files.$1}');
      _cachedDocuments[index] = data;
    }
    setState(() => _loadingDocuments[index] = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account & Privacy'.i18n),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Privacy Policy'.i18n),
            Tab(text: 'Cookie Policy'.i18n),
            Tab(text: 'Terms & Conditions'.i18n),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(3, (index) => _buildDocumentView(index)),
      ),
    );
  }

  Widget _buildDocumentView(int index) {
    if (_loadingDocuments[index] == true) {
      return const Center(child: CircularProgressIndicator());
    }

    final content = _cachedDocuments[index];
    if (content == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: LiquidGlass.wrap(
        Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: SelectableText(
              content,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ),
        ),
        context,
      ),
    );
  }
}
