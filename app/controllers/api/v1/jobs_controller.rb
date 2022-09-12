class Api::V1::JobsController < Api::V1::ApplicationController
  def create
    p params
    @job = Job.new(registry: params[:registry], package_name: params[:package_name], status: 'pending', ip: request.remote_ip)
    p @job
    # p @job.registry.codepoints
    # p Registry.all_names.first.codepoints
    p @job.registry == Registry.all_names.first
    
    p @job.save
    p @job.errors.full_messages
    if @job.id
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