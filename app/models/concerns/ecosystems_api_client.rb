module EcosystemsApiClient
  extend ActiveSupport::Concern

  class_methods do
    def ecosystems_connection
      @ecosystems_connection ||= Faraday.new do |faraday|
        faraday.headers['User-Agent'] = 'resolve.ecosyste.ms'
        faraday.adapter Faraday.default_adapter
      end
    end
  end

  private

  def ecosystems_connection
    self.class.ecosystems_connection
  end
end