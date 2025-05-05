import gleaky.{type SQLValue, type Table}
import gleaky/query.{type Query}
import gleam/list

pub type Insert(table) {
  Insert(
    table: Table(table),
    columns: List(table),
    values: InsertValues(table),
    returning: Returning(table),
  )
}

pub type InsertValues(table) {
  ScalarValues(List(SQLValue(table)))
  QueryValues(Query(table))
}

pub type Returning(table) {
  NotReturning
  Returning(List(table))
}

pub fn insert(table: Table(table)) -> Insert(table) {
  Insert(
    table: table,
    columns: [],
    values: ScalarValues([]),
    returning: NotReturning,
  )
}

pub fn columns(
  insert: Insert(table),
  columns columns: List(table),
) -> Insert(table) {
  Insert(..insert, columns: columns)
}

pub fn values(
  insert: Insert(table),
  values values: List(SQLValue(table)),
) -> Insert(table) {
  Insert(..insert, values: ScalarValues(values))
}

pub fn with_value(insert: Insert(table), column: table, value: SQLValue(table)) {
  let values = case insert.values {
    ScalarValues(values) -> [value, ..values]
    QueryValues(_) -> [value]
  }

  Insert(
    ..insert,
    columns: list.unique([column, ..insert.columns]),
    values: ScalarValues(values),
  )
}

pub fn returning(insert: Insert(table), columns: List(table)) {
  Insert(..insert, returning: Returning(columns))
}
