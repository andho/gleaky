import birdie
import pprint

import glundrisse/query
import glundrisse/table
import glundrisse/table/column

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
  |> query.where_equals_string(Customer(Name), "John")
  |> query.where_equals_int(Customer(Age), 30)
  |> query.join(table2, on: #(Customer(Name), Address(Street)))
  |> query.where_equals_string(Address(Street), "Majeedhee Magu")
  |> pprint.format
  |> birdie.snap(title: "query1")
}
