import birdie
import pprint

import gleaky.{column_value, string}
import gleaky/delete
import gleaky/postgres as pg
import gleaky/where

import example.{Customer, Name}

pub fn postgres_delete_test() {
  delete.delete(example.table1())
  |> pg.transform_delete
  |> pprint.format
  |> birdie.snap(title: "postgres delete")
}

pub fn postgres_delete_with_where_test() {
  delete.delete(example.table1())
  |> delete.where(where.equal(column_value(Customer(Name)), string("John Doe")))
  |> pg.transform_delete
  |> pprint.format
  |> birdie.snap(title: "postgres delete with where")
}
