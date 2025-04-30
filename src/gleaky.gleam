import gleam/dict

@internal
pub type Table(table) {
  Table(
    name: String,
    columns: List(table),
    column_map: dict.Dict(table, Column(table)),
  )
}

pub type TableBuilder(table, column) {
  TableBuilder(
    table: fn(column) -> table,
    name: String,
    columns: List(Column(table)),
  )
}

pub type Column(table) {
  StringColumn(
    column: table,
    name: String,
    constraints: ColumnConstraint(table),
  )
  IntColumn(column: table, name: String, constraints: ColumnConstraint(table))
  InvalidColumn(
    column: table,
    name: String,
    constraints: ColumnConstraint(table),
  )
}

pub type SQLValue(table) {
  ColumnValue(table)
  ScalarValue(SQLScalarValue)
}

pub type SQLScalarValue {
  StringValue(String)
  IntValue(Int)
}

pub type ColumnConstraint(table) {
  ColumnConstraint(
    nullable: Nullable,
    foreign_key: ForeignKey(table),
    default: Default,
    primary_key: PrimaryKey,
    unique: Unique,
  )
}

/// Primary key index parameters are not supported yet
pub type PrimaryKey {
  PrimaryKey
  NotPrimaryKey
}

pub type Unique {
  Unique
  NotUnique
}

pub type Nullable {
  Null
  NotNull
}

pub type Default {
  Default(SQLScalarValue)
  NoDefault
}

pub type ForeignKey(table) {
  ForeignKey(
    columns: List(table),
    on_delete: OnDelete(table),
    on_update: OnUpdate(table),
  )
  NoForeignKey
}

/// Cascade rules are specified for `OnDelete` and `OnUpdate` clauses for foreign
/// key / references.
pub type CascadeRule(a) {
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
  SetNull(List(a))
  /// Set the related foreign key fields to their default value. You can specify a subset of
  /// the fields to be set to defaults.
  ///
  /// SQL equivalent:
  /// ```
  /// SET DEFAULT (author_id)
  /// ```
  SetDefault(List(a))
}

pub type OnDelete(a) {
  OnDelete(CascadeRule(a))
  NoOnDelete
}

pub type OnUpdate(a) {
  OnUpdate(CascadeRule(a))
  NoOnUpdate
}

pub fn string(value: String) -> SQLValue(table) {
  ScalarValue(StringValue(value))
}

pub fn int(value: Int) -> SQLValue(table) {
  ScalarValue(IntValue(value))
}

pub fn column_value(column: table) -> SQLValue(table) {
  ColumnValue(column)
}
