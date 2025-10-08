import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
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
  // Use raw settings map instead of OfficeSettingsModel

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
    _kanwilList = _referenceService.kanwilList;
    final settingService = ref.read(settingDataServiceProvider);
    settingService.prepareOfficeSettingsTableAndFetchValues().then((result) async {
      final map = { for (var row in result) row['key']: row['value'] };
      print('[OfficeConfigDialog] Settings table raw result:');
      for (final row in result) {
        print('  key: ${row['key']}, value: ${row['value']}');
      }
  setState(() => _loading = true);
  print('[OfficeConfigDialog] AppConstants.kantorWpjKey: ${AppConstants.kantorWpjKey}');
  print('[OfficeConfigDialog] AppConstants.kantorKpKey: ${AppConstants.kantorKpKey}');
  print('[OfficeConfigDialog] AppConstants.kantorAlamatKey: ${AppConstants.kantorAlamatKey}');
  print('[OfficeConfigDialog] AppConstants.kantorTeleponKey: ${AppConstants.kantorTeleponKey}');
  print('[OfficeConfigDialog] AppConstants.kantorKotaKey: ${AppConstants.kantorKotaKey}');
  print('[OfficeConfigDialog] AppConstants.kantorKodeKey: ${AppConstants.kantorKodeKey}');

  // Use actual key strings matching the settings table
  _wpjController.text = settingService.safeString(map['kantor.wpj']);
  print('[OfficeConfigDialog] Assigned _wpjController.text: ${_wpjController.text}');
  _kpController.text = settingService.safeString(map['kantor.kp']);
  print('[OfficeConfigDialog] Assigned _kpController.text: ${_kpController.text}');
  _alamatController.text = settingService.safeString(map['kantor.alamat']);
  print('[OfficeConfigDialog] Assigned _alamatController.text: ${_alamatController.text}');
  _teleponController.text = settingService.safeString(map['kantor.telepon']);
  print('[OfficeConfigDialog] Assigned _teleponController.text: ${_teleponController.text}');
  _kotaController.text = settingService.safeString(map['kantor.kota']);
  print('[OfficeConfigDialog] Assigned _kotaController.text: ${_kotaController.text}');
  // Preselect Kanwil and KPP based on saved kode value
  String? kode = settingService.safeString(map['kantor.kode']);
  print('[OfficeConfigDialog] kode for dropdown: $kode');
      String? foundKanwil;
      String? foundKpp;
      List<Map<String, String>> kppList = [];
      if (_kanwilList.isNotEmpty && kode.isNotEmpty) {
        for (final kanwil in _kanwilList) {
          kppList = await _referenceService.loadKppListForKanwil(kanwil['value']!);
          for (final kpp in kppList) {
            if (kpp['value'] == kode) {
              foundKanwil = kanwil['value'];
              foundKpp = kpp['value'];
              break;
            }
          }
          if (foundKanwil != null) break;
        }
      }
      _selectedKanwil = foundKanwil;
      print('[OfficeConfigDialog] Assigned _selectedKanwil: $_selectedKanwil');
      _kppList = foundKanwil != null ? await _referenceService.loadKppListForKanwil(foundKanwil) : [];
      print('[OfficeConfigDialog] Assigned _kppList: ${_kppList.map((k) => k['value']).toList()}');
      _selectedKpp = foundKpp;
      print('[OfficeConfigDialog] Assigned _selectedKpp: $_selectedKpp');
      setState(() => _loading = false);
    });
  }

  // Removed unused _loadSettingsWithModel
  Future<void> _saveSettings() async {
    print('[OfficeConfigDialog] Save pressed');
    print('[OfficeConfigDialog] _selectedKanwil: $_selectedKanwil');
    print('[OfficeConfigDialog] _selectedKpp: $_selectedKpp');
    print('[OfficeConfigDialog] WPJ: ${_wpjController.text}');
    print('[OfficeConfigDialog] KP: ${_kpController.text}');
    print('[OfficeConfigDialog] Alamat: ${_alamatController.text}');
    print('[OfficeConfigDialog] Telepon: ${_teleponController.text}');
    print('[OfficeConfigDialog] Kota: ${_kotaController.text}');
    if (_selectedKpp == null) {
      print('[OfficeConfigDialog] ERROR: _selectedKpp is null');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan pilih KPP terlebih dahulu.'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedKpp == null) {
      print('[OfficeConfigDialog] ERROR: _selectedKpp is null');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan pilih KPP terlebih dahulu.'), backgroundColor: Colors.red),
        );
      }
      return;
    }
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
    print('[OfficeConfigDialog] Saving OfficeSettingsModel: $newSettings');
    await service.updateOfficeSettings(newSettings);
    setState(() => _saving = false);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan kantor berhasil disimpan.'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    }
  }

  // Removed duplicate _buildTextField method

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Stack(
                    children: [
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: 'Tutup',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                'Pengaturan Kantor',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Kanwil Dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedKanwil,
                              isExpanded: true,
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
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Wajib pilih Kanwil';
                                if (!_kanwilList.any((item) => item['value'] == value)) return 'Kanwil tidak valid';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            // KPP Dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedKpp,
                              isExpanded: true,
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
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Wajib pilih KPP';
                                if (!_kppList.any((item) => item['value'] == value)) return 'KPP tidak valid';
                                return null;
                              },
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
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.save),
                                onPressed: _saving ? null : _saveSettings,
                                label: _saving
                                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Text('Simpan'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
