import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class CustomeWidghit extends StatelessWidget {
  final String name;
  final String descrption;
  final String image;
  final bool isLoding;
final VoidCallback? onTap; 
  const CustomeWidghit({
    super.key,
    required this.name,
    required this.descrption,
    required this.image,
    required this.isLoding,
     this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
      child: Card(
        elevation: 0.0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: const Color(0xFFFFF8E6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x33D4AF37)),
        ),
        child: Skeletonizer(
          enabled: isLoding,
          child: ListTile(
            onTap: onTap,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            titleAlignment: ListTileTitleAlignment.center,
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFD4AF37),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child:
                    isLoding
                        ? Container(color: Colors.grey[300])
                        : Image.network(
                          image,
                          fit: BoxFit.cover,
                          width: 44,
                          height: 44,
                        ),
              ),
            ),
            trailing: const Icon(Icons.chevron_left, color: Color(0xFF111111)),
            title: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF111111),
              ),
            ),
            subtitle: Text(
              descrption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF4D4D4D)),
            ),
          ),
        ),
      ),
    );
  }
}
