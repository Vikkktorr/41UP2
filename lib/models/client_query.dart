import '../core/query_params.dart';

/// Условия отбора списка клиентов.
class ClientQuery {
  final String search;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  static const sortFields = {'name', 'registeredAt', 'discount'};
  static const defaultSort = 'name';

  const ClientQuery({
    this.search = '',
    this.sortField = defaultSort,
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  bool get hasFilters => search.isNotEmpty;

  ClientQuery copyWith({
    String? search,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return ClientQuery(
      search: search ?? this.search,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  ClientQuery cleared() => copyWith(search: '');

  ClientQuery sortedBy(String field) => copyWith(
    sortField: field,
    sortAscending: field == sortField ? !sortAscending : true,
  );

  Map<String, String> toQueryParameters() => {
    if (search.isNotEmpty) 'search': search,
    if (sortField != defaultSort || !sortAscending)
      'sort': formatSort(sortField, sortAscending),
    if (page != 1) 'page': '$page',
    if (size != pageSizes.first) 'size': '$size',
    if (includeDeleted) 'deleted': '1',
  };

  factory ClientQuery.fromQueryParameters(Map<String, String> params) {
    final sort = parseSort(
      params['sort'],
      allowed: sortFields,
      fallbackField: defaultSort,
    );
    return ClientQuery(
      search: params['search']?.trim() ?? '',
      sortField: sort.field,
      sortAscending: sort.ascending,
      page: parsePage(params['page']),
      size: parsePageSize(params['size']),
      includeDeleted: parseFlag(params['deleted']),
    );
  }

  String toLocation() {
    final params = toQueryParameters();
    return Uri(
      path: '/clients',
      queryParameters: params.isEmpty ? null : params,
    ).toString();
  }

  @override
  bool operator ==(Object other) =>
      other is ClientQuery &&
      other.search == search &&
      other.sortField == sortField &&
      other.sortAscending == sortAscending &&
      other.page == page &&
      other.size == size &&
      other.includeDeleted == includeDeleted;

  @override
  int get hashCode =>
      Object.hash(search, sortField, sortAscending, page, size, includeDeleted);
}
