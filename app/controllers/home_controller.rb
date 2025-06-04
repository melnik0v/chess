class HomeController < ActionController::Base
  layout 'main'

  def index
    render inline: '', layout: 'main'
  end
end
