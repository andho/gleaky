import gleam/bool
import gleam/dict
import gleam/function
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result

import gleaky.{type Column, type Table}
import gleaky/table
import gleaky/table/column

pub type DataType {
  TypeString(Option(Int))
  TypeInt
}

pub type DDLColumn {
  DDLColumn(
    name: String,
    data_type: DataType,
    collate: CollateClause,
    constraints: ColumnConstraint,
  )
}

pub type ColumnConstraint {
  ColumnConstraint(
    nullable: gleaky.Nullable,
    foreign_key: gleaky.ForeignKey(String),
    default: gleaky.Default,
  )
}

pub type DDLForeignKey {
  ForeignKey(columns: List(String), on_delete: OnDelete, on_update: OnUpdate)
  NoForeignKey
}

/// Cascade rules are specified for `OnDelete` and `OnUpdate` clauses for foreign
/// key / references.
pub type CascadeRule {
  /// Deletes the related rows
  Cascade
  /// Restricts the deletion of the row if the constraint is violated upon
  /// deletion.
  Restrict
  /// Set the related foreign key fields to null. You can specify a subset of
  /// the fields to be set to null.
  ///
  /// SQL equivalent:
  /// ```
  /// SET NULL (author_id)
  /// ```
  SetNull(List(String))
  /// Set the related foreign key fields to their default value. You can specify a subset of
  /// the fields to be set to defaults.
  ///
  /// SQL equivalent:
  /// ```
  /// SET DEFAULT (author_id)
  /// ```
  SetDefault(List(String))
}

pub type OnDelete {
  OnDelete(CascadeRule)
  NoOnDelete
}

pub type OnUpdate {
  OnUpdate(CascadeRule)
  NoOnUpdate
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

pub type CreateTable {
  CreateTable(
    name: String,
    columns: List(DDLColumn),
    attributes: List(TableAttributes),
    indexes: List(TableIndex),
    constraints: List(TableConstraint),
  )
}

pub type AlterTable {
  AlterTable(
    name: String,
    columns: List(DDLAlterColumn),
    attributes: List(TableAttributes),
    indexes: List(TableIndex),
    constraints: List(TableConstraint),
  )
}

pub type DropTable {
  DropTable(name: String)
}

pub type DDLQuery {
  Create(CreateTable)
  Alter(AlterTable)
  Drop(DropTable)
}

pub fn create_table(table: Table(table)) -> CreateTable {
  CreateTable(
    name: table.name,
    columns: list.map(table.columns, column_to_dql_column(table, _)),
    attributes: [],
    indexes: [],
    constraints: [],
  )
}

fn column_to_dql_column(table: Table(table), column: Column(table)) {
  DDLColumn(
    name: column.get_column_name(column),
    data_type: column_to_data_type(column),
    collate: Collate("utf8"),
    constraints: column_to_constraints(table, column),
  )
}

pub type DDLAlterColumn {
  AddColumn(DDLColumn)
  DropColumn(String)
  AlterColumn(name: String, old: DDLColumn, new: DDLColumn)
}

pub fn diff_table(
  created_table: CreateTable,
  new_table: Table(table),
) -> Result(AlterTable, Nil) {
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
          compare_columns(created, column_to_dql_column(new_table, new))
        Error(_), Ok(new) -> Ok(AddColumn(column_to_dql_column(new_table, new)))
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

pub fn merge_ddl(create: CreateTable, queries: List(AlterTable)) {
  list.fold(queries, create, fn(create, alter) {
    let #(new_columns, alter_columns, drop_columns) =
      split_alter_columns(alter.columns)

    let columns =
      list.append(create.columns, new_columns)
      |> list.filter(fn(column) {
        list.contains(drop_columns, column.name)
        |> bool.negate
      })
      |> list.map(fn(column) {
        {
          use #(_, _, alter_column) <- result.try(
            list.find(alter_columns, fn(alter_column) {
              alter_column.0 == column.name
            }),
          )
          Ok(alter_column)
        }
        |> result.unwrap(column)
      })

    CreateTable(..create, columns: columns)
  })
}

pub fn split_alter_columns(
  alter_columns: List(DDLAlterColumn),
) -> #(List(DDLColumn), List(#(String, DDLColumn, DDLColumn)), List(String)) {
  split_alter_column_recursive(alter_columns, #([], [], []))
}

fn split_alter_column_recursive(
  alter_columns: List(DDLAlterColumn),
  split_columns: #(
    List(DDLColumn),
    List(#(String, DDLColumn, DDLColumn)),
    List(String),
  ),
) -> #(List(DDLColumn), List(#(String, DDLColumn, DDLColumn)), List(String)) {
  case alter_columns {
    [] -> split_columns
    [AddColumn(column), ..rest] ->
      split_alter_column_recursive(rest, #(
        [column, ..split_columns.0],
        split_columns.1,
        split_columns.2,
      ))
    [AlterColumn(column_name, old_column, new_column), ..rest] ->
      split_alter_column_recursive(rest, #(
        split_columns.0,
        [#(column_name, old_column, new_column), ..split_columns.1],
        split_columns.2,
      ))
    [DropColumn(column), ..rest] ->
      split_alter_column_recursive(
        rest,
        #(split_columns.0, split_columns.1, [column, ..split_columns.2]),
      )
  }
}

