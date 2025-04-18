import birdie
import pprint

import glundrisse/table
import glundrisse/table/column

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
  |> pprint.format
  |> birdie.snap(title: "define table 1")
}
