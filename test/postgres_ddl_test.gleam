import birdie
import gleam/option.{None, Some}
import pprint

import gleaky/ddl.{
  AddColumn, AlterColumn, AlterTable, Collate, CreateTable, DDLColumn, DDLString,
  DropColumn, TypeInt, TypeString,
}
import gleaky/postgres as pg
import gleaky/table
import gleaky/table/column

import example.{Customer, Gender, Name}

pub fn create_table_test() {
  let options = pg.PgOptions(default_collation: pg.EnUsUtf8, schema: "public")

  CreateTable(
    "customers",
    [
      DDLColumn(
        "name",
        TypeString(None),
        False,
        Some(DDLString("John Doe")),
        Collate("utf8"),
      ),
      DDLColumn("age", TypeInt, True, None, Collate("utf8")),
    ],
    [],
    [],
    [],
  )
  |> ddl.Create
  |> pg.transform_ddl(options)
  |> pprint.format
  |> birdie.snap(title: "create table transform to postgres create table")
}

pub fn alter_table_test() {
  let options = pg.PgOptions(default_collation: pg.EnUsUtf8, schema: "public")
  AlterTable(
    "customers",
    [
      DropColumn("age"),
      AlterColumn(
        "name",
        DDLColumn(
          "name",
          TypeString(None),
          True,
          Some(DDLString("John Doe")),
          Collate("utf8"),
        ),
        DDLColumn(
          "name",
          TypeString(Some(10)),
          False,
          Some(DDLString("Jane Doe")),
          Collate("utf8"),
        ),
      ),
      AddColumn(DDLColumn(
        "gender",
        TypeString(None),
        False,
        None,
        Collate("utf8"),
      )),
    ],
    [],
    [],
    [],
  )
  |> ddl.Alter
  |> pg.transform_ddl(options)
  |> pprint.format
  |> birdie.snap(title: "alter table transform to postgres alter table")
}

pub fn table3() {
  table.table(Customer, name: "customers")
  |> column.string(Name, name: "name", attributes: [
    column.default_string("Jane Doe"),
  ])
  |> column.string(Gender, name: "gender", attributes: [])
  |> table.create
}
