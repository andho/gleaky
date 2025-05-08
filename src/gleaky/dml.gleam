import gleaky/delete
import gleaky/insert
import gleaky/update

pub type DmlQuery(table) {
  Insert(insert.Insert(table))
  Update(update.Update(table))
  Delete(delete.Delete(table))
}
