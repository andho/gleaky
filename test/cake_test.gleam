import birdie
import gleaky/transform
import pprint

import gleaky.{column_value as col, int, string}
import gleaky/cake
import gleaky/query
import gleaky/table
import gleaky/table/column
import gleaky/where

pub type CustomColumns {
  Name
  Age
}

pub type AddressColumns {
  Street
  City
}

pub type Tables {
  Customers(CustomColumns)
  Addresses(AddressColumns)
}

pub fn query_test() {
  let table1 =
    table.table(Customers, name: "customers")
    |> column.string(Name, name: "name", attributes: [
      column.default_string("John Doe"),
    ])
    |> column.int(Age, name: "age", attributes: [column.null])
    |> table.create

  let table2 =
    table.table(Addresses, name: "addresses")
    |> column.string(Street, name: "street", attributes: [
      column.default_string("Majeedhee Magu"),
    ])
    |> column.int(City, name: "city", attributes: [column.null])
    |> table.create

  query.query(table1)
  |> query.select(Customers, [Name, Age])
  |> query.where(
    where.and([
      where.equal(col(Customers(Name)), string("John")),
      where.equal(col(Customers(Age)), int(30)),
    ]),
  )
  |> query.join(
    table2,
    on: where.equal(col(Customers(Name)), col(Addresses(Street))),
  )
  |> query.where(where.equal(col(Addresses(Street)), string("Majeedhee Magu")))
  |> transform.transform(cake.cake_transformer())
  |> pprint.format
  |> birdie.snap(title: "cake1")
}
