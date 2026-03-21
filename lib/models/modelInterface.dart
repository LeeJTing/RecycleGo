abstract class IModel<T> {
  /// Fetch all records
  Future<List<T>> getAll();

  /// Insert a record
  Future<void> insert(T entity);

  /// Update a record by id
  Future<void> update(String id, T entity);

  /// Delete a record by id
  Future<void> delete(String id);

  /// Fetch a single record by id
  Future<T?> getById(String id);
}