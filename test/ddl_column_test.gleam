import birdie
import pprint

import gleaky/ddl
import gleaky/table/column

import example
import example_column.{example_column}

fn schema() {
  ddl.create_schema([example.table1()])
}

pub fn ddl_column_unique_test() {
  example_column()
  |> column.unique
  |> ddl.column_to_ddl_column(schema(), example.table1(), _)
  |> pprint.format
  |> birdie.snap(title: "ddl column unique column")
}

pub fn ddl_column_not_unique_test() {
  example_column()
  |> ddl.column_to_ddl_column(schema(), example.table1(), _)
  |> pprint.format
  |> birdie.snap(title: "ddl column not unique column")
}
