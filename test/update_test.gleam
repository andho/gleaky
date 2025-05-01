import birdie
import pprint

import gleaky.{column_value, int, string}
import gleaky/update
import gleaky/where

import example.{Age, Customer, Name}

pub fn update_test() {
  update.update(example.table1())
  |> update.set(Customer(Age), int(32))
  |> pprint.format
  |> birdie.snap(title: "update")
}

pub fn update_with_where_test() {
  update.update(example.table1())
  |> update.set(Customer(Name), string("Jane Doe"))
  |> update.where(where.equal(column_value(Customer(Name)), string("John Doe")))
  |> pprint.format
  |> birdie.snap(title: "update with where")
}
