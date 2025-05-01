import birdie
import pprint

import gleaky.{column_value, int, string}
import gleaky/postgres as pg
import gleaky/update
import gleaky/where

import example.{Address, Age, Customer, Name, Street}

pub fn postgres_update_test() {
  update.update(example.table1())
  |> update.set(Customer(Age), int(32))
  |> pg.transform_update
  |> pprint.format
  |> birdie.snap(title: "postgres update")
}

pub fn postgres_update_with_where_test() {
  update.update(example.table1())
  |> update.set(Customer(Name), string("Jane Doe"))
  |> update.where(where.equal(column_value(Customer(Name)), string("John Doe")))
  |> pg.transform_update
  |> pprint.format
  |> birdie.snap(title: "postgres update with where")
}
