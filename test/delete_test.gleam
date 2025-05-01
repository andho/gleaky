import birdie
import pprint

import gleaky.{column_value, string}
import gleaky/delete
import gleaky/where

import example.{Customer, Name}

pub fn delete_test() {
  delete.delete(example.table1())
  |> pprint.format
  |> birdie.snap(title: "delete")
}

pub fn delete_with_where_test() {
  delete.delete(example.table1())
  |> delete.where(where.equal(column_value(Customer(Name)), string("John Doe")))
  |> pprint.format
  |> birdie.snap(title: "delete with where")
}
