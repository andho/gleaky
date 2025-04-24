# gleaky

This is a gleam library for defining RDBMS table structure and build queries for
those tables. Actually executing the queries is not part of this library, but
currently a transformer for [cake](https://github.com/inoas/gleam-cake) is
provided.

## Usage

```gleam
import gleaky.{column_value as col, int, string}
import gleaky/query
import gleaky/table
import gleaky/table/column
import gleaky/transform
import gleaky/where

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
  |> query.where(
    where.and([
      where.equal(col(Customer(Name)), string("John")),
      where.equal(col(Customer(Age)), int(30)),
    ]),
  )
  |> query.join(
    table2,
    on: where.equal(col(Customer(Name)), col(Address(Street))),
  )
  |> query.where(where.equal(col(Address(Street)), string("Majeedhee Magu")))
}
```

## Supported SELECT SQL Query features

Following features are supported (*or planned to be supported):

- [x] Select columns
- [x] Inner joins
- [ ] Left joins
- [ ] Right joins
- [ ] Full outer joins
- [ ] Where conditions
  - [x] Equals
  - [x] Greater than
  - [x] Greater than or equals
  - [x] Less than
  - [x] Less than or equals
  - [x] In
  - [x] Like
  - [x] And
  - [x] Or
  - [x] Not
  - [ ] Between
  - [ ] Exists
- [ ] Group by
- [ ] Having
- [ ] Order by
- [ ] Limit & Offset

Following features are not planned:

- Select all columns
- Select columns with aliases
- Distinct
- Union
- Aggregates
- Arithmetic expressions
- Functions

## Supported DDL

- [ ] Foreign key (table and column)
  - [ ] On delete and On Update
    - [ ] Cascade
    - [ ] Restrict
    - [ ] Set null with a subset of columns
    - [ ] Set default with a subset of columns
- [ ] Not Null
- [ ] Unique (table and column) (nulls not distinct is set on supported systems)
- [ ] Primary key (table and column)

## Currently not supported

- Check constraints
- Exclusion constraints
