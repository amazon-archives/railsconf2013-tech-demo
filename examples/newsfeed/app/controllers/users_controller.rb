class UsersController < ApplicationController
  include Seahorse::Controller

  def index
    respond_with User.all
  end

  def show
    respond_with User.where(params).first
  end

  def follow
    user1 = User.where(username: params[:username]).first
    user2 = User.where(username: params[:following_username]).first
    user1.following << user2
    respond_with success: true, followed_at: Time.now
  end

  def create
    respond_with User.create(params)
  end
end
