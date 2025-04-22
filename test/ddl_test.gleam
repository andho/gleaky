import birdie
import gleeunit/should
import pprint

import gleaky/ddl.{create_table}
import gleaky/table
import gleaky/table/column

import example.{Customer, Gender, Name, table1}

pub fn create_table_test() {
  create_table(table1())
  |> pprint.format
  |> birdie.snap(title: "create table 1")
}

pub fn compare_create_with_new_table_version_test() {
  let created_table = create_table(table1())

  ddl.diff_table(created_table, table3())
  |> pprint.format
  |> birdie.snap(title: "alter table 1")
}

pub fn make_create_table_from_multiple_ddl_queries_test() {
  let created_table = create_table(table1())

  let alter_table = should.be_ok(ddl.diff_table(created_table, table3()))

  ddl.merge_ddl(created_table, [alter_table])
  |> pprint.format
  |> birdie.snap(title: "make a create table from multiple ddl queries")
}

pub fn table3() {
  table.table(Customer, name: "customers")
  |> column.string(Name, name: "name", attributes: [
    column.default_string("Jane Doe"),
  ])
  |> column.string(Gender, name: "gender", attributes: [])
  |> table.create
}
