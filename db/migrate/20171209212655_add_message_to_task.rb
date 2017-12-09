class AddMessageToTask < ActiveRecord::Migration[5.1]
  def change
    add_column :tasks, :message, :string
  end
end
