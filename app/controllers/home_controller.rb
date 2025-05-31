class HomeController < ActionController::Base
  layout 'main'
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern # Возможно, эту строку тоже стоит перенести, если она нужна только здесь

  def index
    render inline: '', layout: 'main'
  end
end
