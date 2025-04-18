import birdie
import pprint

import glundrisse.{column_value as col, int, string}
import glundrisse/query
import glundrisse/table
import glundrisse/table/column
import glundrisse/where

pub type CustomerColumns {
  Name
  Age
}

pub type AddressColumns {
  Street
  City
}

pub type Tables {
  Customer(CustomerColumns)
  Address(AddressColumns)
}

pub fn query_test() {
  let table1 =
    table.table(Customer, name: "customers")
    |> column.string(Name, name: "name", attributes: [
      column.default_string("John Doe"),
    ])
    |> column.int(Age, name: "age", attributes: [column.null])
    |> table.create

  let table2 =
    table.table(Address, name: "addresses")
    |> column.string(Street, name: "street", attributes: [
      column.default_string("Majeedhee Magu"),
    ])
    |> column.int(City, name: "city", attributes: [column.null])
    |> table.create

  query.query(table1)
  |> query.select(Customer, [Name, Age])
  |> query.where(where.equal(col(Customer(Name)), string("John")))
  |> query.where(where.equal(col(Customer(Age)), int(30)))
  |> query.join(
    table2,
    on: where.equal(col(Customer(Name)), col(Address(Street))),
  )
  |> query.where(where.equal(col(Address(Street)), string("Majeedhee Magu")))
  |> pprint.format
  |> birdie.snap(title: "query1")
}
