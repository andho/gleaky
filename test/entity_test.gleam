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
  |> pprint.format
  |> birdie.snap(title: "find_by query")
}

fn test_query(_) {
  Ok([CustomerEntity(name: "John Doe", age: 32)])
}

pub fn entity_find_by_get_all_test() {
  let entity =
    entity.Entity(
      table: example.table1(),
      transformer: sql.sql_transformer(),
      query: fn(_) { Ok([CustomerEntity(name: "John Doe", age: 32)]) },
    )

  entity.find_by(entity, Customer(Name), string("John Doe"))
  |> entity.get_all
  |> pprint.format
  |> birdie.snap(title: "find_by get_all")
}

pub fn entity_find_by_get_first_test() {
  let entity =
    entity.Entity(
      table: example.table1(),
      transformer: sql.sql_transformer(),
      query: fn(_) { Ok([CustomerEntity(name: "John Doe", age: 32)]) },
    )

  entity.find_by(entity, Customer(Name), string("John Doe"))
  |> entity.get_first
  |> pprint.format
  |> birdie.snap(title: "find_by get_first")
}

pub fn entity_find_by_get_first_when_no_result_test() {
  let entity =
    entity.Entity(
      table: example.table1(),
      transformer: sql.sql_transformer(),
      query: fn(_) { Ok([]) },
    )

  entity.find_by(entity, Customer(Name), string("John Doe"))
  |> entity.get_first
  |> pprint.format
  |> birdie.snap(title: "find_by get_first when no result")
}

pub fn entity_find_by_get_first_when_more_than_one_result_test() {
  let entity =
    entity.Entity(
      table: example.table1(),
      transformer: sql.sql_transformer(),
      query: fn(_) {
        Ok([
          CustomerEntity(name: "John Doe", age: 32),
          CustomerEntity(name: "John Doe", age: 83),
        ])
      },
    )

  entity.find_by(entity, Customer(Name), string("John Doe"))
  |> entity.get_first
  |> pprint.format
  |> birdie.snap(title: "find_by get_first when more than one result")
}
