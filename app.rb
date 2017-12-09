# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
Dir["./models/*.rb"].each { |f| require f }

set :bind, '0.0.0.0'

get '/' do
  @tasks = Task.tasks
  { tasks: @tasks }.to_json
end
