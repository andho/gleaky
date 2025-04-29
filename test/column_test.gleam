import birdie
import gleaky/table/column
import pprint

import example_column.{example_column}

pub fn unique_test() {
  example_column()
  |> column.unique
  |> pprint.format
  |> birdie.snap(title: "define unique column")
}

pub fn not_unique_test() {
  example_column()
  |> pprint.format
  |> birdie.snap(title: "define not unique column")
}
