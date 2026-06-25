/// Utility for computing the Indian school academic year (June → April/May),
/// instead of the calendar year (Jan → Dec).
class AcademicYearUtils {
  AcademicYearUtils._();

  /// The month the academic year starts in. Schools generally reopen in June.
  static const int academicYearStartMonth = 6; // June

  /// Returns the current academic year as "YYYY-YYYY", e.g. "2026-2027".
  ///
  /// Logic: if today's month is June or later, the academic year started
  /// this calendar year and ends next year (e.g. June 2026 → "2026-2027").
  /// If today's month is before June (Jan–May), the academic year started
  /// last calendar year and ends this year (e.g. March 2026 → "2025-2026").
  static String getCurrentAcademicYear({DateTime? now}) {
    final date = now ?? DateTime.now();
    final startYear = date.month >= academicYearStartMonth ? date.year : date.year - 1;
    return '$startYear-${startYear + 1}';
  }

  /// Same as [getCurrentAcademicYear] but for an arbitrary date —
  /// useful if you need the academic year a record belongs to,
  /// e.g. for a payment made on a specific date.
  static String getAcademicYearFor(DateTime date) {
    final startYear = date.month >= academicYearStartMonth ? date.year : date.year - 1;
    return '$startYear-${startYear + 1}';
  }

  /// Returns the start year only, as an int (e.g. 2026 for "2026-2027").
  static int getCurrentAcademicYearStart({DateTime? now}) {
    final date = now ?? DateTime.now();
    return date.month >= academicYearStartMonth ? date.year : date.year - 1;
  }

  /// Generates a list of recent academic years for dropdowns, most recent first.
  /// e.g. getRecentAcademicYears(3) → ["2026-2027", "2025-2026", "2024-2025"]
  static List<String> getRecentAcademicYears(int count, {DateTime? now}) {
    final currentStart = getCurrentAcademicYearStart(now: now);
    return List.generate(count, (i) {
      final startYear = currentStart - i;
      return '$startYear-${startYear + 1}';
    });
  }

  /// Validates that a string matches the "YYYY-YYYY" academic year format
  /// with consecutive years (e.g. "2026-2027" is valid, "2026-2028" is not).
  static bool isValidAcademicYear(String value) {
    final match = RegExp(r'^(\d{4})-(\d{4})$').firstMatch(value.trim());
    if (match == null) return false;
    final start = int.parse(match.group(1)!);
    final end = int.parse(match.group(2)!);
    return end == start + 1;
  }
}