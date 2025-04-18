import gleam/list
import gleam/option.{None, Some}

import glundrisse.{
  type Column, type TableBuilder, ColumnBasics, IntColumn, InvalidColumn,
  StringColumn, TableBuilder,
}

pub fn get_column_name(column: Column(table)) -> String {
  column.name
}

pub fn get_column(column: Column(table)) -> table {
  column.column
}

pub fn string(
  table: TableBuilder(table, column),
  column: column,
  name name: String,
  attributes attributes: List(fn(Column(table)) -> Column(table)),
) -> TableBuilder(table, column) {
  let new_column =
    StringColumn(
      table.table(column),
      name,
      ColumnBasics(default: None, nullable: False),
    )
    |> list.fold(attributes, _, fn(col, attribute) { attribute(col) })
  TableBuilder(..table, columns: [new_column, ..table.columns])
}

pub fn int(
  table: TableBuilder(table, column),
  column: column,
  name name: String,
  attributes attributes: List(fn(Column(table)) -> Column(table)),
) -> TableBuilder(table, column) {
  let new_column =
    IntColumn(
      table.table(column),
      name,
      ColumnBasics(default: None, nullable: False),
    )
    |> list.fold(attributes, _, fn(col, attribute) { attribute(col) })
  TableBuilder(..table, columns: [new_column, ..table.columns])
}

pub fn null(column: Column(column)) -> Column(column) {
  case column {
    StringColumn(_, _, basics) ->
      StringColumn(..column, basics: ColumnBasics(..basics, nullable: True))
    IntColumn(_, _, basics) ->
      IntColumn(..column, basics: ColumnBasics(..basics, nullable: True))
    InvalidColumn(_, _) -> column
  }
}

pub fn default_string(value: String) -> fn(Column(column)) -> Column(column) {
  fn(column: Column(column)) {
    case column {
      StringColumn(_, _, basics) ->
        StringColumn(
          ..column,
          basics: ColumnBasics(..basics, default: Some(value)),
        )
      _ -> InvalidColumn(column.column, column.name)
    }
  }
}

pub fn default_int(column: Column(column), value: Int) -> Column(column) {
  case column {
    IntColumn(_, _, basics) ->
      IntColumn(..column, basics: ColumnBasics(..basics, default: Some(value)))
    _ -> InvalidColumn(column.column, column.name)
  }
}
