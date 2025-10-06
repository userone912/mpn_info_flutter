import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/services/settings_service.dart';
import '../core/constants/app_constants.dart';

/// Office Configuration Dialog
/// Allows users to set the office code for import operations
class OfficeConfigDialog extends StatefulWidget {
  const OfficeConfigDialog({super.key});

  @override
  State<OfficeConfigDialog> createState() => _OfficeConfigDialogState();
}

class _OfficeConfigDialogState extends State<OfficeConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  final _officeCodeController = TextEditingController();
  final _officeNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  @override
  void dispose() {
    _officeCodeController.dispose();
    _officeNameController.dispose();
    super.dispose();
  }

  void _loadCurrentConfig() {
    final officeCode = SettingsService.getSetting(AppConstants.kantorKodeKey, '');
    final officeName = SettingsService.getSetting('kantor.nama', '');
    
    _officeCodeController.text = officeCode;
    _officeNameController.text = officeName;
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await SettingsService.setSetting(AppConstants.kantorKodeKey, _officeCodeController.text.trim().toUpperCase());
      await SettingsService.setSetting('kantor.nama', _officeNameController.text.trim());

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konfigurasi kantor berhasil disimpan'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error menyimpan konfigurasi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.business, color: Colors.blue),
          SizedBox(width: 8),
          Text('Konfigurasi Kantor'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Silakan atur kode kantor 3 digit sebelum melakukan import data.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _officeCodeController,
                decoration: const InputDecoration(
                  labelText: 'Kode Kantor',
                  hintText: 'Contoh: 907, 001, 123',
                  border: OutlineInputBorder(),
                  helperText: 'Kode kantor 3 digit (huruf/angka)',
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(3),
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                ],
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Kode kantor tidak boleh kosong';
                  }
                  if (value.trim().length != 3) {
                    return 'Kode kantor harus 3 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _officeNameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Kantor (Opsional)',
                  hintText: 'Contoh: KPP Pratama Jakarta Pusat',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveConfig,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}