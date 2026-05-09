import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class CustomeWidghit extends StatefulWidget {
  // حولناها لـ StatefulWidget للتحكم في التوسيع
  final String name;
  final String descrption;
  final String image;
  final String? time;
  final bool isLoding;
  final VoidCallback? onTap;

  const CustomeWidghit({
    super.key,
    required this.name,
    required this.descrption,
    required this.image,
    this.time,
    required this.isLoding,
    this.onTap,
  });

  @override
  State<CustomeWidghit> createState() => _CustomeWidghitState();
}

class _CustomeWidghitState extends State<CustomeWidghit> {
  bool _isExpanded = false; // متغير محلي للتحكم في حالة التوسع

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Card(
        elevation: 0.0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: const Color(0xFFFFF8E6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x33D4AF37)),
        ),
        child: Skeletonizer(
          enabled: widget.isLoding,
          child: InkWell(
            // استخدمنا InkWell لجعل العنصر كاملاً قابلاً للضغط
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded; // عكس الحالة عند الضغط
              });
              if (widget.onTap != null) widget.onTap!();
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. الصورة
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFD4AF37),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child:
                              widget.isLoding
                                  ? Container(color: Colors.grey[300])
                                  : Image.network(
                                    widget.image,
                                    fit: BoxFit.cover,
                                    width: 44,
                                    height: 44,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.person,
                                              color: Colors.white,
                                            ),
                                  ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 2. النصوص (الاسم والوصف المختصر)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111111),
                              ),
                            ),
                            // يظهر الوصف المختصر فقط إذا كان العنصر مغلقاً
                            if (!_isExpanded)
                              Text(
                                widget.descrption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF4D4D4D),
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // 3. الوقت والسهم
                      Column(
                        children: [
                          Text(
                            widget.time ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFD4AF37),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          // سهم يتفاعل مع حالة الفتح والغلق
                          AnimatedRotation(
                            duration: const Duration(milliseconds: 300),
                            turns:
                                _isExpanded ? 0.5 : 0.0, // يلف السهم 180 درجة
                            child: const Icon(
                              Icons.keyboard_arrow_down,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // 4. ميزة التوسع المخصصة
                  AnimatedCrossFade(
                    firstChild: const SizedBox(
                      width: double.infinity,
                    ), // حالة الغلق (فارغ)
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        widget.descrption,
                        style: const TextStyle(
                          color: Color(0xFF4D4D4D),
                          fontSize: 14,
                          height: 1.5, // مسافة بين الأسطر لراحة العين
                        ),
                      ),
                    ),
                    crossFadeState:
                        _isExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
