import gleam/option.{type Option}

pub type Table(table) {
  Table(name: String, columns: List(Column(table)))
}

pub type TableBuilder(table, column) {
  TableBuilder(
    table: fn(column) -> table,
    name: String,
    columns: List(Column(table)),
  )
}

pub type ColumnBasics(column) {
  ColumnBasics(default: Option(column), nullable: Bool)
}

pub type Column(table) {
  StringColumn(column: table, name: String, basics: ColumnBasics(String))
  IntColumn(column: table, name: String, basics: ColumnBasics(Int))
  InvalidColumn(column: table, name: String)
}
