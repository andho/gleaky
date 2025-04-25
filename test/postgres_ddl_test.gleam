import gleam/option.{None, Some}

import birdie
import gleeunit/should
import pprint

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
  |> birdie.snap(title: "create table transform to postgres create table")
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
  |> birdie.snap(title: "alter table transform to postgres alter table")
}
