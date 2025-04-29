import birdie
import pprint

import gleaky/ddl
import gleaky/postgres as pg
import gleaky/table/column

import example
import example_column.{example_column}

fn schema() {
  ddl.create_schema([example.table1()])
}

pub fn postgres_ddl_column_unique_test() {
  let options = pg.PgOptions(default_collation: pg.EnUsUtf8, schema: "public")

  example_column()
  |> column.unique
  |> ddl.column_to_ddl_column(schema(), example.table1(), _)
  |> pg.transform_ddl_column("", options)
  |> pprint.format
  |> birdie.snap(title: "postgres ddl column unique column")
}

pub fn postgres_ddl_column_not_unique_test() {
  let options = pg.PgOptions(default_collation: pg.EnUsUtf8, schema: "public")

  example_column()
  |> ddl.column_to_ddl_column(schema(), example.table1(), _)
  |> pg.transform_ddl_column("", options)
  |> pprint.format
  |> birdie.snap(title: "postgres ddl column not unique column")
}
