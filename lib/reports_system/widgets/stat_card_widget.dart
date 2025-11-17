import 'package:flutter/material.dart';

/// Widget لبطاقة الإحصائيات
class StatCardWidget extends StatelessWidget {
  const StatCardWidget({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.color = Colors.blue,
    this.trend,
    this.trendValue,
    this.onTap,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color color;
  final TrendDirection? trend;
  final String? trendValue;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // العنوان والأيقونة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (icon != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 20,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // القيمة
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),

              // العنوان الفرعي والاتجاه
              if (subtitle != null || trend != null) ...<Widget>[
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    if (subtitle != null)
                      Expanded(
                        child: Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    if (trend != null) ...<Widget>[
                      const SizedBox(width: 8),
                      _buildTrendIndicator(),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );

  Widget _buildTrendIndicator() {
    if (trend == null) return const SizedBox.shrink();

    Color trendColor;
    IconData trendIcon;

    switch (trend!) {
      case TrendDirection.up:
        trendColor = Colors.green;
        trendIcon = Icons.trending_up;
        break;
      case TrendDirection.down:
        trendColor = Colors.red;
        trendIcon = Icons.trending_down;
        break;
      case TrendDirection.stable:
        trendColor = Colors.grey;
        trendIcon = Icons.trending_flat;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          trendIcon,
          size: 16,
          color: trendColor,
        ),
        if (trendValue != null) ...<Widget>[
          const SizedBox(width: 4),
          Text(
            trendValue!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: trendColor,
            ),
          ),
        ],
      ],
    );
  }
}

/// اتجاه الاتجاه
enum TrendDirection {
  up,
  down,
  stable,
}
