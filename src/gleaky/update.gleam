import gleam/dict

import gleaky.{type SQLValue, type Table}
import gleaky/where.{type Where}

pub type Update(table) {
  Update(
    table: Table(table),
    set: dict.Dict(table, SQLValue(table)),
    where: Where(table),
  )
}

pub fn update(table: Table(table)) -> Update(table) {
  Update(table: table, set: dict.new(), where: where.NoWhere)
}

pub fn set(
  update: Update(table),
  column: table,
  value: SQLValue(table),
) -> Update(table) {
  Update(..update, set: dict.insert(update.set, column, value))
}

pub fn where(update: Update(table), where: Where(table)) -> Update(table) {
  case update.where {
    where.NoWhere -> Update(..update, where: where)
    where.WhereAnd(wheres) ->
      Update(..update, where: where.WhereAnd([where, ..wheres]))
    current_where ->
      Update(..update, where: where.WhereAnd([current_where, where]))
  }
}
