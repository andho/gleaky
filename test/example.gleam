import gleaky/table
import gleaky/table/column

pub type CustomerColumns {
  Name
  Age
  Gender
}

pub type AddressColumns {
  Street
  City
}

pub type Tables {
  Customer(CustomerColumns)
  Address(AddressColumns)
}

pub fn table1() {
  table.table(Customer, name: "customers")
  |> column.string(Name, name: "name", attributes: [
    column.default_string("John Doe"),
  ])
  |> column.int(Age, name: "age", attributes: [column.null])
  |> table.create
}

pub fn table2() {
  table.table(Address, name: "addresses")
  |> column.string(Street, name: "street", attributes: [
    column.default_string("Majeedhee Magu"),
  ])
  |> column.int(City, name: "city", attributes: [column.null])
  |> table.create
}
