import gleam/dict
import gleam/list

import gleaky.{type Column, type Table, type TableBuilder, Table, TableBuilder}
import gleaky/table/column

pub fn table(
  table: fn(column) -> table,
  name name: String,
) -> TableBuilder(table, column) {
  TableBuilder(table:, name:, columns: [])
}

pub fn create(table: TableBuilder(table, column)) -> Table(table) {
  let column_map =
    table.columns
    |> list.map(fn(column) { #(column.get_column(column), column) })
    |> dict.from_list
  Table(
    name: table.name,
    columns: table.columns
      |> list.map(fn(col) { col.column })
      |> list.reverse,
    column_map:,
  )
}

pub fn get_name(table: Table(table)) -> String {
  table.name
}

pub fn get_columns(table: Table(table)) -> List(table) {
  table.columns
}

pub fn get_column_map(table: Table(table)) -> dict.Dict(table, Column(table)) {
  table.column_map
}

pub fn get_column(
  table: Table(table),
  column: table,
) -> Result(Column(table), Nil) {
  table.column_map |> dict.get(column)
}
