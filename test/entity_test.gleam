import gleam/dict
import gleam/dynamic/decode
import gleam/result

import birdie
import pprint

import gleaky.{int, string}
import gleaky/entity
import gleaky/sql

import example.{Age, Customer, CustomerId, Name}

pub type CustomerEntity {
  CustomerEntity(id: Int, name: String, age: Int)
}

fn customer_entity_decoder(
  row: dict.Dict(example.Tables, gleaky.SQLScalarValue),
) -> Result(CustomerEntity, Nil) {
  use id <- result.try(
    dict.get(row, Customer(CustomerId))
    |> result.then(gleaky.to_int),
  )
  use name <- result.try(
    dict.get(row, Customer(Name))
    |> result.then(gleaky.to_string),
  )
  use age <- result.try(
    dict.get(row, Customer(Age))
    |> result.then(gleaky.to_int),
  )
  Ok(CustomerEntity(id:, name:, age:))
}

fn customer_encoder(
  customer: CustomerEntity,
) -> dict.Dict(example.Tables, gleaky.SQLScalarValue) {
  let CustomerEntity(id, name, age) = customer
  dict.from_list([
    #(Customer(CustomerId), gleaky.IntValue(id)),
    #(Customer(Name), gleaky.StringValue(name)),
    #(Customer(Age), gleaky.IntValue(age)),
  ])
}

fn dummy_query(_) {
  Ok([CustomerEntity(id: 1, name: "John Doe", age: 32)])
}

pub fn dummy_execute(_) {
  Ok(0)
}

fn dummy_insert(_) -> Result(gleaky.SQLScalarValue, Nil) {
  Ok(gleaky.IntValue(100))
}

pub fn entity_find_by_query_test() {
  let entity =
    entity.Entity(
      table: example.table1(),
      transformer: sql.sql_transformer(),
      query: dummy_query,
      execute: dummy_execute,
      encoder: customer_encoder,
      insert: dummy_insert,
      decoder: customer_entity_decoder,
    )

  entity.find_by(entity, Customer(Name), string("John Doe"))
  |> pprint.format
  |> birdie.snap(title: "find_by query")
}

pub fn entity_find_by_get_all_test() {
  let entity =
    entity.Entity(
      table: example.table1(),
      transformer: sql.sql_transformer(),
      query: fn(_) {
        Ok([
          CustomerEntity(id: 2, name: "John Doe", age: 32),
          CustomerEntity(id: 3, name: "John Doe", age: 83),
        ])
      },
      execute: dummy_execute,
      encoder: customer_encoder,
      insert: dummy_insert,
      decoder: customer_entity_decoder,
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
      query: fn(_) { Ok([CustomerEntity(id: 2, name: "John Doe", age: 32)]) },
      execute: dummy_execute,
      encoder: customer_encoder,
      insert: dummy_insert,
      decoder: customer_entity_decoder,
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
      execute: dummy_execute,
      encoder: customer_encoder,
      insert: dummy_insert,
      decoder: customer_entity_decoder,
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
          CustomerEntity(id: 2, name: "John Doe", age: 32),
          CustomerEntity(id: 3, name: "John Doe", age: 83),
        ])
      },
      execute: dummy_execute,
      encoder: customer_encoder,
      insert: dummy_insert,
      decoder: customer_entity_decoder,
    )

  entity.find_by(entity, Customer(Name), string("John Doe"))
  |> entity.get_first
  |> pprint.format
  |> birdie.snap(title: "find_by get_first when more than one result")
}

pub fn save_entity_query_test() {
  let entity =
    entity.Entity(
      table: example.table1(),
      transformer: sql.sql_transformer(),
      query: dummy_query,
      execute: fn(query) {
        query
        |> pprint.format
        |> birdie.snap(title: "save entity query")
        Ok(1)
      },
      encoder: customer_encoder,
      insert: dummy_insert,
      decoder: customer_entity_decoder,
    )

  entity.save(entity, CustomerEntity(id: -1, name: "John Doe", age: 32))
}

pub fn save_entity_test() {
  let entity =
    entity.Entity(
      table: example.table1(),
      transformer: sql.sql_transformer(),
      query: dummy_query,
      execute: dummy_execute,
      encoder: customer_encoder,
      insert: dummy_insert,
      decoder: customer_entity_decoder,
    )

  entity.save(entity, CustomerEntity(id: -1, name: "John Doe", age: 32))
  |> pprint.format
  |> birdie.snap(title: "save entity")
}
