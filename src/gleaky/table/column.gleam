import gleam/list
import gleam/result

import gleaky.{
  type Column, type TableBuilder, ColumnConstraint, Default, IntColumn, IntValue,
  InvalidColumn, NoDefault, NoForeignKey, NotNull, NotPrimaryKey, NotUnique,
  Null, PrimaryKey, StringColumn, StringValue, TableBuilder, Unique,
}

pub fn get_column_name(column: Column(table)) -> String {
  column.name
}

pub fn get_column(column: Column(table)) -> table {
  column.column
}

pub fn default_constraints() {
  ColumnConstraint(NotNull, NoForeignKey, NoDefault, NotPrimaryKey, NotUnique)
}

pub fn id_constraints() {
  ColumnConstraint(NotNull, NoForeignKey, NoDefault, PrimaryKey, NotUnique)
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

pub fn foreign(
  column: Column(table),
  references: gleaky.ForeignKey(table),
) -> Column(table) {
  case column {
    StringColumn(_, _, constraints) ->
      StringColumn(
        ..column,
        constraints: ColumnConstraint(..constraints, foreign_key: references),
      )
    IntColumn(_, _, constraints) ->
      IntColumn(
        ..column,
        constraints: ColumnConstraint(..constraints, foreign_key: references),
      )
    InvalidColumn(_, _, _) -> column
  }
}

pub fn references(to to_column: column) -> fn(Column(column)) -> Column(column) {
  fn(column: Column(column)) {
    let foreign_key =
      gleaky.ForeignKey(
        columns: [to_column],
        on_delete: gleaky.OnDelete(gleaky.Cascade),
        on_update: gleaky.OnUpdate(gleaky.Cascade),
      )

    case column {
      StringColumn(_, _, constraints) ->
        StringColumn(
          ..column,
          constraints: ColumnConstraint(..constraints, foreign_key:),
        )
      IntColumn(_, _, constraints) ->
        IntColumn(
          ..column,
          constraints: ColumnConstraint(..constraints, foreign_key:),
        )
      InvalidColumn(_, _, _) -> column
    }
  }
}

pub fn on_delete(
  column_builder: fn(Column(table)) -> Column(table),
  cascade_rule cascade_rule: gleaky.CascadeRule(table),
) -> fn(Column(table)) -> Column(table) {
  fn(base_column: Column(table)) {
    let column = column_builder(base_column)
    case column.constraints.foreign_key {
      gleaky.NoForeignKey -> Error(Nil)
      gleaky.ForeignKey(columns, _, on_update) ->
        Ok(gleaky.ForeignKey(
          columns: columns,
          on_delete: gleaky.OnDelete(cascade_rule),
          on_update: on_update,
        ))
    }
    |> result.map(fn(foreign_key) {
      case column {
        StringColumn(_, _, constraints) ->
          StringColumn(
            ..column,
            constraints: ColumnConstraint(..constraints, foreign_key:),
          )
        IntColumn(_, _, constraints) ->
          IntColumn(
            ..column,
            constraints: ColumnConstraint(..constraints, foreign_key:),
          )
        InvalidColumn(_, _, _) -> column
      }
    })
    |> result.unwrap(InvalidColumn(
      column.column,
      column.name,
      column.constraints,
    ))
  }
}

pub fn on_update(
  column_builder: fn(Column(table)) -> Column(table),
  cascade_rule cascade_rule: gleaky.CascadeRule(table),
) -> fn(Column(table)) -> Column(table) {
  fn(base_column: Column(table)) {
    let column = column_builder(base_column)
    case column.constraints.foreign_key {
      gleaky.NoForeignKey -> Error(Nil)
      gleaky.ForeignKey(columns, on_delete, _) ->
        Ok(gleaky.ForeignKey(
          columns: columns,
          on_delete: on_delete,
          on_update: gleaky.OnUpdate(cascade_rule),
        ))
    }
    |> result.map(fn(foreign_key) {
      case column {
        StringColumn(_, _, constraints) ->
          StringColumn(
            ..column,
            constraints: ColumnConstraint(..constraints, foreign_key:),
          )
        IntColumn(_, _, constraints) ->
          IntColumn(
            ..column,
            constraints: ColumnConstraint(..constraints, foreign_key:),
          )
        InvalidColumn(_, _, _) -> column
      }
    })
    |> result.unwrap(InvalidColumn(
      column.column,
      column.name,
      column.constraints,
    ))
  }
}

pub fn primary_key(column: Column(column)) -> Column(column) {
  case column {
    StringColumn(_, _, constraints) ->
      StringColumn(
        ..column,
        constraints: ColumnConstraint(..constraints, primary_key: PrimaryKey),
      )
    IntColumn(_, _, constraints) ->
      IntColumn(
        ..column,
        constraints: ColumnConstraint(..constraints, primary_key: PrimaryKey),
      )
    InvalidColumn(_, _, _) -> column
  }
}

pub fn unique(column: Column(column)) -> Column(column) {
  case column {
    StringColumn(_, _, constraints) ->
      StringColumn(
        ..column,
        constraints: ColumnConstraint(..constraints, unique: Unique),
      )
    IntColumn(_, _, constraints) ->
      IntColumn(
        ..column,
        constraints: ColumnConstraint(..constraints, unique: Unique),
      )
    InvalidColumn(_, _, _) -> column
  }
}
