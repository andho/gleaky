import gleam/dict
import gleam/list
import gleam/result

import gleaky.{type SQLValue, type Table}
import gleaky/ddl.{type Schema}
import gleaky/delete
import gleaky/insert
import gleaky/query
import gleaky/table
import gleaky/update
import gleaky/where

import gleaky/dml

pub type Entity(table, entity) {
  Entity(
    schema: Schema(table),
    table: Table(table),
    query: fn(query.Query(table)) -> Result(List(entity), Nil),
    insert: fn(insert.Insert(table)) -> Result(gleaky.SQLScalarValue, Nil),
    execute: fn(dml.DmlQuery(table)) -> Result(Int, Nil),
    encoder: fn(entity) -> EntityFields(table),
    decoder: fn(EntityFields(table)) -> Result(entity, Nil),
  )
}

pub opaque type EntityQuery(table, entity) {
  EntityQuery(entity: Entity(table, entity), query: query.Query(table))
}

pub fn get_query(entity_query: EntityQuery(table, entity)) -> query.Query(table) {
  entity_query.query
}

pub fn find_by(
  entity: Entity(table, entity),
  column: table,
  value: SQLValue(table),
) -> EntityQuery(table, entity) {
  query.query(entity.table)
  |> query.select_columns(table.get_columns(entity.table))
  |> query.where(where.equal(gleaky.column_value(column), value))
  |> fn(query) { EntityQuery(entity:, query:) }
}

pub fn get_all(
  entity_query: EntityQuery(table, entity),
) -> Result(List(entity), Nil) {
  entity_query.query
  |> entity_query.entity.query
}

pub fn get_first(
  entity_query: EntityQuery(table, entity),
) -> Result(entity, Nil) {
  entity_query.query
  |> entity_query.entity.query
  |> result.then(fn(entities) {
    case entities {
      [entity] -> Ok(entity)
      _ -> Error(Nil)
    }
  })
}

pub fn save(entity_definition: Entity(table, entity), entity: entity) {
  let entity_dict =
    entity
    |> entity_definition.encoder
  let pk = table.get_primary_key(entity_definition.table)

  use id_value <- result.try(entity_dict |> dict.get(pk))

  case id_value {
    Scalar(gleaky.IntValue(id)) if id < 0 ->
      save_new(entity_definition, entity, entity_dict, pk)
    _ -> save_existing(entity_definition, entity, entity_dict, pk)
  }
}

pub fn save_new(
  entity_definition: Entity(table, entity),
  _entity: entity,
  entity_dict: EntityFields(table),
  pk: table,
) {
  let #(columns, values) =
    entity_dict
    |> dict.to_list
    |> list.filter_map(fn(column_tuple) {
      let #(column, value) = column_tuple
      case column == pk, value {
        True, _ -> Error(Nil)
        False, Scalar(scalar) -> Ok(#(column, scalar))
        _, _ -> Error(Nil)
      }
    })
    |> list.unzip

  let result =
    insert.insert(entity_definition.table)
    |> insert.columns(columns)
    |> insert.values(values |> list.map(gleaky.ScalarValue))
    |> insert.returning([pk])
    |> entity_definition.insert

  case result {
    Ok(pk_value) ->
      entity_dict
      |> dict.insert(pk, Scalar(pk_value))
      |> entity_definition.decoder
    Error(Nil) -> Error(Nil)
  }
}

fn save_existing(
  entity_definition: Entity(table, entity),
  entity: entity,
  entity_dict: EntityFields(table),
  pk: table,
) -> Result(entity, Nil) {
  use pk_value <- result.try(
    dict.get(entity_dict, pk)
    |> result.then(fn(value) {
      case value {
        Scalar(scalar) -> Ok(scalar)
        _ -> Error(Nil)
      }
    }),
  )
  let result =
    update.update(entity_definition.table)
    |> list.fold(dict.to_list(entity_dict), _, fn(query, column_tuple) {
      let #(column, value) = column_tuple
      case column == pk, value {
        True, _ -> query
        False, Scalar(scalar) ->
          update.set(query, column_tuple.0, gleaky.ScalarValue(scalar))
        _, _ -> query
      }
    })
    |> update.where(where.equal(
      gleaky.column_value(pk),
      gleaky.ScalarValue(pk_value),
    ))
    |> dml.Update
    |> entity_definition.execute

  case result {
    Ok(_) -> Ok(entity)
    _ -> Error(Nil)
  }
}

pub fn delete(
  entity_definition: Entity(table, entity),
  entity: entity,
) -> Result(Nil, Nil) {
  let entity_dict =
    entity
    |> entity_definition.encoder
  let pk = table.get_primary_key(entity_definition.table)

  use pk_value <- result.try(
    dict.get(entity_dict, pk)
    |> result.then(fn(value) {
      case value {
        Scalar(scalar) -> Ok(scalar)
        _ -> Error(Nil)
      }
    }),
  )

  let result =
    delete.delete(entity_definition.table)
    |> delete.where(where.equal(
      gleaky.column_value(pk),
      gleaky.ScalarValue(pk_value),
    ))
    |> dml.Delete
    |> entity_definition.execute

  case result {
    Ok(_) -> Ok(Nil)
    _ -> Error(Nil)
  }
}

pub type EntityFields(table) =
  dict.Dict(table, Value(table))

pub type Value(table) {
  Scalar(gleaky.SQLScalarValue)
  Many(List(EntityFields(table)))
  One(EntityFields(table))
}

pub fn to_int(value: Value(table)) -> Result(Int, Nil) {
  case value {
    Scalar(gleaky.IntValue(value)) -> Ok(value)
    _ -> Error(Nil)
  }
}

pub fn to_string(value: Value(table)) -> Result(String, Nil) {
  case value {
    Scalar(gleaky.StringValue(value)) -> Ok(value)
    _ -> Error(Nil)
  }
}
