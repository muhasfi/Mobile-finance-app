import 'package:flutter/material.dart';

class BootstrapIconMapper {
  static final Map<String, IconData> _map = {
    // ── Makanan
    'bi-cup-hot': Icons.local_cafe,

    // ── Belanja
    'bi-bag': Icons.shopping_bag,

    // ── Transport
    'bi-car-front': Icons.directions_car,
    'bi-fuel-pump': Icons.local_gas_station,
    'bi-phone': Icons.phone_android,
    'bi-p-square': Icons.local_parking,
    'bi-wrench': Icons.build,

    // ── Tagihan
    'bi-lightning': Icons.flash_on,
    'bi-droplet': Icons.water_drop,
    'bi-wifi': Icons.wifi,
    'bi-play-circle': Icons.play_circle,

    // ── Kesehatan
    'bi-heart-pulse': Icons.monitor_heart,
    'bi-hospital': Icons.local_hospital,
    'bi-capsule': Icons.medication,
    'bi-trophy': Icons.emoji_events,

    // ── Pendidikan
    'bi-book': Icons.book,
    'bi-mortarboard': Icons.school,

    // ── Hiburan
    'bi-film': Icons.movie,
    'bi-controller': Icons.sports_esports,
    'bi-map': Icons.map,

    // ── Rumah
    'bi-house': Icons.home,
    'bi-tools': Icons.handyman,

    // ── Sosial
    'bi-people': Icons.people,
    'bi-gift': Icons.card_giftcard,
    'bi-heart': Icons.favorite,

    // ── Income
    'bi-cash-stack': Icons.account_balance_wallet,
    'bi-cash': Icons.attach_money,
    'bi-clock': Icons.access_time,
    'bi-briefcase': Icons.work,
    'bi-bag-check': Icons.shopping_cart_checkout,

    // ── Default
    'bi-three-dots': Icons.more_horiz,
  };

  static IconData get(String? icon) {
    if (icon == null) return Icons.category;
    return _map[icon] ?? Icons.category;
  }
}
