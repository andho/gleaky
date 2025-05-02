import gleam/int
import gleam/string

import gleaky/transform

pub fn sql_transformer() {
  transform.Transformer(
    table: fn(table: String) { table },
    select_column: fn(col: String) { col },
    where_column: fn(col: String) { col },
    to_string: fn(str: String) { "'" <> str <> "'" },
    to_int: fn(int: Int) -> String { int.to_string(int) },
    eq: fn(val1: String, val2: String) { val1 <> " = " <> val2 },
    gt: fn(val1: String, val2: String) { val1 <> " > " <> val2 },
    gte: fn(val1: String, val2: String) { val1 <> " >= " <> val2 },
    lt: fn(val1: String, val2: String) { val1 <> " < " <> val2 },
    lte: fn(val1: String, val2: String) { val1 <> " <= " <> val2 },
    in: fn(val1: String, vals: List(String)) {
      val1
      <> " IN ("
      <> {
        vals
        |> string.join(", ")
      }
      <> ")"
    },
    like: fn(val1: String, like: String) { val1 <> " LIKE " <> like },
    not: fn(where: String) { "NOT " <> where },
    and: fn(wheres: List(String)) {
      "( "
      <> {
        wheres
        |> string.join(" AND ")
      }
      <> " )"
    },
    or: fn(wheres: List(String)) {
      "( "
      <> {
        wheres
        |> string.join(" OR ")
      }
      <> " )"
    },
    no_where: fn() { "" },
    join: fn(table_name, where) {
      "INNER JOIN " <> table_name <> " ON " <> where
    },
    compose: fn(
      table: String,
      selects: List(String),
      wheres: String,
      joins: List(String),
    ) {
      "SELECT "
      <> {
        selects
        |> string.join(", ")
      }
      <> " FROM "
      <> table
      <> " "
      <> {
        joins
        |> string.join(" ")
      }
      <> " WHERE "
      <> wheres
    },
  )
}
