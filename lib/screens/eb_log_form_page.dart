import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:school_app/controllers/eb_controller.dart';

class EBLogFormScreen extends StatefulWidget {
  final String schoolId;
  final Map<String, dynamic>? existingLog;

  const EBLogFormScreen({
    super.key,
    required this.schoolId,
    this.existingLog,
  });

  @override
  State<EBLogFormScreen> createState() => _EBLogFormScreenState();
}

class _EBLogFormScreenState extends State<EBLogFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final EBController ebController = Get.put(EBController());

  String? _selectedPremisesId;
  final TextEditingController _meterReadingController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  bool get _isEditing => widget.existingLog != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPremisesAndPopulate();
    });
  }

  Future<void> _loadPremisesAndPopulate() async {
    // 1. Check if schoolId is valid before making API call
    if (widget.schoolId.isNotEmpty && ebController.premisesList.isEmpty) {
      try {
        await ebController.getAllPremises(widget.schoolId);
      } catch (_) {
        // Silently catch or handle locally without blocking form UI
      }
    }

    // 2. Populate form if in Edit Mode...
    if (_isEditing) {
      final log = widget.existingLog!;
      final premisesRaw = log['premisesId'];
      if (premisesRaw is Map) {
        _selectedPremisesId = (premisesRaw['_id'] ?? premisesRaw['id'])?.toString();
      } else if (premisesRaw != null) {
        _selectedPremisesId = premisesRaw.toString();
      }

      if (log['meterReading'] != null) {
        _meterReadingController.text = log['meterReading'].toString();
      }
      if (log['note'] != null) {
        _notesController.text = log['note'].toString();
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _meterReadingController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPremisesId == null) {
      Get.snackbar(
        'Required',
        'Please select a premises',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final formattedDate = _selectedDate.toIso8601String();
    final formattedTime =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    final payload = {
      'premisesId': _selectedPremisesId,
      'meterReading': num.tryParse(_meterReadingController.text.trim()) ?? 0,
      'date': formattedDate,
      'time': formattedTime,
      'note': _notesController.text.trim(),
    };

    bool success;
    if (_isEditing) {
      final logId = (widget.existingLog!['_id'] ?? widget.existingLog!['id']).toString();
      success = await ebController.updateEBLog(widget.schoolId, logId, payload);
    } else {
      success = await ebController.createEBLog(widget.schoolId, payload);
    }

    if (success) {
      Get.back(result: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd-MM-yyyy').format(_selectedDate);
    final timeStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          _isEditing ? 'Edit EB Reading' : 'Record EB Reading',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Get.back(),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.domain, size: 18, color: Colors.grey.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Premises & Reading',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),

                            // Row with premises dropdown & reading input
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'PREMISES',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Obx(() {
                                        final list = ebController.premisesList;
                                        return DropdownButtonFormField<String>(
                                          isExpanded: true, // Prevents text overflow
                                          value: _selectedPremisesId,
                                          style: const TextStyle(fontSize: 12, color: Colors.black),
                                          icon: const Icon(Icons.arrow_drop_down, size: 20),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                            prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
                                            prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 0),
                                            hintText: 'Select Premises',
                                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(color: Colors.grey.shade300),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(color: Colors.grey.shade300),
                                            ),
                                          ),
                                          items: list.map((p) {
                                            final id = (p['_id'] ?? p['id']).toString();
                                            final name = (p['premisesName'] ?? 'Unnamed').toString();
                                            return DropdownMenuItem<String>(
                                              value: id,
                                              child: Text(
                                                name,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (val) => setState(() => _selectedPremisesId = val),
                                          validator: (val) => val == null ? 'Select' : null,
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'METER READING (KWH) *',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade600,
                                          letterSpacing: 0.5,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _meterReadingController,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(fontSize: 12),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          hintText: 'e.g. 14500',
                                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                        ),
                                        validator: (val) {
                                          if (val == null || val.trim().isEmpty) {
                                            return 'Required';
                                          }
                                          if (num.tryParse(val.trim()) == null) {
                                            return 'Invalid';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Date & Time pickers
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'READING DATE',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      InkWell(
                                        onTap: _pickDate,
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(dateStr, style: const TextStyle(fontSize: 12)),
                                              Icon(Icons.calendar_today_outlined, size: 15, color: Colors.grey.shade600),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'READING TIME',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      InkWell(
                                        onTap: _pickTime,
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(timeStr, style: const TextStyle(fontSize: 12)),
                                              Icon(Icons.access_time, size: 15, color: Colors.grey.shade600),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Notes section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NOTES / OBSERVATIONS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _notesController,
                              maxLines: 4,
                              style: const TextStyle(fontSize: 12),
                              decoration: InputDecoration(
                                hintText: 'Any observations regarding this reading...',
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.all(10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Actions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Close', style: TextStyle(color: Colors.black87, fontSize: 13)),
                    ),
                    const SizedBox(width: 10),
                    Obx(() {
                      final loading = ebController.isLoading.value;
                      return ElevatedButton(
                        onPressed: loading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF323B4A),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: loading
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                            : Text(
                          _isEditing ? 'Update Reading' : 'Record Reading',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}