class Api::V1::RegistriesController < Api::V1::ApplicationController
  def index
    @registries = Registry.supported.order(:name)
  end
end
