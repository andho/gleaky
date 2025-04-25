import gleam/dict
import gleam/list
import gleam/result

import gleaky.{
  type Column, type SQLScalarValue, type SQLValue, type Table, ColumnValue,
  IntValue, ScalarValue, StringValue,
}
import gleaky/query.{type Query}
import gleaky/table
import gleaky/table/column
import gleaky/where.{type Where}

pub type Transformer(table, sel_val, where_val, where, query, join) {
  Transformer(
    table: fn(String) -> table,
    select_column: fn(String) -> sel_val,
    where_column: fn(String) -> where_val,
    to_string: fn(String) -> where_val,
    to_int: fn(Int) -> where_val,
    eq: fn(where_val, where_val) -> where,
    gt: fn(where_val, where_val) -> where,
    gte: fn(where_val, where_val) -> where,
    lt: fn(where_val, where_val) -> where,
    lte: fn(where_val, where_val) -> where,
    in: fn(where_val, List(where_val)) -> where,
    like: fn(where_val, String) -> where,
    not: fn(where) -> where,
    and: fn(List(where)) -> where,
    or: fn(List(where)) -> where,
    no_where: fn() -> where,
    join: fn(String, where) -> join,
    compose: fn(String, List(sel_val), where, List(join)) -> query,
  )
}

pub fn transform(
  query q: Query(table),
  transformer transformer: Transformer(
    ttable,
    sel_val,
    where_val,
    where,
    query,
    join,
  ),
) -> Result(query, Nil) {
  let table_col_map =
    list.flat_map(q.tables, fn(t) {
      table.get_columns(t)
      |> list.map(fn(column) { #(column.get_column(column), t) })
    })
    |> dict.from_list

  let cols =
    list.flat_map(q.tables, fn(t) {
      table.get_columns(t)
      |> list.map(fn(column) { #(column.get_column(column), column) })
    })
    |> dict.from_list

  let get_column_name = get_column_name_(table_col_map, cols, _)

  let get_sql_val = get_sql_val_(get_column_name, transformer, _)

  use selected_columns <- result.try(
    list.map(q.select, fn(column) {
      get_column_name(column)
      |> result.map(transformer.select_column)
      //  let t = table.get_name(column)
      //  let col = table.get_column(column)
      //  sel.column(t <> col.name)
    })
    |> result.all,
  )

  use twhere <- result.try(transform_where(q.where, get_sql_val, transformer))

  use table_name <- result.try(
    list.reverse(q.tables)
    |> list.first
    |> result.map(table.get_name),
  )
  use joins <- result.try(
    q.joins
    |> list.map(fn(join) {
      let table_name = table.get_name(join.table)
      transform_where(join.on, get_sql_val, transformer)
      |> result.map(fn(where) { transformer.join(table_name, where) })
    })
    |> result.all,
  )

  Ok(transformer.compose(table_name, selected_columns, twhere, joins))
}

fn transform_where(
  where: Where(table),
  get_sql_val: fn(SQLValue(table)) -> Result(where_val, Nil),
  transformer: Transformer(ttable, sel_val, where_val, where, query, join),
) -> Result(where, Nil) {
  let comparison_to_where = fn(
    compare_fn: fn(where_val, where_val) -> where,
    val1: SQLValue(table),
    val2: SQLValue(table),
  ) {
    use val1 <- result.try(get_sql_val(val1))
    use val2 <- result.try(get_sql_val(val2))
    Ok(compare_fn(val1, val2))
  }

  case where {
    where.WhereEquals(value, to_value) ->
      comparison_to_where(transformer.eq, value, to_value)
    where.WhereGreaterThan(value, to_value) ->
      comparison_to_where(transformer.gt, value, to_value)
    where.WhereGreaterThanOrEquals(value, to_value) ->
      comparison_to_where(transformer.gte, value, to_value)
    where.WhereLessThan(value, to_value) ->
      comparison_to_where(transformer.lt, value, to_value)
    where.WhereLessThanOrEquals(value, to_value) ->
      comparison_to_where(transformer.lte, value, to_value)
    where.WhereIn(value, values) -> {
      use val1 <- result.try(get_sql_val(value))
      values
      |> list.map(get_sql_val)
      |> result.all
      |> result.map(fn(vals) { transformer.in(val1, vals) })
    }
    where.WhereLike(value, like_value) ->
      get_sql_val(value)
      |> result.map(fn(val) { transformer.like(val, like_value) })
    where.WhereNot(w) ->
      w
      |> transform_where(get_sql_val, transformer)
      |> result.map(transformer.not)
    where.WhereAnd(wheres) ->
      wheres
      |> list.map(transform_where(_, get_sql_val, transformer))
      |> result.all
      |> result.map(fn(wheres) { transformer.and(wheres) })
    where.WhereOr(wheres) ->
      wheres
      |> list.map(transform_where(_, get_sql_val, transformer))
      |> result.all
      |> result.map(fn(wheres) { transformer.or(wheres) })
    where.NoWhere -> Ok(transformer.no_where())
  }
}

fn get_column_name_(
  table_col_map: dict.Dict(table, Table(table)),
  cols: dict.Dict(table, Column(table)),
  column: table,
) -> Result(String, Nil) {
  use t <- result.try(dict.get(table_col_map, column))
  use col <- result.try(
    dict.get(cols, column)
    |> result.map(fn(c) { column.get_column_name(c) }),
  )
  Ok(table.get_name(t) <> "." <> col)
}

fn get_sql_val_(
  get_column_name: fn(table) -> Result(String, Nil),
  transformer: Transformer(ttable, sel_val, where_val, where, query, join),
  v: SQLValue(table),
) -> Result(where_val, Nil) {
  case v {
    ColumnValue(column) -> {
      get_column_name(column)
      |> result.map(transformer.where_column)
    }
    ScalarValue(scalar_val) -> get_scalar_val(scalar_val, transformer)
  }
}

fn get_scalar_val(
  scalar_val: SQLScalarValue,
  transformer: Transformer(ttable, sel_val, where_val, where, query, join),
) -> Result(where_val, Nil) {
  case scalar_val {
    StringValue(str_val) -> Ok(transformer.to_string(str_val))
    IntValue(int_val) -> Ok(transformer.to_int(int_val))
  }
}
