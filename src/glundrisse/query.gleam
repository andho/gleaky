import gleam/list
import gleam/string

import glundrisse.{type Table}
import glundrisse/table
import glundrisse/table/column

pub type SQLValue(table) {
  ColumnValue(table)
  StringValue(String)
  IntValue(Int)
}

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

pub opaque type ValidQuery {
  ValidQuery
  InvalidQuery(reason: String)
}

pub type Query(table) {
  Query(
    tables: List(Table(table)),
    select: List(table),
    joins: List(Join(table)),
    where: List(#(SQLValue(table), SQLCondition(table))),
    invalid: ValidQuery,
  )
}

pub type Join(table) {
  Join(
    table: Table(table),
    on: #(SQLValue(table), SQLCondition(table)),
    and: List(#(SQLValue(table), SQLCondition(table))),
  )
}

pub fn query(table: Table(table)) -> Query(table) {
  Query(tables: [table], select: [], joins: [], where: [], invalid: ValidQuery)
}

pub fn select(
  query: Query(table),
  from from: fn(column) -> table,
  columns columns: List(column),
) -> Query(table) {
  Query(..query, select: list.append(list.map(columns, from), query.select))
}

pub fn where_equals_string(
  query: Query(table),
  column: table,
  value: String,
) -> Query(table) {
  case
    list.any(query.tables, fn(table) {
      list.any(table.get_columns(table), fn(table_column) {
        column.get_column(table_column) == column
      })
    })
  {
    True ->
      Query(..query, where: [
        #(ColumnValue(column), Equals(StringValue(value))),
        ..query.where
      ])
    False -> {
      echo "Invalid column"
      echo column
      echo "Only the following tables are in the current query scope:"
      echo list.map(query.tables, fn(table) { table.get_name(table) })
        |> string.join(", ")
      Query(..query, invalid: InvalidQuery("Invalid column"))
    }
  }
}

pub fn where_equals_int(
  query: Query(table),
  column: table,
  value: Int,
) -> Query(table) {
  Query(..query, where: [
    #(ColumnValue(column), Equals(IntValue(value))),
    ..query.where
  ])
}

pub fn join(
  query: Query(table),
  table table: Table(table),
  on on: #(table, table),
) -> Query(table) {
  Query(..query, tables: [table, ..query.tables], joins: [
    Join(table:, on: #(ColumnValue(on.0), Equals(ColumnValue(on.1))), and: []),
    ..query.joins
  ])
}
