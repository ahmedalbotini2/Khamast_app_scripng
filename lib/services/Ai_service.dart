import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class GeminiAiService {
  final Gemini _gemini = Gemini.instance;

  // متغير لتخزين النتيجة النهائية
  String _outPut = '';

  /// الدالة الرئيسية للمعالجة والعمليات
  /// [prompt]: هو التعليمات (مثلاً: حلل هذه النبذة)
  /// [value]: هي القيمة المراد تحليلها (مثلاً: نص النبذة الشخصية)
  /// [modelName]: اختيار الموديل (افتراضياً gemini-1.5-flash لتوفير التوكن والسرعة)
  Future<void> analyze({
    required String prompt,
    required String? value,
    String modelName = 'gemini-1.5-flash',
  }) async {
    
    // 1. منطق التوفير: إذا كانت القيمة فارغة، لا تنفذ العملية
    if (value == null || value.trim().isEmpty || value.length < 5) {
      _outPut = "القيمة المقدمة فارغة جداً، لا يمكن تحليلها.";
      debugPrint("تم إلغاء الطلب لتوفير التوكنز: القيمة فارغة.");
      return;
    }

    try {
      // 2. دمج البرومت مع القيمة
      final String fullPrompt = "$prompt \n\n القيمة المراد تحليلها: \n $value";


      final response = await _gemini.text(fullPrompt);

      // 4. تخزين النتيجة
      _outPut = response?.output ?? "لم يتم إرجاع نتيجة من الذكاء الاصطناعي.";
      
    } catch (e) {
      _outPut = "حدث خطأ أثناء الاتصال بالذكاء الاصطناعي: $e";
      debugPrint(_outPut);
    }
  }

  /// دالة لاستخراج النتيجة
  String getOutput() {
    return _outPut;
  }
}