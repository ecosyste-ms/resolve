class JobsController < ApplicationController
  def resolve
    raise ActionController::RoutingError.new('Not Found') if params[:registry].blank? || params[:package_name].blank?
    @job = Job.find_by(registry: params[:registry], package_name: params[:package_name])
    if @job.nil?
      @job = Job.create(registry: params[:registry], package_name: params[:package_name], status: 'pending', ip: request.remote_ip, before: params[:before])
      @job.resolve_async
    end
  end
end