class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    before_action :tracking
    rescue_from Exception, with: :handle_exception
    def handle_exception(_e)
      raise Exception, _e.message.gsub(/"/, ''), _e.backtrace
    end

    def tracking
        @userParam = params[:user]
        ::NewRelic::Agent.add_custom_attributes({ user: params[:user] })
    end
end