class HomeController < ApplicationController
  def index
    @registries = Registry.all.order(:name)
  end
end