import gleam/bool
import gleam/dict
import gleam/function
import gleam/list
import gleam/option.{type Option, None, Some}

import gleaky.{type Column, type Table, IntColumn, InvalidColumn, StringColumn}
import gleaky/table
import gleaky/table/column

pub type DataType {
  TypeString
  TypeInt
}

pub type DQLValue {
  DQLString(String)
  DQLInt(Int)
}

pub type DQLColumn {
  DQLColumn(
    name: String,
    data_type: DataType,
    nullable: Bool,
    default: Option(DQLValue),
    collate: CollateClause,
  )
}

pub type CollateClause {
  NoCollate
  Collate(String)
}

pub type UniqueSpecification {
  /// todo
  UniqueSpecification
}

pub type CheckConstraint {
  /// todo
  CheckConstraint
}

pub type ColumnConstraint {
  NotNull
  Unique(UniqueSpecification)
  Check(CheckConstraint)
}

pub type ConstraintAttribute {
  /// todo
  ConstraintAttribute
}

pub type OnCommit {
  OnCommitDelete
  OnCommitPreserve
}

pub type TableAttributes {
  OnCommitAttribute(OnCommit)
}

pub type TableIndex {
  NoIndex
}

pub type TableConstraint {
  NoConstraint
}

pub type DQLQuery {
  CreateTable(
    name: String,
    columns: List(DQLColumn),
    attributes: List(TableAttributes),
    indexes: List(TableIndex),
    constraints: List(TableConstraint),
  )
  AlterTable(
    name: String,
    columns: List(DQLAlterColumn),
    attributes: List(TableAttributes),
    indexes: List(TableIndex),
    constraints: List(TableConstraint),
  )
  DropTable(name: String)
}

pub fn create_table(table: Table(table)) -> DQLQuery {
  CreateTable(
    name: table.name,
    columns: list.map(table.columns, column_to_dql_column),
    attributes: [],
    indexes: [],
    constraints: [],
  )
}

fn column_to_dql_column(column: Column(table)) {
  DQLColumn(
    name: column.get_column_name(column),
    data_type: column_to_data_type(column),
    nullable: column.is_nullable(column),
    default: column_to_default(column),
    collate: Collate("utf8"),
  )
}

pub type DQLAlterColumn {
  AddColumn(DQLColumn)
  DropColumn(String)
  AlterColumn(String, DQLColumn)
}

pub fn diff_table(
  created_table: DQLQuery,
  new_table: Table(table),
) -> Result(DQLQuery, Nil) {
  use <- bool.guard(!check_table_name(created_table, new_table), Error(Nil))

  let created_columns = get_column_dict(created_table)
  let new_columns = get_new_column_dict(new_table)

  let all_columns =
    list.unique(list.append(dict.keys(created_columns), dict.keys(new_columns)))

  let to_create =
    list.filter_map(all_columns, fn(column) {
      let created_column = dict.get(created_columns, column)
      let new_column = dict.get(new_columns, column)

      case created_column, new_column {
        Ok(created), Ok(new) ->
          compare_columns(created, column_to_dql_column(new))
        Error(_), Ok(new) -> Ok(AddColumn(column_to_dql_column(new)))
        Ok(created), Error(_) -> Ok(DropColumn(created.name))
        Error(_), Error(_) -> Error(Nil)
      }
    })

  Ok(
    AlterTable(
      name: new_table.name,
      columns: to_create,
      attributes: [],
      indexes: [],
      constraints: [],
    ),
  )
}

fn compare_columns(
  created: DQLColumn,
  new: DQLColumn,
) -> Result(DQLAlterColumn, Nil) {
  use <- bool.guard(
    list.all(
      [
        created.data_type == new.data_type,
        created.nullable == new.nullable,
        created.default == new.default,
      ],
      function.identity,
    ),
    return: Error(Nil),
  )

  Ok(AlterColumn(new.name, new))
}

/// todo compare collate, constraints, etc
fn get_column_dict(created_table: DQLQuery) -> dict.Dict(String, DQLColumn) {
  case created_table {
    CreateTable(_, columns, _, _, _) ->
      list.map(columns, fn(column) { #(column.name, column) })
    _ -> []
  }
  |> dict.from_list
}

fn get_new_column_dict(
  new_table: Table(table),
) -> dict.Dict(String, Column(table)) {
  table.get_columns(new_table)
  |> list.map(fn(column) { #(column.get_column_name(column), column) })
  |> dict.from_list
}

fn check_table_name(created_table: DQLQuery, new_table: Table(table)) -> Bool {
  created_table.name == table.get_name(new_table)
}

fn column_to_data_type(column: Column(table)) -> DataType {
  case column {
    StringColumn(_, _, _) -> TypeString
    IntColumn(_, _, _) -> TypeInt
    InvalidColumn(_, _, _) -> TypeString
  }
}

fn column_to_default(column: Column(table)) -> Option(DQLValue) {
  case column {
    StringColumn(_, _, basics) ->
      case basics.default {
        Some(value) -> Some(DQLString(value))
        None -> None
      }
    IntColumn(_, _, basics) ->
      case basics.default {
        Some(value) -> Some(DQLInt(value))
        None -> None
      }
    InvalidColumn(_, _, _) -> None
  }
}
