import birdie
import pprint

import gleaky.{int}
import gleaky/insert

import example.{Age, Customer}

pub fn insert_test() {
  insert.insert(example.table1())
  |> insert.columns([Customer(Age)])
  |> insert.values([int(1)])
  |> pprint.format
  |> birdie.snap(title: "insert")
}
