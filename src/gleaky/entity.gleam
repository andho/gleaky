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
    query: fn(query) -> Result(entity, Nil),
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
) -> Result(entity, Nil) {
  query.query(entity.table)
  |> query.select_columns(table.get_columns(entity.table))
  |> query.where(where.equal(gleaky.column_value(column), value))
  |> transform.transform(entity.transformer)
  |> result.then(entity.query)
}
