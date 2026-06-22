// Provider Badge - shows provider logo/initial with brand color
import 'package:flutter/material.dart';

import '../../core/constants/ai_providers.dart';

class ProviderBadge extends StatelessWidget {
  const ProviderBadge({
    super.key,
    required this.provider,
    this.size = ProviderBadgeSize.medium,
    this.showName = false,
  });

  final AIProvider provider;
  final ProviderBadgeSize size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final dimensions = switch (size) {
      ProviderBadgeSize.small => 18.0,
      ProviderBadgeSize.medium => 28.0,
      ProviderBadgeSize.large => 40.0,
      ProviderBadgeSize.xlarge => 64.0,
    };

    final fontSize = switch (size) {
      ProviderBadgeSize.small => 9.0,
      ProviderBadgeSize.medium => 12.0,
      ProviderBadgeSize.large => 16.0,
      ProviderBadgeSize.xlarge => 24.0,
    };

    final iconSize = switch (size) {
      ProviderBadgeSize.small => 10.0,
      ProviderBadgeSize.medium => 14.0,
      ProviderBadgeSize.large => 20.0,
      ProviderBadgeSize.xlarge => 32.0,
    };

    final badge = Container(
      width: dimensions,
      height: dimensions,
      decoration: BoxDecoration(
        color: provider.brandColor,
        borderRadius: BorderRadius.circular(dimensions * 0.25),
        boxShadow: [
          BoxShadow(
            color: provider.brandColor.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: provider.isLocal
            ? Icon(Icons.computer, size: iconSize, color: Colors.white)
            : Text(
                provider.displayName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );

    if (!showName) return badge;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                provider.displayName,
                style: Theme.of(context).textTheme.labelLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                provider.description,
                style: Theme.of(context).textTheme.labelSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum ProviderBadgeSize { small, medium, large, xlarge }
