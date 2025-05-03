import gleaky.{type SQLValue, type Table}
import gleaky/query
import gleaky/table
import gleaky/transform
import gleaky/where
import gleam/result

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
