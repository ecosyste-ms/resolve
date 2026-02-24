class Api::V1::RegistriesController < Api::V1::ApplicationController
  def index
    @registries = Registry.all.order(:name)
  end
end
