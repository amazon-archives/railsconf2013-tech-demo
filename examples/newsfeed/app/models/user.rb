class User < ActiveRecord::Base
  has_many :posts
  has_and_belongs_to_many :followers, class_name: "User",
    foreign_key: :subscriber_id, association_foreign_key: :user_id
  has_and_belongs_to_many :following, class_name: "User",
    association_foreign_key: :subscriber_id
end
