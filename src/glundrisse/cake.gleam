import cake/internal/read_query
import cake/join as j
import cake/select as s
import cake/where as w
import gleam/dict
import gleam/list
import gleam/result

import glundrisse.{
  type Column, type SQLValue, type Table, ColumnValue, IntValue, StringValue,
}
import glundrisse/query.{type Query}
import glundrisse/table
import glundrisse/table/column
import glundrisse/where.{type Where, NoWhere}

pub fn transform(q: Query(table)) {
  let sel = s.new()

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

  let to_where_val = get_sql_val(table_col_map, cols, _)

  let sel =
    s.selects(
      sel,
      list.map(q.select, fn(column) {
        let assert Ok(t) = dict.get(table_col_map, column)
        let col =
          dict.get(cols, column)
          |> result.map(fn(c) { column.get_column_name(c) })
          |> result.unwrap("Invalid column")
        s.col(table.get_name(t) <> "." <> col)
        //  let t = table.get_name(column)
        //  let col = table.get_column(column)
        //  sel.column(t <> col.name)
      }),
    )

  list.reverse(q.tables)
  |> list.first
  |> result.map(fn(t) { s.from_table(sel, table.get_name(t)) })
  |> result.map(fn(sel) {
    q.joins
    |> list.fold(sel, fn(sel, join) {
      let table_name = table.get_name(join.table)
      let on = where_to_cake_w(join.on, to_where_val)

      s.join(sel, j.inner(with: j.table(table_name), on:, alias: table_name))
    })
  })
  |> result.map(s.to_query)
}

fn get_sql_val(
  table_col_map: dict.Dict(table, Table(table)),
  cols: dict.Dict(table, Column(table)),
  v: SQLValue(table),
) {
  case v {
    ColumnValue(column) -> {
      let assert Ok(t) = dict.get(table_col_map, column)
      let col =
        dict.get(cols, column)
        |> result.map(fn(c) { column.get_column_name(c) })
        |> result.unwrap("Invalid column")
      w.col(table.get_name(t) <> "." <> col)
    }
    StringValue(str_val) -> w.string(str_val)
    IntValue(int_val) -> w.int(int_val)
  }
}

fn get_sql_val_string(v: SQLValue(table)) -> String {
  case v {
    StringValue(str_val) -> str_val
    _ -> "Invalid string"
  }
}

fn get_sql_val_list(
  to_where_val: fn(SQLValue(table)) -> read_query.WhereValue,
  v: List(SQLValue(table)),
) {
  v
  |> list.map(to_where_val)
}

fn where_to_cake_w(
  where: Where(table),
  to_where_val: fn(SQLValue(table)) -> read_query.WhereValue,
) {
  case where {
    NoWhere -> w.none()
    where.WhereAnd(wheres) ->
      w.and(list.map(wheres, where_to_cake_w(_, to_where_val)))
    where.WhereOr(wheres) ->
      w.or(list.map(wheres, where_to_cake_w(_, to_where_val)))
    where.WhereNot(where) -> w.not(where_to_cake_w(where, to_where_val))
    where.WhereEquals(value, to_value) ->
      w.eq(to_where_val(value), to_where_val(to_value))
    where.WhereGreaterThan(value, to_value) ->
      w.gt(to_where_val(value), to_where_val(to_value))
    where.WhereGreaterThanOrEquals(value, to_value) ->
      w.gte(to_where_val(value), to_where_val(to_value))
    where.WhereLessThan(value, to_value) ->
      w.lt(to_where_val(value), to_where_val(to_value))
    where.WhereLessThanOrEquals(value, to_value) ->
      w.lte(to_where_val(value), to_where_val(to_value))
    where.WhereIn(value, values) ->
      w.in(to_where_val(value), get_sql_val_list(to_where_val, values))
    where.WhereLike(value, like_value) ->
      w.like(to_where_val(value), get_sql_val_string(like_value))
  }
}
