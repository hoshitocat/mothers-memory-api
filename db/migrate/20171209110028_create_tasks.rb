class CreateTasks < ActiveRecord::Migration[5.1]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.datetime :notification_date
      t.boolean :checked, null: false, default: false
      t.float :weight, null: false, default: 0.5
      t.integer :user_id, null: false
      t.integer :frequency, null: false, default: 0
      t.float :notification_threshold, null: false, default: 0.5

      t.timestamps
    end
  end
end