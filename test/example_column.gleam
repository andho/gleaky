import gleaky.{StringColumn}
import gleaky/table/column

import example

pub fn example_column() {
  StringColumn(
    example.Customer(example.Name),
    name: "name",
    constraints: column.default_constraints(),
  )
}
