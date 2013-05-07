class Api::Post
  include Seahorse::Model

  type :post => :structure do
    model ::Post
    integer :post_id, as: :id
    string :username, as: [:user, :username]
    string :body
    list(:tags) { tag }
    integer :repost_count, as: [:posts, :count]
    timestamp :created_at
  end

  type :post_details => :post do
    list :reposts, as: :posts do
      structure do
        integer :post_id, as: :id
        string :username, as: [:user, :username]
        string :body
      end
    end
  end

  type :tag => :structure do
    model Tag
    string :name
  end

  type :post_id => :structure do
    string :username, uri: true, required: true
    integer :post_id, uri: true, required: true, as: :id
  end

  desc "Creates a new post"
  operation :create do
    url '/:username/posts'

    input do
      desc "The username to create a post for"
      string :username, uri: true, required: true

      structure :post do
        desc "The body contents of the post"
        string :body, required: true

        list(:tags) { tag }
      end
    end

    output :post
  end

  operation :repost do
    url '/:username/posts/:post_id/repost/:repost_username'
    verb :post

    input do
      string :username, uri: true, required: true
      string :repost_username, uri: true, required: true
      integer :post_id, uri: true, required: true, as: :id
      string :body
    end

    output :post
  end

  operation :tag do
    url '/:username/posts/:post_id/tag'

    input :post_id do
      structure :post do
        list(:tags) { tag }
      end
    end

    output :post
  end

  operation :destroy do
    url '/:username/posts/:post_id'

    input :post_id

    output do
      boolean :success
      timestamp :deleted_at
    end
  end

  operation :index do
    url '/:username/posts'

    input do
      string :username, uri: true, required: true
      integer :page
    end

    output do
      list(:posts) { post }
      integer :next_page
    end
  end

  operation :show do
    url '/:username/posts/:post_id'

    input :post_id
    output :post_details
  end
end
