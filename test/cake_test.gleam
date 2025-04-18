import birdie
import pprint

import gleaky.{column_value as col, int, string}
import gleaky/cake
import gleaky/query
import gleaky/transform
import gleaky/where

import example.{Address, Age, Customer, Name, Street, table1, table2}

pub fn query_test() {
  query.query(table1())
  |> query.select(Customer, [Name, Age])
  |> query.where(
    where.and([
      where.equal(col(Customer(Name)), string("John")),
      where.equal(col(Customer(Age)), int(30)),
    ]),
  )
  |> query.join(
    table2(),
    on: where.equal(col(Customer(Name)), col(Address(Street))),
  )
  |> query.where(where.equal(col(Address(Street)), string("Majeedhee Magu")))
  |> transform.transform(cake.cake_transformer())
  |> pprint.format
  |> birdie.snap(title: "cake1")
}
