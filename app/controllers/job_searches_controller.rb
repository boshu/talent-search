#encoding: UTF-8
class JobSearchesController < ApplicationController
  include ApplicationHelper
  
  
  def show
    @user = current_user
    if params[:id]
      @search = JobSearch.find(params[:id]) 
      @job_posts = Kaminari.paginate_array(@search.matching_jobs).page(params[:page]).per(10)
    else 
      @search = JobSearch.new
      @is_new = true
      @job_posts = Kaminari.paginate_array(@user.matches).page(params[:page]).per(10)
    end

  end

  def create
    @search = JobSearch.create(params[:job_search])
    redirect_to @search
  end

  def update
    @search = JobSearch.create(params[:job_search])
    redirect_to @search
  end


end
