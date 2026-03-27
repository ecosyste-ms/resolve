require 'open3'

class Job < ApplicationRecord
  PACKAGE_NAME_PATTERN = /\A[@a-zA-Z0-9][\w\-\.\/\:]*\z/

  validates_presence_of :package_name
  validates_uniqueness_of :id
  validates_format_of :package_name, with: PACKAGE_NAME_PATTERN, message: "contains invalid characters", allow_blank: true
  validates_length_of :package_name, maximum: 255
  validate :registry_or_ecosystem_present

  attr_accessor :ecosystem, :tree

  def registry_or_ecosystem_present
    if registry.blank? && ecosystem.blank?
      errors.add(:base, "Either registry or ecosystem must be provided")
    end
    if registry.present? && !Registry.all_names.include?(registry)
      errors.add(:registry, "is not included in the list")
    end
  end

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

  def self.resolve_binary
    ENV.fetch('RESOLVE_BINARY', 'resolve')
  end

  def resolve
    args = [self.class.resolve_binary]
    args += ["--registry", registry] if registry.present?
    args += ["--ecosystem", ecosystem] if ecosystem.present?
    args += ["--package", package_name]
    args += ["--version", version] if version.present? && version != ">= 0"
    args += ["--tree"] if tree

    stdout, stderr, status = Open3.capture3(*args)

    if status.success?
      update(status: 'complete', results: JSON.parse(stdout))
    else
      error_info = JSON.parse(stderr) rescue { error: stderr }
      update(results: error_info, status: 'error')
    end
  rescue => e
    update(results: { error: e.inspect }, status: 'error')
  end
end
