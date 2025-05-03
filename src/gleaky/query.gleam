import gleam/list

import gleaky.{type SQLValue, type Table}
import gleaky/where.{type Where, NoWhere}

pub type SQLCondition(table) {
  Equals(SQLValue(table))
  NotEquals(SQLValue(table))
  GreaterThan(SQLValue(table))
  LessThan(SQLValue(table))
  GreaterThanOrEquals(SQLValue(table))
  LessThanOrEquals(SQLValue(table))
  In(List(SQLValue(table)))
  NotIn(List(SQLValue(table)))
  Like(SQLValue(table))
  NotLike(SQLValue(table))
}

/// Indicates whether a query is valid. Validity is checked based in the data
/// types of table columns, and if referred columns exist in the scope of the
/// query.
pub opaque type ValidQuery {
  /// The query has not been checked for validity. This is the default while the
  /// query is being built, as the table definitions are not available to the dsl
  /// for API simplicity.
  NotChecked
  /// The query has been checked for validity and no issues has been found as
  /// far as the table definitions are concerned. Still, if the underlying data
  /// does not match the table definitions, chance of runtime errors exist.
  ValidQuery
  /// The query has been checked for validity and issues have been found. The
  /// user can choose to ignore issues and execute the query anyway. You can also
  /// create a module to run for checking if all the queries are valid as a CI
  /// check.
  InvalidQuery(reason: String)
}

pub type Query(table) {
  Query(
    tables: List(Table(table)),
    select: List(table),
    joins: List(Join(table)),
    where: Where(table),
    invalid: ValidQuery,
  )
}

pub type Join(table) {
  Join(
    table: Table(table),
    on: Where(table),
    and: List(#(SQLValue(table), SQLCondition(table))),
  )
}

pub fn query(table: Table(table)) -> Query(table) {
  Query(
    tables: [table],
    select: [],
    joins: [],
    where: NoWhere,
    invalid: NotChecked,
  )
}

pub fn select(
  query: Query(table),
  from from: fn(column) -> table,
  columns columns: List(column),
) -> Query(table) {
  Query(..query, select: list.append(list.map(columns, from), query.select))
}

pub fn select_columns(query: Query(table), columns: List(table)) -> Query(table) {
  Query(..query, select: list.append(columns, query.select))
}

pub fn join(
  query: Query(table),
  table table: Table(table),
  on on: Where(table),
) -> Query(table) {
  Query(..query, tables: [table, ..query.tables], joins: [
    Join(table:, on:, and: []),
    ..query.joins
  ])
}

pub fn where(query: Query(table), where where: Where(table)) -> Query(table) {
  case query.where {
    NoWhere -> Query(..query, where: where)
    where.WhereAnd(wheres) ->
      Query(..query, where: where.WhereAnd([where, ..wheres]))
    current_where ->
      Query(..query, where: where.WhereAnd([current_where, where]))
  }
}
