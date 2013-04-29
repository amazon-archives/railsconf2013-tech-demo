class PostsController < ApplicationController
  include Seahorse::Controller

  def index
    page_size, page = 20, params[:page] || 1
    offset = (page - 1) * page_size
    posts = Post.includes(:posts).limit(page_size).offset(offset)
    output = { posts: posts }
    output[:next_page] = page + 1 if Post.count > (offset + page_size)
    respond_with(output)
  end

  def show
    user = User.where(username: params[:username]).first
    post = user.posts.find(params[:post_id])
    respond_with post
  end

  def create
    user = User.where(username: params[:username]).first
    respond_with user.posts.create(params[:post])
  end

  def destroy
    Post.find(params[:post_id]).destroy
    respond_with success: true, deleted_at: Time.now
  end

  def repost
    repost_username = User.where(username: params[:repost_username]).first
    post = Post.find(params[:post_id])
    body = params[:body] || "Repost: #{post.body}"
    respond_with post.posts.create(user_id: repost_username.id, body: body)
  end

  def tag
    user = User.where(username: params[:username]).first
    post = user.posts.find(params[:post_id])
    post.update_attributes(params[:post])
    respond_with post
  end
end
