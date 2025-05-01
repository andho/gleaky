import gleaky.{type Table}
import gleaky/where.{type Where}

pub type Delete(table) {
  Delete(table: Table(table), where: Where(table))
}

pub fn delete(table: Table(table)) -> Delete(table) {
  Delete(table: table, where: where.NoWhere)
}

pub fn where(update: Delete(table), where: Where(table)) -> Delete(table) {
  case update.where {
    where.NoWhere -> Delete(..update, where: where)
    where.WhereAnd(wheres) ->
      Delete(..update, where: where.WhereAnd([where, ..wheres]))
    current_where ->
      Delete(..update, where: where.WhereAnd([current_where, where]))
  }
}
