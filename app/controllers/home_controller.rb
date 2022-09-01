class HomeController < ApplicationController
  def index
    @registries = Registry.all
  end
end