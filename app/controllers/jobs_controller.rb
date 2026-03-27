class JobsController < ApplicationController
  def resolve
    raise ActionController::RoutingError.new('Not Found') if (params[:registry].blank? && params[:ecosystem].blank?) || params[:package_name].blank?
    @job = Job.where(registry: params[:registry], package_name: params[:package_name], before: params[:before], version: version)
                .where.not(status: 'error')
                .order(created_at: :desc)
                .first
    if @job.nil?
      @job = Job.create(registry: params[:registry], ecosystem: params[:ecosystem], package_name: params[:package_name], status: 'pending', ip: request.remote_ip, before: params[:before], version: version, tree: params[:tree] == 'true')
      @job.resolve_async
    end
    redirect_to job_path(@job)
  end

  def show
    @job = Job.find(params[:id])
    @job.check_status if @job.status.in?(%w[pending queued working])
  end

  def version
    return '>= 0' if params[:version].blank?
    params[:version]
  end
end