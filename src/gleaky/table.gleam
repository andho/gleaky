import gleam/list

import gleaky.{type Column, type Table, type TableBuilder, Table, TableBuilder}

pub fn table(
  table: fn(column) -> table,
  name name: String,
) -> TableBuilder(table, column) {
  TableBuilder(table:, name:, columns: [])
}

pub fn create(table: TableBuilder(table, column)) -> Table(table) {
  Table(name: table.name, columns: list.reverse(table.columns))
}

pub fn get_name(table: Table(table)) -> String {
  table.name
}

pub fn get_columns(table: Table(table)) -> List(Column(table)) {
  table.columns
}
