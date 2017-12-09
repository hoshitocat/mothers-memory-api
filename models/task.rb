# frozen_string_literal: true

require 'sinatra/activerecord'

class Task < ActiveRecord::Base
  # TODO: ハッカソンで利用するUserID
  #       一旦最初はUserの概念は気にしない(作成しない)
  DEFAULT_USER_ID = 1
  class << self
    def tasks
      where(user_id: DEFAULT_USER_ID)
    end
  end
end
