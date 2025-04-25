import birdie
import gleeunit/should
import pprint

import gleaky
import gleaky/ddl.{create_schema, create_table}
import gleaky/table
import gleaky/table/column

import example.{Customer, Gender, Name, table1}

pub fn create_table_test() {
  create_schema([table1()])
  |> create_table(table1())
  |> should.be_ok
  |> pprint.format
  |> birdie.snap(title: "create table 1")
}

pub fn compare_create_with_new_table_version_test() {
  // schema_v1 is the schema at the first deployment
  let schema_v1 = create_schema([table1()])
  let created_table = create_table(schema_v1, table1()) |> should.be_ok

  // schema_v2 is when some changes has been made to the schema over the course
  // of development
  let schema_v2 = create_schema([example.table1_v2()])
  ddl.diff_table(schema_v2, created_table, example.table1_v2())
  |> pprint.format
  |> birdie.snap(title: "alter table 1")
}

pub fn make_create_table_from_multiple_ddl_queries_test() {
  let schema_v1 = create_schema([example.table1()])
  let created_table = create_table(schema_v1, example.table1()) |> should.be_ok

  let schema_v2 = create_schema([example.table1_v2()])
  let alter_table =
    ddl.diff_table(schema_v2, created_table, example.table1_v2())
    |> should.be_ok

  ddl.merge_ddl(created_table, [alter_table])
  |> pprint.format
  |> birdie.snap(title: "make a create table from multiple ddl queries")
}

pub fn create_table_with_foreign_key_test() {
  create_schema([table1(), example.table2()])
  |> create_table(example.table2())
  |> should.be_ok
  |> pprint.format
  |> birdie.snap(title: "create table with foreign key 1")
}
