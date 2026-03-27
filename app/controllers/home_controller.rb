class HomeController < ApplicationController
  def index
    @registries = Registry.supported.order(:name)
  end
end