import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

import gleaky/ddl.{type DDLQuery, Alter, Create, Drop}

pub type PgCollation {
  Default
  EnUsUtf8
}

pub type PgOptions {
  PgOptions(default_collation: PgCollation, schema: String)
}

pub fn transform_ddl(ddl: DDLQuery, options: PgOptions) -> String {
  case ddl {
    Create(create) -> transform_create(create, options)
    Alter(alter) -> transform_alter(alter, options)
    Drop(drop) -> transform_drop(drop, options)
  }
}

fn transform_create(create: ddl.CreateTable, options: PgOptions) -> String {
  "CREATE TABLE "
  |> string.append(transform_table_name(create.name, options))
  |> string.append(" (")
  |> string.append(transform_ddl_columns(create.columns, options))
  |> string.append(");")
}

fn transform_alter(alter: ddl.AlterTable, options: PgOptions) -> String {
  "ALTER TABLE "
  |> string.append(transform_table_name(alter.name, options))
  |> string.append("\n" <> transform_ddl_alter_columns(alter.columns, options))
  |> string.append(";")
}

fn transform_drop(drop: ddl.DropTable, options: PgOptions) -> String {
  "DROP TABLE "
  |> string.append(transform_table_name(drop.name, options))
}

fn transform_table_name(name: String, options: PgOptions) -> String {
  options.schema <> "." <> name
}

fn transform_ddl_columns(
  columns: List(ddl.DDLColumn),
  options: PgOptions,
) -> String {
  "\n"
  <> list.map(columns, fn(column) {
    transform_ddl_column(column, indent(), options)
  })
  |> string.join(",\n")
  <> "\n"
}

fn transform_ddl_column(
  column: ddl.DDLColumn,
  indent: String,
  options: PgOptions,
) -> String {
  indent
  <> column.name
  |> string.append(" ")
  |> string.append(transform_data_type(column.data_type, options))
  |> string.append(case column.nullable {
    True -> " NULL"
    False -> " NOT NULL"
  })
  |> string.append("")
  |> string.append("")
}

fn transform_ddl_alter_column(
  old_column: ddl.DDLColumn,
  new_column: ddl.DDLColumn,
  options: PgOptions,
) -> List(Option(String)) {
  [
    transform_alter_data_type(old_column, new_column, options),
    transform_alter_default(old_column, new_column, options),
    transform_alter_nullable(old_column, new_column, options),
  ]
}

fn transform_alter_default(
  old_column: ddl.DDLColumn,
  new_column: ddl.DDLColumn,
  _options: PgOptions,
) -> Option(String) {
  case old_column.default, new_column.default {
    Some(old), Some(new) if old == new -> None
    Some(_), Some(new_default) | None, Some(new_default) ->
      Some(
        "ALTER COLUMN "
        <> new_column.name
        <> " SET DEFAULT "
        <> transform_ddl_value(new_default),
      )
    Some(_), None -> Some(new_column.name <> " DROP DEFAULT")
    None, None -> None
  }
}

fn transform_alter_nullable(
  old_column: ddl.DDLColumn,
  new_column: ddl.DDLColumn,
  _options: PgOptions,
) -> Option(String) {
  case old_column.nullable, new_column.nullable {
    True, True | False, False -> None
    _, _ ->
      Some(
        "ALTER COLUMN "
        <> new_column.name
        <> {
          case new_column.nullable {
            True -> " SET"
            False -> " DROP"
          }
        }
        <> " NOT NULL",
      )
  }
}

fn transform_alter_data_type(
  old_column: ddl.DDLColumn,
  new_column: ddl.DDLColumn,
  options: PgOptions,
) -> Option(String) {
  case did_data_type_change(old_column, new_column) {
    True ->
      Some(
        "ALTER COLUMN "
        <> new_column.name
        <> " TYPE "
        <> transform_data_type(new_column.data_type, options),
      )
    _ -> None
  }
}

fn did_data_type_change(
  old_column: ddl.DDLColumn,
  new_column: ddl.DDLColumn,
) -> Bool {
  old_column.data_type != new_column.data_type
}

fn transform_ddl_value(value: ddl.DDLValue) -> String {
  case value {
    ddl.DDLString(value) -> "'" <> value <> "'"
    ddl.DDLInt(value) -> int.to_string(value)
  }
}

fn transform_data_type(data_type: ddl.DataType, _options: PgOptions) -> String {
  case data_type {
    ddl.TypeString(None) -> "varchar"
    ddl.TypeString(Some(length)) -> "varchar(" <> int.to_string(length) <> ")"
    ddl.TypeInt -> "int"
  }
}

fn transform_ddl_alter_columns(
  columns: List(ddl.DDLAlterColumn),
  options: PgOptions,
) -> String {
  list.map(columns, fn(column) {
    indent()
    <> case column {
      ddl.AddColumn(column) ->
        "ADD " <> transform_ddl_column(column, "", options)
      ddl.AlterColumn(_, old_column, new_column) ->
        transform_ddl_alter_column(old_column, new_column, options)
        |> list.filter_map(fn(option) { option.to_result(option, Nil) })
        |> string.join(",\n" <> indent())
      ddl.DropColumn(column_name) -> "DROP COLUMN " <> column_name
    }
  })
  |> string.join(",\n")
}

fn indent() -> String {
  "\t"
}
