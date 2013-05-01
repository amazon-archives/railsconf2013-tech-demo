# Seahorse

Seahorse is a way to describe your service APIs as first-class citizens with
a declarative DSL. The library also provides Ruby on Rails integration so that
take advantage of your API model in controller actions.

# Features

Seahorse provides the ability to define an API model, but also has functionality
to support parameter validation and serialization of inputs and outputs to API
calls. With Rails integration, this is automatic, namely, parameters in
`params` are automatically type-converted and validated, outputs are
automatically serialized from your API model to JSON or XML. You can also hook
this up to a Sinatra app with a little amount of work.

# Usage

Using Seahorse in a Rails app is pretty easy!

First, define your API model and operations by creating a class like
`Api::Post` in `app/models/api/post.rb` and including `Seahorse::Model`:

```ruby
class Api::Post
  include Seahorse::Model

  # Define a type so you can re-use this later
  type :post do
    model ::Post # Hook up to an AR model
    integer :post_id, as: :id
    string :username, as: [:user, :username]
    string :body
    list(:tags) { tag }
    integer :repost_count, as: [:posts, :count]
    timestamp :created_at
  end

  # The 'index' action in Rails.
  # Also maps to the 'list_posts' command as an RPC call
  operation :index do
    # Define this if you need to map parameters in the URL
    url '/:username/posts'

    # Define some input parameters
    input do
      string :username, uri: true, required: true
      integer :page
    end

    # Define the output parameters
    output do
      # A list of posts
      list(:posts) { post }

      # The page number of the next page
      integer :next_page
    end
  end

  # Other operations here...
end
```

You can generate a JSON description of this API model by calling:

```ruby
puts Api::Post.to_json
```

## Rails Integration

In Rails, you can hook this API model up to routing by adding the following line
in your `config/routes.rb`:

```ruby
Seahorse::Model.add_all_routes(self)
```

This finds all API models defined and hooks them up to your Rails app.
**Note** that in Rails, the Post API model will route to your `PostsController`.

Then you just write Rails code as normal. Here is what the index controller
action might look like on `PostsController`:

```ruby
class PostsController < ApplicationController
  # You need to add this for Seahorse integration
  include Seahorse::Controller

  def index
    # Simple pagination logic
    page_size, page = 20, params[:page] || 1
    offset = (page - 1) * page_size

    # Build the response
    output = { posts: Post.limit(page_size).offset(offset) }
    output[:next_page] = page + 1 if Post.count > (offset + page_size)

    respond_with(output)
  end
end
```

Note that `params[:page]` can be used without calling `.to_i` because Seahorse
already typecasted it to an integer, since your model's input defined it as one.
You no longer have to worry about typecasting values in and out. You simply
take input params and call `respond_with` on the data you want to serialize
out the data you want to display (also defined in your API model).

Here's what a create action might look like:

```ruby
def create
  user = User.where(username: params[:username]).first
  respond_with user.posts.create(params[:post])
end
```

Note that all your parameters are automatically validated and type-converted
according to the inputs you defined in your API model. You don't have to white
list attributes in your model, and you don't need to define strong parameters
either; Seahorse does this all for you.

# Contributing

Feel free to open issues or submit pull requests with any ideas you can think
of to make integrating the Seahorse model into your application an easier
process. This project was initially created as a tech demo for RailsConf 2013
to illustrate some of the principles used to design the client-side SDKs at
Amazon Web Services, so the current breadth of features is fairly minimal.
Feature additions and extra work on the project is welcome!

# License

Seahorse uses the Apache 2.0 License. See LICENSE for details.
