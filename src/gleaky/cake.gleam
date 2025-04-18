import cake/internal/read_query
import cake/join as j
import cake/select as s
import cake/where as w

import gleaky/transform

pub fn cake_transformer() {
  transform.Transformer(
    table: fn(x) { x },
    select_column: s.col,
    where_column: w.col,
    to_string: w.string,
    to_int: w.int,
    eq: w.eq,
    gt: w.gt,
    gte: w.gte,
    lt: w.lt,
    lte: w.lte,
    in: w.in,
    like: w.like,
    not: w.not,
    and: w.and,
    or: w.or,
    join: fn(table_name, where) {
      j.inner(j.table(table_name), on: where, alias: table_name)
    },
    compose: fn(
      table: String,
      selects: List(read_query.SelectValue),
      wheres: read_query.Where,
      joins: List(read_query.Join),
    ) {
      s.new()
      |> s.from_table(table)
      |> s.selects(selects)
      |> s.where(wheres)
      |> s.joins(joins)
      |> s.to_query
    },
  )
}
