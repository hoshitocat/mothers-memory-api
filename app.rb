# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'pry'
Dir["./models/*.rb"].each { |f| require f }

set :bind, '0.0.0.0'

get '/tasks' do
  tasks = Task.tasks
  { tasks: tasks }.to_json
end

patch '/tasks/:id' do
  'hoge'
end

post '/tasks' do
  json = request.body.read
  parse_params = JSON.parse(json).symbolize_keys
  task = Task.new(title: parse_params[:title], notification_date: parse_params[:notification_date], user_id: Task::DEFAULT_USER_ID)
  if task.save
    status 200
    body task.to_json
  else
    status 422
    body task.errors.full_messages
  end
end
