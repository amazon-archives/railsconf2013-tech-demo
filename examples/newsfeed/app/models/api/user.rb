class Api::User
  include Seahorse::Model

  type :username => :string

  type :user do
    model ::User
    username
    list(:followers) { username as: :username }
    integer :followers_count, as: [:followers, :count]
    list(:following) { username as: :username }
    integer :following_count, as: [:following, :count]
    timestamp :created_at
  end

  operation :create do
    url '/:username'

    input do
      string :username, uri: true, required: true
    end

    output :user
  end

  operation :follow do
    url '/:username/follow/:following_username'
    verb :post

    input do
      string :username, uri: true, required: true
      string :following_username, uri: true, required: true
    end

    output do
      boolean :success
      timestamp :followed_at
    end
  end

  operation :index do
    output(:list) { username as: [:user, :username] }
  end

  operation :show do
    url '/:username'
    input { string :username, uri: true, required: true }
    output :user
  end
end
