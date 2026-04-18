import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/theme.dart';

// ── Currency formatter ────────────────────────────────────────────────────────
String formatCurrency(double amount, {String currency = 'IDR'}) {
  final fmt = NumberFormat.currency(
    locale: 'id_ID', symbol: currency == 'IDR' ? 'Rp ' : '$currency ',
    decimalDigits: 0,
  );
  return fmt.format(amount.abs());
}

String formatDate(String dateStr, {String pattern = 'd MMM yyyy'}) {
  try {
    final dt = DateTime.parse(dateStr);
    return DateFormat(pattern, 'id_ID').format(dt);
  } catch (_) {
    return dateStr;
  }
}

// ── Gradient copper ───────────────────────────────────────────────────────────
const kCopperGradient = LinearGradient(
  begin: Alignment.topLeft,
  end:   Alignment.bottomRight,
  colors: [FinaColors.copper, FinaColors.copper2],
);

// ─────────────────────────────────────────────────────────────────────────────
// FinaCard
// ─────────────────────────────────────────────────────────────────────────────
class FinaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double radius;
  final bool copper; // copper-tinted card

  const FinaCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.radius = 20,
    this.copper = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: copper
            ? const Color(0x12C8783A)
            : (color ?? FinaColors.surface),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: copper
              ? const Color(0x2EC8783A)
              : FinaColors.border,
        ),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IconCircle
// ─────────────────────────────────────────────────────────────────────────────
class IconCircle extends StatelessWidget {
  final String emoji;
  final Color bgColor;
  final double size;

  const IconCircle({
    super.key,
    required this.emoji,
    this.bgColor = FinaColors.icCopper,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      color: bgColor, borderRadius: BorderRadius.circular(size * 0.33),
    ),
    alignment: Alignment.center,
    child: Text(emoji, style: TextStyle(fontSize: size * 0.44)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// FinaPill
// ─────────────────────────────────────────────────────────────────────────────
enum PillVariant { green, red, copper, blue }

class FinaPill extends StatelessWidget {
  final String label;
  final PillVariant variant;
  final String? prefix;

  const FinaPill(this.label, {super.key, this.variant = PillVariant.copper, this.prefix});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (variant) {
      PillVariant.green  => (FinaColors.pillGreen,  FinaColors.green),
      PillVariant.red    => (FinaColors.pillRed,    FinaColors.red),
      PillVariant.copper => (FinaColors.pillCopper, FinaColors.copper2),
      PillVariant.blue   => (FinaColors.pillBlue,   FinaColors.blue),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        prefix != null ? '$prefix $label' : label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ProgressBar
// ─────────────────────────────────────────────────────────────────────────────
class FinaProgressBar extends StatelessWidget {
  final double progress; // 0.0 – 1.0
  final bool danger;

  const FinaProgressBar({super.key, required this.progress, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? const LinearGradient(colors: [Color(0xFFA03030), FinaColors.red])
        : kCopperGradient;

    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: FinaColors.surface2, borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0, 1),
        child: Container(
          decoration: BoxDecoration(
            gradient: color, borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FinaDivider
// ─────────────────────────────────────────────────────────────────────────────
class FinaDivider extends StatelessWidget {
  final double indent;
  const FinaDivider({super.key, this.indent = 0});

  @override
  Widget build(BuildContext context) => Divider(
    height: 1, thickness: 1, color: FinaColors.border,
    indent: indent, endIndent: 0,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// FinaButton
// ─────────────────────────────────────────────────────────────────────────────
class FinaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outline;
  final Widget? icon;

  const FinaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.outline = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (outline) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: icon ?? const SizedBox.shrink(),
          label: Text(label),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 18, width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[icon!, const SizedBox(width: 8)],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Amount widget — warna sesuai tipe
// ─────────────────────────────────────────────────────────────────────────────
class AmountText extends StatelessWidget {
  final double amount;
  final String type; // income | expense | transfer
  final double fontSize;
  final FontWeight fontWeight;

  const AmountText({
    super.key,
    required this.amount,
    required this.type,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    final (prefix, color) = switch (type) {
      'income'   => ('+', FinaColors.green),
      'expense'  => ('-', FinaColors.red),
      _          => ('', FinaColors.blue),
    };
    return Text(
      '$prefix${formatCurrency(amount)}',
      style: TextStyle(
        fontSize: fontSize, fontWeight: fontWeight, color: color,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────
class FinaEmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;
  final Widget? action;

  const FinaEmptyState({
    super.key,
    required this.emoji,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading skeleton shimmer-like
// ─────────────────────────────────────────────────────────────────────────────
class FinaSkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const FinaSkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: FinaColors.surface2,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom nav
// ─────────────────────────────────────────────────────────────────────────────
class FinaBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FinaBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    (icon: '🏠', label: 'Beranda'),
    (icon: '💳', label: 'Transaksi'),
    (icon: '📊', label: 'Budget'),
    (icon: '📈', label: 'Laporan'),
    (icon: '👤', label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xE60D0F14),
        border: Border(top: BorderSide(color: FinaColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(_items.length, (i) {
            final item = _items[i];
            final isActive = i == currentIndex;
            return Expanded(
              child: InkWell(
                onTap: () => onTap(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.icon,
                        style: TextStyle(
                          fontSize: 20,
                          color: isActive ? FinaColors.copper : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: isActive ? FinaColors.copper : FinaColors.text2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error widget
// ─────────────────────────────────────────────────────────────────────────────
class FinaErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const FinaErrorWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) => FinaEmptyState(
    emoji: '⚠️',
    title: 'Gagal memuat data',
    subtitle: message,
    action: onRetry != null
        ? FinaButton(label: 'Coba lagi', onPressed: onRetry)
        : null,
  );
}
