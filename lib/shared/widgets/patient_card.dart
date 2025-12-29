import 'package:flutter/material.dart';

class PatientCard extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final String? subtitle;
  final String? status;
  final Color? statusColor;
  final VoidCallback? onTap;
  final List<Widget>? actions;

  const PatientCard({
    super.key,
    required this.name,
    this.avatarUrl,
    this.subtitle,
    this.status,
    this.statusColor,
    this.onTap,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFA49E86),
                image: avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: avatarUrl == null
                  ? Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'P',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                      fontFamily: 'Inter',
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B6B6B),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (status != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (statusColor ?? const Color(0xFFA49E86)).withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor ?? const Color(0xFFA49E86),
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
            if (actions != null) ...actions!,
            if (onTap != null && actions == null && status == null)
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFCCCCCC),
              ),
          ],
        ),
      ),
    );
  }
}

class PatientListTile extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final String? procedure;
  final String? date;
  final String? time;
  final VoidCallback? onTap;

  const PatientListTile({
    super.key,
    required this.name,
    this.avatarUrl,
    this.procedure,
    this.date,
    this.time,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withAlpha(31),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE8E6E0),
                image: avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: avatarUrl == null
                  ? Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'P',
                        style: const TextStyle(
                          color: Color(0xFF6B6B6B),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                      fontFamily: 'Inter',
                    ),
                  ),
                  if (procedure != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      procedure!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B6B6B),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (date != null || time != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (date != null)
                    Text(
                      date!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A),
                        fontFamily: 'Inter',
                      ),
                    ),
                  if (time != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      time!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B6B6B),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}
