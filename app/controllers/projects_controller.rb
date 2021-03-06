class ProjectsController < ApplicationController
  before_action :set_project, only: [:show, :edit, :update, :destroy,:bump,:like]
  before_action :set_pending_requests, only: [:edit]

  before_action :authenticate_user!, except: [:show, :index]
  before_action :authorize_user, only: [:edit, :update, :destroy,:bump]
  before_action :confirmed?, except: [:show, :index]
  # GET /projects
  # GET /projects.json
  def index
    if params[:search]
      @projects = Project.tagged_with(params[:search]).order("bumped_at DESC").paginate(:page => params[:page])
    else 
      @projects = Project.order("bumped_at DESC").paginate(:page => params[:page])
    end 
  end

  # GET /projects/1
  # GET /projects/1.json
  def show
  end

  # GET /projects/new
  def new
    @project = current_user.projects.build
  end

  # GET /projects/1/edit
  def edit
  end

  # POST /projects
  # POST /projects.json
  def create
    @project = current_user.projects.build(project_params)
    @project.memberships.new(user: current_user,role:'Creator')
    respond_to do |format|
      if @project.save
        format.html { redirect_to @project, notice: 'Project was successfully created.' }
        format.json { render :show, status: :created, location: @project }
      else
        format.html { render :new }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /projects/1
  # PATCH/PUT /projects/1.json
  def update
    respond_to do |format|
      if @project.update(project_params)
        format.html { redirect_to @project, notice: 'Project was successfully updated.' }
        format.json { render :show, status: :ok, location: @project }
      else
        format.html { render :edit }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /projects/1
  # DELETE /projects/1.json
  def destroy
    @project.destroy
    respond_to do |format|
      format.html { redirect_to projects_url, notice: 'Project was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def like
    @project.upvote_by current_user
    redirect_to @project
  end

  def bump
    if ((DateTime.now.to_i - @project.bumped_at.to_i ) / 1.hours) >= 24 
      @project.bumped_at = DateTime.now
      respond_to do |format|
        if @project.save
          format.html { redirect_to @project, notice: 'Project was bumped.' }
        else
          format.html { redirect_to @project, notice: 'Something went wrong' }
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to @project, notice: 'Too early' }
      end
    end  
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_project
      @project = Project.find(params[:id])
    end

    def set_pending_requests
      @pending_requests = @project.requests.select { |req| req[:status] == 'pending'  }
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def project_params
      params.require(:project).permit(:name, :description, :short_description,:tag_list,:slack,:trello)
    end

    def authorize_user
      @project = current_user.projects.find_by(id: params[:id])
      redirect_to projects_path, notice: "Not authorized to edit this project" if @project.nil?
    end

    def confirmed?
      redirect_to root_path, notice: "Confirm your email" unless current_user.confirmed?
    end
end
