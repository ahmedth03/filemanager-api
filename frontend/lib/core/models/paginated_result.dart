class PaginatedResult<T> {
  final List<T> data;
  final PaginatedMeta meta;

  const PaginatedResult({required this.data, required this.meta});
}

class PaginatedMeta {
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPrevPage;

  const PaginatedMeta({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPrevPage,
  });

  factory PaginatedMeta.fromJson(Map<String, dynamic> json) => PaginatedMeta(
        total: json['total'] ?? 0,
        page: json['page'] ?? 1,
        limit: json['limit'] ?? 20,
        totalPages: json['totalPages'] ?? 1,
        hasNextPage: json['hasNextPage'] ?? false,
        hasPrevPage: json['hasPrevPage'] ?? false,
      );

  factory PaginatedMeta.empty() => const PaginatedMeta(
        total: 0,
        page: 1,
        limit: 20,
        totalPages: 1,
        hasNextPage: false,
        hasPrevPage: false,
      );
}
