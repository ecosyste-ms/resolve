class Api::V1::JobsController < Api::V1::ApplicationController
  def create
    @job = Job.new(registry: params[:registry], package_name: params[:package_name], status: 'pending', ip: request.remote_ip)
    if @job.save
      @job.resolve_async
      redirect_to api_v1_job_path(@job)
    else
      error = {
        title: "Bad Request",
        details: @job.errors.full_messages
      }
      render json: error, status: 400
    end
  end

  def show
    @job = Job.find(params[:id])
    @job.check_status
  end

  def formats
    render json: Job.formats
  end
end