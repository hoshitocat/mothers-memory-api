require 'sinatra'
require 'sinatra/reloader' if development?
require 'pry'
Dir["./models/*.rb"].each { |f| require f }
require "sinatra/activerecord"
require 'line/bot'
require 'dotenv/load'
require 'natto'

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
  task = Task.new(title: @params[:title], notification_date: notification_date, user_id: Task::DEFAULT_USER_ID, message: (convert_message(@params[:title]) << '?'))
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
        if event.message['text'] == 'タスク教えて'
          message = {
            type: 'text',
            text: "わたしが知ってるのはこれよ\n" +
            Task.tasks.pluck(:title).map { |task| "・#{task}" }.join("\n")
          }
        else
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
        end
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

def convert_message(msg)
  enum = mecab_natto.enum_parse(msg)
  arr = enum.map {|n| n.feature.split(',') if !n.is_eos? }.compact
  arr.reverse.each { |v| break if v[1] == '動詞'; arr.pop }
  generate_string(arr)
end

def generate_string(arr)
  arr.each_with_object('') do |a, str|
    if a[1] == '動詞'
      str << convert_question_msg(a[2])
    else
      str << a[0]
    end
  end
end

def convert_question_msg(str)
  case
  when str[-2..-1] == 'する'
    str.gsub('する', 'した')
  when str[-1] == 'る'
    str.gsub('る', 'た')
  else
    s = str[0...-1] + (str[-1].ord - 2).chr("UTF-8")
    case s[-1]
    when 'い', 'ち', 'り'
      s.gsub(/い|ち|り/, 'った')
    when 'に', 'び', 'み'
      s.gsub(/に|び|み/, 'んだ')
    when 'し'
      s.gsub('し', 'した')
    when 'き'
      s.gsub('き', 'いた')
    when 'ぎ'
      s.gsub('ぎ', 'いだ')
    end
  end
end

def mecab_natto
  @mn ||= Natto::MeCab.new('-F%m,%f[0],%f[6]')
end
