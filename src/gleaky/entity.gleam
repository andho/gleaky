import gleaky.{type SQLValue, type Table}
import gleaky/insert
import gleaky/query
import gleaky/table
import gleaky/transform
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

  let #(columns, values) =
    entity_dict
    |> dict.to_list
    |> list.unzip

  let pk = table.get_primary_key(entity_definition.table)

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
