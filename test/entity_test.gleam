import gleam/dict
import gleam/result

import birdie
import pprint

import gleaky.{string}
import gleaky/entity
import gleaky/sql

import example.{Address, AddressCustomer, AddressId, City, Street}

pub type AddressEntity {
  AddressEntity(id: Int, city: String, street: String, customer_id: Int)
}

fn address_entity_decoder(
  row: dict.Dict(example.Tables, gleaky.SQLScalarValue),
) -> Result(AddressEntity, Nil) {
  use id <- result.try(
    dict.get(row, Address(AddressId))
    |> result.then(gleaky.to_int),
  )
  use street <- result.try(
    dict.get(row, Address(Street))
    |> result.then(gleaky.to_string),
  )
  use city <- result.try(
    dict.get(row, Address(City))
    |> result.then(gleaky.to_string),
  )
  use customer_id <- result.try(
    dict.get(row, Address(AddressCustomer))
    |> result.then(gleaky.to_int),
  )
  Ok(AddressEntity(id:, street:, city:, customer_id:))
}

fn address_encoder(
  address: AddressEntity,
) -> dict.Dict(example.Tables, gleaky.SQLScalarValue) {
  let AddressEntity(id:, street:, city:, customer_id:) = address
  dict.from_list([
    #(Address(AddressId), gleaky.IntValue(id)),
    #(Address(Street), gleaky.StringValue(street)),
    #(Address(City), gleaky.StringValue(city)),
    #(Address(AddressCustomer), gleaky.IntValue(customer_id)),
  ])
}

fn dummy_query(_) {
  Ok([
    AddressEntity(
      id: 1,
      street: "Majeedhee Magu",
      city: "Male'",
      customer_id: 1,
    ),
  ])
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
      table: example.table2(),
      transformer: sql.sql_transformer(),
      query: dummy_query,
      execute: dummy_execute,
      encoder: address_encoder,
      insert: dummy_insert,
      decoder: address_entity_decoder,
    )

  entity.find_by(entity, Address(Street), string("Majeedhee Magu"))
  |> pprint.format
  |> birdie.snap(title: "find_by query")
}

pub fn entity_find_by_get_all_test() {
  let entity =
    entity.Entity(
      table: example.table2(),
      transformer: sql.sql_transformer(),
      query: fn(_) {
        Ok([
          AddressEntity(
            id: 2,
            street: "Majeedhee Magu",
            city: "Male'",
            customer_id: 1,
          ),
          AddressEntity(
            id: 3,
            street: "Majeedhee Magu",
            city: "Male'",
            customer_id: 1,
          ),
        ])
      },
      execute: dummy_execute,
      encoder: address_encoder,
      insert: dummy_insert,
      decoder: address_entity_decoder,
    )

  entity.find_by(entity, Address(Street), string("Majeedhee Magu"))
  |> entity.get_all
  |> pprint.format
  |> birdie.snap(title: "find_by get_all")
}

pub fn entity_find_by_get_first_test() {
  let entity =
    entity.Entity(
      table: example.table2(),
      transformer: sql.sql_transformer(),
      query: fn(_) {
        Ok([
          AddressEntity(
            id: 2,
            street: "Majeedhee Magu",
            city: "Male'",
            customer_id: 1,
          ),
        ])
      },
      execute: dummy_execute,
      encoder: address_encoder,
      insert: dummy_insert,
      decoder: address_entity_decoder,
    )

  entity.find_by(entity, Address(Street), string("Majeedhee Magu"))
  |> entity.get_first
  |> pprint.format
  |> birdie.snap(title: "find_by get_first")
}

pub fn entity_find_by_get_first_when_no_result_test() {
  let entity =
    entity.Entity(
      table: example.table2(),
      transformer: sql.sql_transformer(),
      query: fn(_) { Ok([]) },
      execute: dummy_execute,
      encoder: address_encoder,
      insert: dummy_insert,
      decoder: address_entity_decoder,
    )

  entity.find_by(entity, Address(Street), string("Majeedhee Magu"))
  |> entity.get_first
  |> pprint.format
  |> birdie.snap(title: "find_by get_first when no result")
}

pub fn entity_find_by_get_first_when_more_than_one_result_test() {
  let entity =
    entity.Entity(
      table: example.table2(),
      transformer: sql.sql_transformer(),
      query: fn(_) {
        Ok([
          AddressEntity(
            id: 2,
            street: "Majeedhee Magu",
            city: "Male'",
            customer_id: 1,
          ),
          AddressEntity(
            id: 3,
            street: "Majeedhee Magu",
            city: "Male'",
            customer_id: 1,
          ),
        ])
      },
      execute: dummy_execute,
      encoder: address_encoder,
      insert: dummy_insert,
      decoder: address_entity_decoder,
    )

  entity.find_by(entity, Address(Street), string("Majeedhee Magu"))
  |> entity.get_first
  |> pprint.format
  |> birdie.snap(title: "find_by get_first when more than one result")
}

pub fn save_entity_query_test() {
  let entity =
    entity.Entity(
      table: example.table2(),
      transformer: sql.sql_transformer(),
      query: dummy_query,
      execute: dummy_execute,
      encoder: address_encoder,
      insert: fn(query) {
        query
        |> pprint.format
        |> birdie.snap(title: "save entity query")
        Ok(gleaky.IntValue(100))
      },
      decoder: address_entity_decoder,
    )

  entity.save(
    entity,
    AddressEntity(
      id: -1,
      street: "Majeedhee Magu",
      city: "Male'",
      customer_id: 1,
    ),
  )
}

pub fn save_entity_test() {
  let entity =
    entity.Entity(
      table: example.table2(),
      transformer: sql.sql_transformer(),
      query: dummy_query,
      execute: dummy_execute,
      encoder: address_encoder,
      insert: dummy_insert,
      decoder: address_entity_decoder,
    )

  entity.save(
    entity,
    AddressEntity(
      id: -1,
      street: "Majeedhee Magu",
      city: "Male'",
      customer_id: 1,
    ),
  )
  |> pprint.format
  |> birdie.snap(title: "save entity")
}

pub fn save_existing_entity_should_update_query_test() {
  let entity =
    entity.Entity(
      table: example.table2(),
      transformer: sql.sql_transformer(),
      query: dummy_query,
      execute: fn(query) {
        query
        |> pprint.format
        |> birdie.snap(title: "save existing entity query")
        Ok(1)
      },
      encoder: address_encoder,
      insert: dummy_insert,
      decoder: address_entity_decoder,
    )

  entity.save(
    entity,
    AddressEntity(
      id: 100,
      street: "Majeedhee Magu",
      city: "Male'",
      customer_id: 1,
    ),
  )
}

pub fn delete_entity_test() {
  let entity =
    entity.Entity(
      table: example.table2(),
      transformer: sql.sql_transformer(),
      query: dummy_query,
      execute: fn(query) {
        query
        |> pprint.format
        |> birdie.snap(title: "delete entity query")
        Ok(1)
      },
      encoder: address_encoder,
      insert: dummy_insert,
      decoder: address_entity_decoder,
    )

  entity.delete(
    entity,
    AddressEntity(
      id: 100,
      street: "Majeedhee Magu",
      city: "Male'",
      customer_id: 1,
    ),
  )
}
