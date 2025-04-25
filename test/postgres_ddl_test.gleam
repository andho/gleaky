import gleam/option.{None, Some}

import birdie
import gleeunit/should
import pprint

import gleaky
import gleaky/ddl.{create_schema, create_table}
import gleaky/postgres as pg
import gleaky/table
import gleaky/table/column

import example.{Customer, Gender, Name, table1}

pub fn create_table_test() {
  let options = pg.PgOptions(default_collation: pg.EnUsUtf8, schema: "public")

  create_schema([table1()])
  |> create_table(table1())
  |> should.be_ok
  |> ddl.Create
  |> pg.transform_ddl(options)
  |> pprint.format
  |> birdie.snap(
    title: "postgres create table transform to postgres create table",
  )
}

pub fn alter_table_test() {
  let options = pg.PgOptions(default_collation: pg.EnUsUtf8, schema: "public")
  let schema = create_schema([table1()])

  create_table(schema, table1())
  |> should.be_ok
  |> ddl.diff_table(schema, _, example.table1_alter_v1())
  |> should.be_ok
  |> ddl.Alter
  |> pg.transform_ddl(options)
  |> pprint.format
  |> birdie.snap(
    title: "postgres alter table transform to postgres alter table",
  )
}

pub fn drop_column_primary_key_test() {
  let options = pg.PgOptions(default_collation: pg.EnUsUtf8, schema: "public")

  let constraints =
    ddl.ColumnConstraint(
      gleaky.NotNull,
      ddl.NoForeignKey,
      gleaky.NoDefault,
      gleaky.PrimaryKey,
    )
  let column =
    ddl.DDLColumn(
      name: "id",
      data_type: ddl.TypeInt,
      collate: ddl.Collate(""),
      constraints: constraints,
    )
  let new_column =
    ddl.DDLColumn(
      ..column,
      constraints: ddl.ColumnConstraint(
        ..constraints,
        primary_key: gleaky.NotPrimaryKey,
      ),
    )
  let alter_column = ddl.AlterColumn("id", column, new_column)

  pg.transform_ddl_alter_column(column, new_column, options)
  |> pprint.format
  |> birdie.snap(title: "postgres alter column remove primary key")
}

pub fn add_column_primary_key_test() {
  let options = pg.PgOptions(default_collation: pg.EnUsUtf8, schema: "public")

  let constraints =
    ddl.ColumnConstraint(
      gleaky.NotNull,
      ddl.NoForeignKey,
      gleaky.NoDefault,
      gleaky.NotPrimaryKey,
    )
  let column =
    ddl.DDLColumn(
      name: "id",
      data_type: ddl.TypeInt,
      collate: ddl.Collate(""),
      constraints: constraints,
    )
  let new_column =
    ddl.DDLColumn(
      ..column,
      constraints: ddl.ColumnConstraint(
        ..constraints,
        primary_key: gleaky.PrimaryKey,
      ),
    )
  let alter_column = ddl.AlterColumn("id", column, new_column)

  pg.transform_ddl_alter_column(column, new_column, options)
  |> pprint.format
  |> birdie.snap(title: "postgres alter column add primary key")
}
