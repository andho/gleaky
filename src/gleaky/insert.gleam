import gleaky.{type SQLValue, type Table}
import gleaky/query.{type Query}

pub type Insert(table) {
  Insert(table: Table(table), columns: List(table), values: InsertValues(table))
}

pub type InsertValues(table) {
  ScalarValues(List(SQLValue(table)))
  QueryValues(Query(table))
}

pub fn insert(table: Table(table)) -> Insert(table) {
  Insert(table: table, columns: [], values: ScalarValues([]))
}

pub fn columns(
  insert: Insert(table),
  columns columns: List(table),
) -> Insert(table) {
  Insert(..insert, columns: columns)
}

pub fn values(
  insert: Insert(table),
  values values: InsertValues(table),
) -> Insert(table) {
  Insert(..insert, values: values)
}
