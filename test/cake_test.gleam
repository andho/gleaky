import birdie
import pprint

import glundrisse/cake
import glundrisse/query
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
  |> query.where_equals_string(Customers(Name), "John")
  |> query.where_equals_int(Customers(Age), 30)
  |> query.join(table2, on: #(Customers(Name), Addresses(Street)))
  |> query.where_equals_string(Addresses(Street), "Majeedhee Magu")
  |> cake.transform
  |> pprint.format
  |> birdie.snap(title: "cake1")
}
