class TodoController < ApplicationController
  before_filter :authenticate_user!

  def index
		if current_user.todo_items.empty?
			TodoItem.create(:user_id => current_user.id, :complete => false, :description => 'New')
		end
  end

  def ajax_save
    p params

    old_todos = current_user.todo_items.find(:all)

    if old_todos.find { |item| item.updated_at.to_i > params['timestamp'].to_i }
      render :text => 'invalid'
      return
    end

    params[:data].each do |n, item|
      TodoItem.create(:user_id => current_user.id, :complete => (item['complete'] == 'true'), :description => item['description'])
    end

    old_todos.each(&:destroy)
    render :json => { :timestamp => Time.now.to_i }
  end
end
