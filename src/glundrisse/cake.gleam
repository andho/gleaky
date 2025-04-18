import cake/join as j
import cake/select as s
import cake/where as w
import gleam/dict
import gleam/list
import gleam/result

import glundrisse.{type Column, type Table}
import glundrisse/query.{type Query}
import glundrisse/table
import glundrisse/table/column

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
      let #(val, cond) = join.on
      let w_lhs = case val {
        query.ColumnValue(column) -> {
          let assert Ok(t) = dict.get(table_col_map, column)
          let col =
            dict.get(cols, column)
            |> result.map(fn(c) { column.get_column_name(c) })
            |> result.unwrap("Invalid column")
          w.col(table.get_name(t) <> "." <> col)
        }
        _ -> w.col("invalid_table")
      }

      let w_rhs = case cond {
        query.Equals(sql_val) -> w.eq(
          _,
          get_sql_val(table_col_map, cols, sql_val),
        )
        query.NotEquals(sql_val) -> fn(x) {
          w.not(w.eq(x, get_sql_val(table_col_map, cols, sql_val)))
        }
        query.GreaterThan(sql_val) -> w.gt(
          _,
          get_sql_val(table_col_map, cols, sql_val),
        )
        query.GreaterThanOrEquals(sql_val) -> w.gte(
          _,
          get_sql_val(table_col_map, cols, sql_val),
        )
        query.LessThan(sql_val) -> w.lt(
          _,
          get_sql_val(table_col_map, cols, sql_val),
        )
        query.LessThanOrEquals(sql_val) -> w.lte(
          _,
          get_sql_val(table_col_map, cols, sql_val),
        )
        query.Like(sql_val) -> w.like(_, get_sql_val_string(sql_val))
        query.NotLike(sql_val) -> fn(x) {
          w.not(w.like(x, get_sql_val_string(sql_val)))
        }
        query.In(sql_val) -> w.in(
          _,
          get_sql_val_list(table_col_map, cols, sql_val),
        )
        query.NotIn(sql_val) -> fn(x) {
          w.in(x, get_sql_val_list(table_col_map, cols, sql_val))
        }
      }

      let on = w_rhs(w_lhs)

      s.join(sel, j.inner(with: j.table(table_name), on:, alias: table_name))
    })
  })
  |> result.map(s.to_query)
}

fn get_sql_val(
  table_col_map: dict.Dict(table, Table(table)),
  cols: dict.Dict(table, Column(table)),
  v: query.SQLValue(table),
) {
  case v {
    query.ColumnValue(column) -> {
      let assert Ok(t) = dict.get(table_col_map, column)
      let col =
        dict.get(cols, column)
        |> result.map(fn(c) { column.get_column_name(c) })
        |> result.unwrap("Invalid column")
      w.col(table.get_name(t) <> "." <> col)
    }
    query.StringValue(str_val) -> w.string(str_val)
    query.IntValue(int_val) -> w.int(int_val)
  }
}

fn get_sql_val_string(v: query.SQLValue(table)) {
  case v {
    query.StringValue(str_val) -> str_val
    _ -> "Invalid string"
  }
}

fn get_sql_val_list(
  table_col_map: dict.Dict(table, Table(table)),
  cols: dict.Dict(table, Column(table)),
  v: List(query.SQLValue(table)),
) {
  v
  |> list.map(get_sql_val(table_col_map, cols, _))
}
