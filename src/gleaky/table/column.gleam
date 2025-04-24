import gleam/list

import gleaky.{
  type Column, type TableBuilder, ColumnConstraint, Default, IntColumn, IntValue,
  InvalidColumn, NoDefault, NoForeignKey, NotNull, Null, StringColumn,
  StringValue, TableBuilder,
}

pub fn get_column_name(column: Column(table)) -> String {
  column.name
}

pub fn get_column(column: Column(table)) -> table {
  column.column
}

fn default_constraints() {
  ColumnConstraint(NotNull, NoForeignKey, NoDefault)
}

fn id_constraints() {
  ColumnConstraint(NotNull, NoForeignKey, NoDefault)
}

pub fn id_int(
  table: TableBuilder(table, column),
  column: column,
  attributes attributes: List(fn(Column(table)) -> Column(table)),
) -> TableBuilder(table, column) {
  let new_column =
    IntColumn(table.table(column), "id", id_constraints())
    |> list.fold(attributes, _, fn(col, attribute) { attribute(col) })
  TableBuilder(..table, columns: [new_column, ..table.columns])
}

pub fn string(
  table: TableBuilder(table, column),
  column: column,
  name name: String,
  attributes attributes: List(fn(Column(table)) -> Column(table)),
) -> TableBuilder(table, column) {
  let new_column =
    StringColumn(table.table(column), name, default_constraints())
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
    IntColumn(table.table(column), name, default_constraints())
    |> list.fold(attributes, _, fn(col, attribute) { attribute(col) })
  TableBuilder(..table, columns: [new_column, ..table.columns])
}

pub fn null(column: Column(column)) -> Column(column) {
  case column {
    StringColumn(_, _, constraints) ->
      StringColumn(
        ..column,
        constraints: ColumnConstraint(..constraints, nullable: Null),
      )
    IntColumn(_, _, constraints) ->
      IntColumn(
        ..column,
        constraints: ColumnConstraint(..constraints, nullable: Null),
      )
    InvalidColumn(_, _, _) -> column
  }
}

pub fn is_nullable(column: Column(column)) -> Bool {
  case column.constraints.nullable {
    Null -> True
    NotNull -> False
  }
}

pub fn default_string(value: String) -> fn(Column(column)) -> Column(column) {
  fn(column: Column(column)) {
    case column {
      StringColumn(_, _, constraints) ->
        StringColumn(
          ..column,
          constraints: ColumnConstraint(
            ..constraints,
            default: Default(StringValue(value)),
          ),
        )
      _ -> InvalidColumn(column.column, column.name, column.constraints)
    }
  }
}

pub fn default_int(column: Column(column), value: Int) -> Column(column) {
  case column {
    IntColumn(_, _, constraints) ->
      IntColumn(
        ..column,
        constraints: ColumnConstraint(
          ..constraints,
          default: Default(IntValue(value)),
        ),
      )
    _ -> InvalidColumn(column.column, column.name, column.constraints)
  }
}
