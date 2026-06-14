import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/dio_client.dart';

class ReportScreen extends StatefulWidget {
  final String targetId;
  final String type; // USER, LISTING, CRAFTSMAN, MESSAGE

  const ReportScreen({super.key, required this.targetId, required this.type});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String? _reason;
  final _descCtrl = TextEditingController();
  bool _loading = false;

  static const _reasons = [
    'محتوى مسيء',
    'احتيال أو نصب',
    'معلومات مضللة',
    'محتوى غير لائق',
    'انتهاك الخصوصية',
    'أخرى',
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار سبب البلاغ', style: TextStyle(fontFamily: 'Cairo'))),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await DioClient.instance.post('/reports', data: {
        'targetId': widget.targetId,
        'type': widget.type,
        'reason': _reason,
        if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال البلاغ بنجاح', style: TextStyle(fontFamily: 'Cairo'))),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString(), style: const TextStyle(fontFamily: 'Cairo'))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إرسال بلاغ', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: const Color(0xFF1B4F72),
          foregroundColor: Colors.white,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('سبب البلاغ',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._reasons.map((r) => RadioListTile<String>(
                  title: Text(r, style: const TextStyle(fontFamily: 'Cairo')),
                  value: r,
                  groupValue: _reason,
                  activeColor: const Color(0xFF1B4F72),
                  onChanged: (v) => setState(() => _reason = v),
                )),
            const SizedBox(height: 16),
            const Text('تفاصيل إضافية (اختياري)',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'اكتب تفاصيل البلاغ...',
                hintStyle: const TextStyle(fontFamily: 'Cairo'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('إرسال البلاغ',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
