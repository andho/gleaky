import birdie
import example
import pprint

import gleaky/table
import gleaky/table/column

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

pub fn table1_test() {
  table.table(Customers, name: "customers")
  |> column.string(Name, name: "name", attributes: [
    column.default_string("John Doe"),
  ])
  |> column.int(Age, name: "age", attributes: [column.null])
  |> table.create
  |> pprint.format
  |> birdie.snap(title: "define table 1")
}

pub fn table_with_foreign_key_test() {
  example.table2()
  |> pprint.format
  |> birdie.snap(title: "define table with foreign key 1")
}
