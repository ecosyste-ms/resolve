module EcosystemsApiClient
  extend ActiveSupport::Concern

  class_methods do
    def ecosystems_connection
      @ecosystems_connection ||= Faraday.new do |faraday|
        faraday.headers['User-Agent'] = 'resolve.ecosyste.ms'
        faraday.headers['X-API-Key'] = ENV['ECOSYSTEMS_API_KEY'] if ENV['ECOSYSTEMS_API_KEY']
        faraday.adapter Faraday.default_adapter
      end
    end
  end

  private

  def ecosystems_connection
    self.class.ecosystems_connection
  end
end