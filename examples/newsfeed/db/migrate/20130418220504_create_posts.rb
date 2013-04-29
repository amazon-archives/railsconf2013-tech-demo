class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.string :body
      t.belongs_to :user
      t.belongs_to :post
      t.timestamps
    end
  end
end
