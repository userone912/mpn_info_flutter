import 'package:flutter/material.dart';
import '../../data/models/office_settings_model.dart';
import '../../data/services/setting_data_service.dart';
import '../../data/services/reference_data_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OfficeConfigDialog extends ConsumerStatefulWidget {
  const OfficeConfigDialog({Key? key}) : super(key: key);

  @override
  ConsumerState<OfficeConfigDialog> createState() => _OfficeConfigDialogState();
}

class _OfficeConfigDialogState extends ConsumerState<OfficeConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;
  OfficeSettingsModel? _settings;

  String? _selectedKanwil;
  String? _selectedKpp;
  List<Map<String, String>> _kanwilList = [];
  List<Map<String, String>> _kppList = [];
  late ReferenceDataService _referenceService;

  final TextEditingController _wpjController = TextEditingController();
  final TextEditingController _kpController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _teleponController = TextEditingController();
  final TextEditingController _kotaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _referenceService = ref.read(referenceDataServiceProvider);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    final settingService = ref.read(settingDataServiceProvider);
    _kanwilList = _referenceService.kanwilList;
    final settings = await settingService.fetchOfficeSettings();
    _settings = settings;
    _wpjController.text = settings.wpj;
    _kpController.text = settings.kp;
    _alamatController.text = settings.alamat;
    _teleponController.text = settings.telepon;
    _kotaController.text = settings.kota;

    // Preselect Kanwil and KPP only if there is a saved setting
    if (_kanwilList.isNotEmpty && settings.kode.isNotEmpty) {
      final kodeKantor = settings.kode;
      String? foundKanwil;
      String? foundKpp;
      List<Map<String, String>> kppList = [];
      for (final kanwil in _kanwilList) {
        kppList = await _referenceService.loadKppListForKanwil(kanwil['value']!);
        for (final kpp in kppList) {
          if (kpp['value'] == kodeKantor) {
            foundKanwil = kanwil['value'];
            foundKpp = kpp['value'];
            break;
          }
        }
        if (foundKanwil != null) break;
      }
      _selectedKanwil = foundKanwil;
      _kppList = foundKanwil != null ? await _referenceService.loadKppListForKanwil(foundKanwil) : [];
      _selectedKpp = foundKpp;
    } else {
      _selectedKanwil = null;
      _kppList = [];
      _selectedKpp = null;
    }
    setState(() => _loading = false);
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedKpp == null) return;
    setState(() => _saving = true);
    final service = ref.read(settingDataServiceProvider);
    final newSettings = OfficeSettingsModel(
      kode: _selectedKpp!,
      wpj: _wpjController.text.trim(),
      kp: _kpController.text.trim(),
      alamat: _alamatController.text.trim(),
      telepon: _teleponController.text.trim(),
      kota: _kotaController.text.trim(),
    );
    await service.updateOfficeSettings(newSettings);
    setState(() => _saving = false);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan kantor berhasil disimpan.'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Pengaturan Kantor', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    // Kanwil Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedKanwil,
                      decoration: const InputDecoration(
                        labelText: 'Kanwil',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: _kanwilList.map((item) => DropdownMenuItem(
                        value: item['value'],
                        child: Text(item['label'] ?? ''),
                      )).toList(),
                      onChanged: (value) async {
                        print('[OfficeConfigDialog] Kanwil selected: $value');
                        if (value != null && value.isNotEmpty) {
                          final kppList = await _referenceService.loadKppListForKanwil(value);
                          print('[OfficeConfigDialog] KPP list for Kanwil $value:');
                          for (final kpp in kppList) {
                            print('  value: ${kpp['value']}, label: ${kpp['label']}');
                          }
                          Map<String, String> firstKppMap = kppList.firstWhere(
                            (kpp) => kpp['value'] != '000',
                            orElse: () => kppList.isNotEmpty ? kppList.first : <String, String>{},
                          );
                          String? firstKpp = firstKppMap.isNotEmpty ? firstKppMap['value'] : null;
                          setState(() {
                            _selectedKanwil = value;
                            _kppList = kppList;
                            _selectedKpp = firstKpp;
                          });
                        } else {
                          setState(() {
                            _selectedKanwil = value;
                            _kppList = [];
                            _selectedKpp = null;
                          });
                        }
                      },
                      validator: (value) => value == null || value.isEmpty ? 'Wajib pilih Kanwil' : null,
                    ),
                    const SizedBox(height: 12),
                    // KPP Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedKpp,
                      decoration: const InputDecoration(
                        labelText: 'Kode KPP',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        if (_kppList.isEmpty)
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Pilih Kanwil terlebih dahulu', style: TextStyle(color: Colors.grey)),
                          ),
                        ..._kppList.map((item) => DropdownMenuItem(
                          value: item['value'],
                          child: Text(item['label'] ?? ''),
                        ))
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedKpp = value;
                        });
                      },
                      validator: (value) => value == null || value.isEmpty ? 'Wajib pilih KPP' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(_wpjController, 'WPJ', false),
                    _buildTextField(_kpController, 'KP', false),
                    _buildTextField(_alamatController, 'Alamat', false),
                    _buildTextField(_teleponController, 'Telepon', false),
                    _buildTextField(_kotaController, 'Kota', false),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveSettings,
                        child: _saving
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }

  Widget _buildTextField(TextEditingController controller, String label, bool required) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        validator: required
            ? (value) => value == null || value.trim().isEmpty ? 'Wajib diisi' : null
            : null,
      ),
    );
  }
}
