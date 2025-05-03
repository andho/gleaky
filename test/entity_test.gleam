import birdie
import pprint

import gleaky.{string}
import gleaky/entity
import gleaky/sql

import example.{Customer, Name}

pub type CustomerEntity {
  CustomerEntity(name: String, age: Int)
}

pub fn entity_find_by_query_test() {
  let entity =
    entity.Entity(
      table: example.table1(),
      transformer: sql.sql_transformer(),
      query: test_query,
    )

  entity.find_by(entity, Customer(Name), string("John Doe"))
}

fn test_query(query) -> Result(CustomerEntity, Nil) {
  query
  |> pprint.format
  |> birdie.snap(title: "find_by query")

  Ok(CustomerEntity(name: "John Doe", age: 32))
}

pub fn entity_find_by_test() {
  let entity =
    entity.Entity(
      table: example.table1(),
      transformer: sql.sql_transformer(),
      query: fn(_) { Ok(CustomerEntity(name: "John Doe", age: 32)) },
    )

  entity.find_by(entity, Customer(Name), string("John Doe"))
  |> pprint.format
  |> birdie.snap(title: "find_by")
}