fn compare_columns(
  created: DDLColumn,
  new: DDLColumn,
) -> Result(DDLAlterColumn, Nil) {
  use <- bool.guard(
    created.data_type == new.data_type && created.constraints == new.constraints,
    return: Error(Nil),
  )

  Ok(AlterColumn(new.name, created, new))
}

/// todo compare collate, constraints, etc
fn get_column_dict(created_table: CreateTable) -> dict.Dict(String, DDLColumn) {
  list.map(created_table.columns, fn(column) { #(column.name, column) })
  |> dict.from_list
}

fn get_new_column_dict(
  new_table: Table(table),
) -> dict.Dict(String, Column(table)) {
  table.get_columns(new_table)
  |> list.map(fn(column) { #(column.get_column_name(column), column) })
  |> dict.from_list
}

fn check_table_name(created_table: CreateTable, new_table: Table(table)) -> Bool {
  created_table.name == table.get_name(new_table)
}

fn column_to_data_type(column: Column(table)) -> DataType {
  case column {
    gleaky.StringColumn(_, _, _) -> TypeString(None)
    gleaky.IntColumn(_, _, _) -> TypeInt
    gleaky.InvalidColumn(_, _, _) -> TypeString(None)
  }
}

fn column_to_constraints(
  table: Table(table),
  column: Column(table),
) -> ColumnConstraint {
  let foreign_key = case column.constraints.foreign_key {
    gleaky.ForeignKey(columns, on_delete, on_update) ->
      gleaky.ForeignKey(
        columns: columns_to_string(table, columns),
        on_delete: on_delete_to_ddl(table, on_delete),
        on_update: on_update_to_ddl(table, on_update),
      )
    gleaky.NoForeignKey -> gleaky.NoForeignKey
  }
  ColumnConstraint(
    nullable: column.constraints.nullable,
    foreign_key:,
    default: column.constraints.default,
  )
}

fn columns_to_string(table: Table(table), columns: List(table)) -> List(String) {
  let cols =
    table.get_columns(table)
    |> list.map(fn(column) { #(column.get_column(column), column) })
    |> dict.from_list
  list.map(columns, fn(fq_col_name) {
    use column <- result.try(dict.get(cols, fq_col_name))

    Ok(column.get_column_name(column))
  })
  |> result.all
  |> result.unwrap([])
}

fn cascade_rule_to_ddl(
  table: Table(table),
  cascade_rule: gleaky.CascadeRule(table),
) -> gleaky.CascadeRule(String) {
  case cascade_rule {
    gleaky.SetNull(columns) -> gleaky.SetNull(columns_to_string(table, columns))
    gleaky.SetDefault(columns) ->
      gleaky.SetDefault(columns_to_string(table, columns))
    gleaky.Cascade -> gleaky.Cascade
    gleaky.Restrict -> gleaky.Restrict
  }
}

fn on_delete_to_ddl(
  table: Table(table),
  on_delete: gleaky.OnDelete(table),
) -> gleaky.OnDelete(String) {
  case on_delete {
    gleaky.OnDelete(cascade_rule) ->
      gleaky.OnDelete(cascade_rule_to_ddl(table, cascade_rule))
    gleaky.NoOnDelete -> gleaky.NoOnDelete
  }
}

fn on_update_to_ddl(
  table: Table(table),
  on_update: gleaky.OnUpdate(table),
) -> gleaky.OnUpdate(String) {
  case on_update {
    gleaky.OnUpdate(cascade_rule) ->
      gleaky.OnUpdate(cascade_rule_to_ddl(table, cascade_rule))
    gleaky.NoOnUpdate -> gleaky.NoOnUpdate
  }
}
