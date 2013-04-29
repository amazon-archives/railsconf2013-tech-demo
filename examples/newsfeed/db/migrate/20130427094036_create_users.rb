class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :username

      t.timestamps
    end

    create_table :users_users, id: false do |t|
      t.integer :subscriber_id
      t.integer :user_id
    end
  end
end
