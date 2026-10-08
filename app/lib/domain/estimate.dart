/// Estimation INDICATIVE renvoyée par le serveur (prix moyens en France, euros TTC). Jamais un devis.
class RepairEstimate {
  const RepairEstimate({
    required this.diyFeasibility,
    required this.difficulty,
    this.durationMinutes,
    this.diyCostMin,
    this.diyCostMax,
    this.proCostMin,
    this.proCostMax,
    this.parts = const [],
  });

  /// 0 (à ne pas faire soi-même) à 10 (très simple).
  final int diyFeasibility;

  /// easy | medium | hard
  final String difficulty;
  final int? durationMinutes;
  final int? diyCostMin;
  final int? diyCostMax;
  final int? proCostMin;
  final int? proCostMax;
  final List<EstimatePart> parts;

  static RepairEstimate? maybe(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    try {
      return RepairEstimate(
        diyFeasibility: (raw['diy_feasibility'] as num).toInt().clamp(0, 10),
        difficulty: raw['difficulty'] as String? ?? 'medium',
        durationMinutes: (raw['duration_minutes'] as num?)?.toInt(),
        diyCostMin: (raw['diy_cost_min'] as num?)?.toInt(),
        diyCostMax: (raw['diy_cost_max'] as num?)?.toInt(),
        proCostMin: (raw['pro_cost_min'] as num?)?.toInt(),
        proCostMax: (raw['pro_cost_max'] as num?)?.toInt(),
        parts: [
          for (final p in raw['parts'] as List? ?? const [])
            if (p is Map<String, dynamic> && (p['name'] as String? ?? '').trim().isNotEmpty)
              EstimatePart(name: (p['name'] as String).trim(), approxEur: (p['approx_eur'] as num?)?.toInt()),
        ],
      );
    } catch (_) {
      return null; // une estimation mal formée ne doit jamais casser un diagnostic
    }
  }

  static int? _mid(int? a, int? b) => a == null && b == null ? null : (((a ?? b)! + (b ?? a)!) / 2).round();

  int? get diyMid => _mid(diyCostMin, diyCostMax);
  int? get proMid => _mid(proCostMin, proCostMax);

  /// Économie estimée en réparant soi-même (artisan − soi-même), seulement si les deux coûts sont connus.
  int? get savings {
    final pro = proMid, diy = diyMid ?? 0;
    if (pro == null) return null;
    final s = pro - diy;
    return s > 0 ? s : null;
  }
}

class EstimatePart {
  const EstimatePart({required this.name, this.approxEur});
  final String name;
  final int? approxEur;
}

/// « ~8 € » (bornes proches) ou « 5–12 € ».
String formatEuros(int? min, int? max) {
  if (min == null && max == null) return '—';
  final a = min ?? max!, b = max ?? min!;
  if (a == b || (b - a) <= (a * 0.25)) return '~${((a + b) / 2).round()} €';
  return '$a–$b €';
}

String formatDuration(int minutes) {
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60, m = minutes % 60;
  return m == 0 ? '$h h' : '$h h ${m.toString().padLeft(2, '0')}';
}
