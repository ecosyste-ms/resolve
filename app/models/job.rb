require 'timeout'

class Job < ApplicationRecord
  validates_presence_of :package_name, :registry
  validates_uniqueness_of :id
  validates :registry, inclusion: Registry.pluck(:name)

  scope :status, ->(status) { where(status: status) }

  def self.check_statuses
    Job.where(status: ["queued", "working"]).find_each(&:check_status)
  end

  def check_status
    return if sidekiq_id.blank?
    return if finished?
    update(status: fetch_status)
  end

  def fetch_status
    Sidekiq::Status.status(sidekiq_id).presence || 'error'
  end

  def finished?
    ['complete', 'error'].include?(status)
  end

  def resolve_async
    sidekiq_id = ResolveDependenciesWorker.perform_async(id)
    update(sidekiq_id: sidekiq_id)
  end

  def resolve
    begin
      Timeout::timeout(60) do
        source = EcosystemsPackageSource.new({ package_name => '>=0 ' }, registry)
      solver = PubGrub::VersionSolver.new(source: source)
      result = solver.solve  
      update(status: 'complete', results: result)
      end
    rescue => e
      update(results: {error: e.inspect}, status: 'error')
    end
  end
end
