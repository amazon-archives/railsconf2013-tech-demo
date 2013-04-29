class Post < ActiveRecord::Base
  belongs_to :user
  has_many :posts
  has_many :tags
  accepts_nested_attributes_for :tags, allow_destroy: true
end
