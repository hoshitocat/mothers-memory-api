# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'pry'
Dir["./models/*.rb"].each { |f| require f }
require "sinatra/activerecord"
require 'line/bot'
require 'dotenv/load'

set :bind, '0.0.0.0'

get '/tasks' do
  tasks = Task.tasks
  { tasks: tasks }.to_json
end

patch '/tasks/:id' do
  begin
    task = Task.find(params[:id])
    json = request.body.read
    @params = JSON.parse(json).symbolize_keys
    if task.update(checked: @params[:checked])
      status 200
      body task.to_json
    else
      status 422
      body task.errors.full_messages
    end
  rescue Exception => err
    status 500
    body err
  end
end

post '/tasks' do
  json = request.body.read
  @params = JSON.parse(json).symbolize_keys
  notification_date = @params[:notification_date] ? @params[:notification_date] : '2017-12-10'
  # TODO: messageは話し言葉に変換したものを入れたい
  task = Task.new(title: @params[:title], notification_date: notification_date, user_id: Task::DEFAULT_USER_ID, message: @params[:title])
  if task.save
    status 200
    body task.to_json
  else
    status 422
    body task.errors.full_messages
  end
end

get '/' do
  content_type :json
  tasks = Task.all
  tasks.to_json
end

post '/line/task' do
  body = request.body.read

  signature = request.env['HTTP_X_LINE_SIGNATURE']
  unless line_client.validate_signature(body, signature)
    error 400 do 'Bad Request' end
  end

  events = line_client.parse_events_from(body)
  events.each { |event|
    case event
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
        Task.create(
          title: event.message['text'],
          notification_date: '2017-12-10',
          user_id: 1
        )
        message = {
          type: 'sticker',
          packageId: 3,
          stickerId: 184
        }
        line_client.reply_message(event['replyToken'], message)
      when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
        response = line_client.get_message_content(event.message['id'])
        tf = Tempfile.open("content")
        tf.write(response.body)
      end
    end
  }

  "OK"
end

def line_client
  @line_client ||= Line::Bot::Client.new { |config|
    config.channel_secret = ENV.fetch('LINE_CHANNEL_SECRET')
    config.channel_token = ENV.fetch('LINE_CHANNEL_TOKEN')
  }
end
