import glundrisse.{type SQLValue}

pub type Where(table) {
  NoWhere
  WhereAnd(List(Where(table)))
  WhereOr(List(Where(table)))
  WhereNot(Where(table))
  WhereEquals(SQLValue(table), SQLValue(table))
  WhereGreaterThan(SQLValue(table), SQLValue(table))
  WhereGreaterThanOrEquals(SQLValue(table), SQLValue(table))
  WhereLessThan(SQLValue(table), SQLValue(table))
  WhereLessThanOrEquals(SQLValue(table), SQLValue(table))
  WhereIn(SQLValue(table), List(SQLValue(table)))
  WhereLike(SQLValue(table), SQLValue(table))
}

pub fn equal(
  value: SQLValue(table),
  to to_value: SQLValue(table),
) -> Where(table) {
  WhereEquals(value, to_value)
}

pub fn not(where: Where(table)) -> Where(table) {
  WhereNot(where)
}

pub fn greater_than(
  value: SQLValue(table),
  to to_value: SQLValue(table),
) -> Where(table) {
  WhereGreaterThan(value, to_value)
}

pub fn greater_than_or_equals(
  value: SQLValue(table),
  to to_value: SQLValue(table),
) -> Where(table) {
  WhereGreaterThanOrEquals(value, to_value)
}

pub fn less_than(
  value: SQLValue(table),
  to to_value: SQLValue(table),
) -> Where(table) {
  WhereLessThan(value, to_value)
}

pub fn less_than_or_equals(
  value: SQLValue(table),
  to to_value: SQLValue(table),
) -> Where(table) {
  WhereLessThanOrEquals(value, to_value)
}

pub fn in(value: SQLValue(table), values: List(SQLValue(table))) -> Where(table) {
  WhereIn(value, values)
}

pub fn like(
  value: SQLValue(table),
  like like_value: SQLValue(table),
) -> Where(table) {
  WhereLike(value, like_value)
}

pub fn and(wheres: List(Where(table))) -> Where(table) {
  WhereAnd(wheres)
}

pub fn or(wheres: List(Where(table))) -> Where(table) {
  WhereOr(wheres)
}
