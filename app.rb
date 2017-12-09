# frozen_string_literal: true

require 'sinatra'

# bind serve
set :bind, '0.0.0.0'

get '/' do
    'Hello, World!'
end