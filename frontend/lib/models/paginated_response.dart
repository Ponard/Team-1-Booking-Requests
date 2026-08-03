class PaginatedResponse<T> {
  final List<T> items;
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;

  const PaginatedResponse({
    required this.items,
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
  });
}
