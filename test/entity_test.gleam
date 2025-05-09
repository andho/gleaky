import gleam/dict
import gleam/list
import gleam/result

import birdie
import pprint

import gleaky.{string}
import gleaky/entity.{type EntityFields, Many, One, Scalar}
import gleaky/sql

import example.{
  Address, AddressCustomer, AddressId, Age, City, Customer, CustomerId, Name,
  Street,
}

pub type AddressEntity {
  AddressEntity(id: Int, city: String, street: String, customer_id: Int)
}

pub type CustomerEntity {
  CustomerEntity(
    id: Int,
    name: String,
    age: Int,
    addresses: List(AddressEntity),
  )
}

fn address_entity_decoder(
  row: EntityFields(example.Tables),
) -> Result(AddressEntity, Nil) {
  use id <- result.try(
    dict.get(row, Address(AddressId))
    |> result.then(entity.to_int),
  )
  use street <- result.try(
    dict.get(row, Address(Street))
    |> result.then(entity.to_string),
  )
  use city <- result.try(
    dict.get(row, Address(City))
    |> result.then(entity.to_string),
  )
  use customer_id <- result.try(
    dict.get(row, Address(AddressCustomer))
    |> result.then(entity.to_int),
  )
  Ok(AddressEntity(id:, street:, city:, customer_id:))
}

fn address_encoder(address: AddressEntity) -> EntityFields(example.Tables) {
  let AddressEntity(id:, street:, city:, customer_id:) = address
  dict.from_list([
    #(Address(AddressId), Scalar(gleaky.IntValue(id))),
    #(Address(Street), Scalar(gleaky.StringValue(street))),
    #(Address(City), Scalar(gleaky.StringValue(city))),
    #(Address(AddressCustomer), Scalar(gleaky.IntValue(customer_id))),
  ])
}

fn customer_entity_decoder(
  row: EntityFields(example.Tables),
) -> Result(CustomerEntity, Nil) {
  use id <- result.try(
    dict.get(row, Customer(CustomerId))
    |> result.then(entity.to_int),
  )
  use name <- result.try(
    dict.get(row, Customer(Name))
    |> result.then(entity.to_string),
  )
  use age <- result.try(
    dict.get(row, Customer(Age))
    |> result.then(entity.to_int),
  )
  use addresses <- result.try(
    dict.get(row, Address(AddressId))
    |> result.then(fn(value) {
      case value {
        Many(addresses) -> {
          addresses
          |> list.map(address_entity_decoder)
          |> result.all
        }
        _ -> Error(Nil)
      }
    }),
  )
  Ok(CustomerEntity(id:, name:, age:, addresses:))
}

fn dummy_query(_) {
  Ok([
    dict.from_list([
      #(Address(AddressId), Scalar(gleaky.IntValue(1))),
      #(Address(Street), Scalar(gleaky.StringValue("Majeedhee Magu"))),
      #(Address(City), Scalar(gleaky.StringValue("Male'"))),
      #(Address(AddressCustomer), Scalar(gleaky.IntValue(1))),
    ]),
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
      schema: example.schema(),
      table: example.table2(),
      query: dummy_query,
      execute: dummy_execute,
      encoder: address_encoder,
      insert: dummy_insert,
      decoder: address_entity_decoder,
    )

  entity.find_by(entity, Address(Street), string("Majeedhee Magu"))
  |> entity.get_query
  |> pprint.format
  |> birdie.snap(title: "find_by query")
}

pub fn entity_find_by_get_all_test() {
  let entity =
    entity.Entity(
      schema: example.schema(),
      table: example.table2(),
      query: fn(_) {
        Ok([
          address_encoder(AddressEntity(
            id: 2,
            street: "Majeedhee Magu",
            city: "Male'",
            customer_id: 1,
          )),
          address_encoder(AddressEntity(
            id: 3,
            street: "Majeedhee Magu",
            city: "Male'",
            customer_id: 1,
          )),
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
      schema: example.schema(),
      table: example.table2(),
      query: fn(_) {
        Ok([
          address_encoder(AddressEntity(
            id: 2,
            street: "Majeedhee Magu",
            city: "Male'",
            customer_id: 1,
          )),
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
      schema: example.schema(),
      table: example.table2(),
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
      schema: example.schema(),
      table: example.table2(),
      query: fn(_) {
        Ok([
          address_encoder(AddressEntity(
            id: 2,
            street: "Majeedhee Magu",
            city: "Male'",
            customer_id: 1,
          )),
          address_encoder(AddressEntity(
            id: 3,
            street: "Majeedhee Magu",
            city: "Male'",
            customer_id: 1,
          )),
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
      schema: example.schema(),
      table: example.table2(),
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
      schema: example.schema(),
      table: example.table2(),
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
      schema: example.schema(),
      table: example.table2(),
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
      schema: example.schema(),
      table: example.table2(),
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
//pub fn save_entity_with_relationship_query_test() {
//  let entity1 =
//    entity.Entity(
//schema: example.schema(),
//      table: example.table1(),
//      query: dummy_query,
//      execute: dummy_execute,
//      encoder: address_encoder,
//      insert: fn(query) {
//        query
//        |> pprint.format
//        |> birdie.snap(title: "save entity query")
//        Ok(gleaky.IntValue(100))
//      },
//      decoder: address_entity_decoder,
//    )
//  let entity2 =
//    entity.Entity(
//      table: example.table2(),
//      transformer: sql.sql_transformer(),
//      query: dummy_query,
//      execute: dummy_execute,
//      encoder: address_encoder,
//      insert: fn(query) {
//        query
//        |> pprint.format
//        |> birdie.snap(title: "save entity query")
//        Ok(gleaky.IntValue(100))
//      },
//      decoder: address_entity_decoder,
//    )
//
//  entity.save(
//    entity,
//    AddressEntity(
//      id: -1,
//      street: "Majeedhee Magu",
//      city: "Male'",
//      customer_id: 1,
//    ),
//  )
//}
