import birdie
import pprint

import gleaky.{int, string}
import gleaky/insert
import gleaky/postgres as pg

import example.{Address, Age, Customer, Name, Street}

pub fn postgres_insert_test() {
  insert.insert(example.table1())
  |> insert.columns([Customer(Name), Customer(Age)])
  |> insert.values([string("John Doe"), int(1)])
  |> pg.transform_insert
  |> pprint.format
  |> birdie.snap(title: "postgres insert")
}

pub fn postgres_insert_table_mismatch_column_test() {
  insert.insert(example.table1())
  |> insert.columns([Address(Street), Customer(Age)])
  |> insert.values([string("John Doe"), int(1)])
  |> pg.transform_insert
  |> pprint.format
  |> birdie.snap(title: "postgres insert mismatch table column")
}
