import 'package:flutter/material.dart';

class CustomSliver extends StatefulWidget {
  final String name;
  final String descrption;
  final String image;
  final bool compact;
  final String? time;

  const CustomSliver({
    super.key,
    required this.name,
    required this.descrption,
    required this.image,
    this.compact = false,
    this.time,
  });

  @override
  State<CustomSliver> createState() => _CustomSliverState();
}

class _CustomSliverState extends State<CustomSliver> {
  @override
  Widget build(BuildContext context) {
    // استخدام Directionality لضمان الترتيب من اليمين لليسار
    if (widget.compact) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // مصغر للأفاتار داخل الشريط المرن
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD4AF37),
                    width: 1.2,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    widget.image,
                    fit: BoxFit.cover,
                    width: 40,
                    height: 40,
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          color: const Color(0xFFD4AF37),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D2D2D),
                        fontFamily: 'Cairo',
                      ),
                    ),
                    if (widget.descrption.isNotEmpty)
                      Text(
                        widget.descrption,
                        // maxLines: 1,
                        //overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4A4A4A),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          // تدرج لوني يبدأ من جهة القراءة (اليمين)
          gradient: const LinearGradient(
            colors: [Color(0xFFD4AF37), Color(0xFFFFFDF5)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4AF37).withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(
                -2,
                5,
              ), // إزاحة الظل بما يتناسب مع اتجاه العين
            ),
          ],
          border: Border.all(
            color: const Color(0xFFD4AF37).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
           
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD4AF37), width: 1.6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.network(
                  widget.image,
                  fit: BoxFit.cover,
                  width: 56,
                  height: 56,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        color: const Color(0xFFD4AF37),
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                ),
              ),
            ),
            title: Text(
              widget.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF2D2D2D),
                fontFamily: 'Cairo',
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                widget.descrption,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF4A4A4A),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            // الوقت والأيقونة تظهر في الطرف المقابل بشكل متناسق
            trailing:
                widget.time != null
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          widget.time!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFD4AF37),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: Color(0xFF2D2D2D),
                        ),
                      ],
                    )
                    : null,
          ),
        ),
      ),
    );
  }
}
