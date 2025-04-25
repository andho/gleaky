import gleaky
import gleaky/table
import gleaky/table/column

pub type CustomerColumns {
  CustomerId
  Name
  Age
  Gender
}

pub type AddressColumns {
  AddressId
  Street
  City
  AddressCustomer
}

pub type Tables {
  Customer(CustomerColumns)
  Address(AddressColumns)
}

pub fn table1() {
  table.table(Customer, name: "customers")
  |> column.id_int(CustomerId, attributes: [])
  |> column.string(Name, name: "name", attributes: [
    column.default_string("John Doe"),
  ])
  |> column.int(Age, name: "age", attributes: [column.null])
  |> table.create
}

pub fn table2() {
  table.table(Address, name: "addresses")
  |> column.id_int(AddressId, attributes: [])
  |> column.string(Street, name: "street", attributes: [
    column.default_string("Majeedhee Magu"),
  ])
  |> column.int(City, name: "city", attributes: [column.null])
  |> column.int(AddressCustomer, name: "customer_id", attributes: [
    column.references(Customer(CustomerId)),
  ])
  |> table.create
}

pub fn table1_v2() {
  table.table(Customer, name: "customers")
  |> column.id_int(CustomerId, attributes: [])
  |> column.string(Name, name: "name", attributes: [
    column.default_string("Jane Doe"),
  ])
  |> column.string(Gender, name: "gender", attributes: [])
  |> table.create
}

pub fn table1_alter_v1() {
  table.table(Customer, name: "customers")
  |> column.id_int(CustomerId, attributes: [])
  |> column.string(Name, name: "name", attributes: [
    column.default_string("Jane Doe"),
    column.null,
  ])
  |> column.string(Gender, name: "gender", attributes: [])
  |> table.create
}
