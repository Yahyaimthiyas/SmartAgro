import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CommonImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const CommonImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    Widget imageWidget;
    
    if (imageUrl!.startsWith('data:image')) {
      final base64String = imageUrl!.split(',').last;
      
      return FutureBuilder<Uint8List>(
        future: compute(base64Decode, base64String),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              width: width, height: height,
              child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _buildPlaceholder();
          }
          
          Widget imgWidget = Image.memory(
            snapshot.data!,
            width: width,
            height: height,
            fit: fit,
            cacheWidth: 800, // Forces downscaling during decode to prevent RAM overload
            errorBuilder: (_, __, ___) => _buildPlaceholder(),
          );
          
          if (borderRadius != null) {
            return ClipRRect(borderRadius: borderRadius!, child: imgWidget);
          }
          return imgWidget;
        },
      );
    } 
    // Regular Network Image
    else {
      imageWidget = Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: 600, // Important fix: prevents full-res decoding of massive network images
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }
    return imageWidget;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }
}
