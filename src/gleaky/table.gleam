import gleam/dict
import gleam/list
import gleam/result

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

pub fn get_primary_key(table: Table(table)) -> table {
  let assert Ok(pk) =
    table.column_map
    |> dict.to_list
    |> list.find(fn(column_tuple) {
      let #(_, column_data) = column_tuple
      case column_data.constraints.primary_key {
        gleaky.PrimaryKey -> True
        _ -> False
      }
    })
    |> result.map(fn(column_tuple) { column_tuple.0 })

  pk
}
