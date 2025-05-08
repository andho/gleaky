import gleaky.{type SQLValue, type Table}
import gleaky/delete
import gleaky/insert
import gleaky/query
import gleaky/table
import gleaky/transform
import gleaky/update
import gleaky/where
import gleam/dict
import gleam/list
import gleam/result

import gleaky/dml

pub type Entity(
  table,
  transformer_table,
  sel_val,
  where_val,
  where,
  query,
  join,
  entity,
) {
  Entity(
    table: Table(table),
    transformer: transform.Transformer(
      transformer_table,
      sel_val,
      where_val,
      where,
      query,
      join,
    ),
    query: fn(query) -> Result(List(entity), Nil),
    insert: fn(insert.Insert(table)) -> Result(gleaky.SQLScalarValue, Nil),
    execute: fn(dml.DmlQuery(table)) -> Result(Int, Nil),
    encoder: fn(entity) -> dict.Dict(table, gleaky.SQLScalarValue),
    decoder: fn(dict.Dict(table, gleaky.SQLScalarValue)) -> Result(entity, Nil),
  )
}

pub opaque type EntityQuery(
  table,
  transformer_table,
  sel_val,
  where_val,
  where,
  query,
  join,
  entity,
) {
  EntityQuery(
    entity: Entity(
      table,
      transformer_table,
      sel_val,
      where_val,
      where,
      query,
      join,
      entity,
    ),
    query: query.Query(table),
  )
}

pub fn find_by(
  entity: Entity(
    table,
    transformer_table,
    sel_val,
    where_val,
    where,
    query,
    join,
    entity,
  ),
  column: table,
  value: SQLValue(table),
) -> EntityQuery(
  table,
  transformer_table,
  sel_val,
  where_val,
  where,
  query,
  join,
  entity,
) {
  query.query(entity.table)
  |> query.select_columns(table.get_columns(entity.table))
  |> query.where(where.equal(gleaky.column_value(column), value))
  |> fn(query) { EntityQuery(entity:, query:) }
}

pub fn get_all(
  entity_query: EntityQuery(
    table,
    transformer_table,
    sel_val,
    where_val,
    where,
    query,
    join,
    entity,
  ),
) -> Result(List(entity), Nil) {
  entity_query.query
  |> transform.transform(entity_query.entity.transformer)
  |> result.then(entity_query.entity.query)
}

pub fn get_first(
  entity_query: EntityQuery(
    table,
    transformer_table,
    sel_val,
    where_val,
    where,
    query,
    join,
    entity,
  ),
) -> Result(entity, Nil) {
  entity_query.query
  |> transform.transform(entity_query.entity.transformer)
  |> result.then(entity_query.entity.query)
  |> result.then(fn(entities) {
    case entities {
      [entity] -> Ok(entity)
      _ -> Error(Nil)
    }
  })
}

pub fn save(
  entity_definition: Entity(
    table,
    transformer_table,
    sel_val,
    where_val,
    where,
    query,
    join,
    entity,
  ),
  entity: entity,
) {
  let entity_dict =
    entity
    |> entity_definition.encoder
  let pk = table.get_primary_key(entity_definition.table)

  use id_value <- result.try(entity_dict |> dict.get(pk))

  case id_value {
    gleaky.IntValue(id) if id < 0 ->
      save_new(entity_definition, entity, entity_dict, pk)
    _ -> save_existing(entity_definition, entity, entity_dict, pk)
  }
}

pub fn save_new(
  entity_definition: Entity(
    table,
    transformer_table,
    sel_val,
    where_val,
    where,
    query,
    join,
    entity,
  ),
  entity: entity,
  entity_dict: dict.Dict(table, gleaky.SQLScalarValue),
  pk: table,
) {
  let #(columns, values) =
    entity_dict
    |> dict.to_list
    |> list.filter(fn(column_tuple) {
      case column_tuple.0 == pk {
        True -> False
        False -> True
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
      |> dict.insert(pk, pk_value)
      |> entity_definition.decoder
    Error(Nil) -> Error(Nil)
  }
}

fn save_existing(
  entity_definition: Entity(
    table,
    transformer_table,
    sel_val,
    where_val,
    where,
    query,
    join,
    entity,
  ),
  entity: entity,
  entity_dict: dict.Dict(table, gleaky.SQLScalarValue),
  pk: table,
) -> Result(entity, Nil) {
  use pk_value <- result.try(dict.get(entity_dict, pk))
  let result =
    update.update(entity_definition.table)
    |> list.fold(dict.to_list(entity_dict), _, fn(query, column_tuple) {
      case column_tuple.0 == pk {
        True -> query
        False ->
          update.set(query, column_tuple.0, gleaky.ScalarValue(column_tuple.1))
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
  entity_definition: Entity(
    table,
    transformer_table,
    sel_val,
    where_val,
    where,
    query,
    join,
    entity,
  ),
  entity: entity,
) -> Result(Nil, Nil) {
  let entity_dict =
    entity
    |> entity_definition.encoder
  let pk = table.get_primary_key(entity_definition.table)

  use pk_value <- result.try(dict.get(entity_dict, pk))

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
