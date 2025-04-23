import gleaky/ddl.{type DDLQuery, Alter, Create, Drop}
import gleam/list
import gleam/string

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
  column: ddl.DDLColumn,
  options: PgOptions,
) -> String {
  transform_alter_data_type(column.data_type, options)
}

fn transform_data_type(data_type: ddl.DataType, _options: PgOptions) -> String {
  case data_type {
    ddl.TypeString -> "varchar"
    ddl.TypeInt -> "int"
  }
}

fn transform_alter_data_type(
  data_type: ddl.DataType,
  options: PgOptions,
) -> String {
  "TYPE " <> transform_data_type(data_type, options)
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
      ddl.AlterColumn(column_name, column) ->
        "ALTER COLUMN "
        <> column_name
        <> " "
        <> transform_ddl_alter_column(column, options)
      ddl.DropColumn(column_name) -> "DROP COLUMN " <> column_name
    }
  })
  |> string.join(",\n")
}

fn indent() -> String {
  "\t"
}
