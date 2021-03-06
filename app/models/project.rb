# encoding: UTF-8
class Project
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip
  include SimpleEnum::Mongoid

  
  field :title
  field :intro
  field :project_update
  has_many :shouts
  has_many :photos, autosave: true, as: :attachable
  has_many :bookmarkings,:class_name=>"Bookmark", as: :bookmarkable
  has_and_belongs_to_many :project_fields
  has_and_belongs_to_many :project_needs
  
  field :has_patent, type: Boolean
  field :people_count, type: Integer
  
  belongs_to :province
  field :province_id, type: Integer
  has_many :project_memberships
  as_enum :stage, :"概念"=>1,
                  :"开发初期"=>2,
                  :"产品原型"=>3,
                  :"市场化"=>4,
                  :"规模化"=>5
                  
 
    if Rails.env.production?  
      has_mongoid_attached_file :logo,
        :path => ':project_logo/:id/:style.:extension',
        :storage => :s3,
        :bucket => 'talent-search',
        :s3_credentials => {:access_key_id => ENV['S3_KEY'],:secret_access_key => ENV['S3_SECRET']},
        :styles => {
          :original => ['1920x1680>', :jpg],
          :small    => ['30x30#',   :jpg],
          :medium   => ['150x250',    :jpg],
          :large    => ['500x500>',   :jpg]
        }
    else    
      has_mongoid_attached_file :logo,
        :default_url => '/assets/project_logo/:style/missing.jpg',
        :styles => {
          :original => ['1920x1680>', :jpg],
          :small    => ['30x30#',   :jpg],
          :medium   => ['150x250',    :jpg],
          :large    => ['500x500>',   :jpg]
        }
    end
    
  attr_accessible :title, :intro, :logo, :province_id, :stage, :has_patent, :photos_attributes, :people_count, :project_need_ids, :project_field_ids
  validates :people_count, :title, :intro, :province,:province_id, :stage, :presence =>true
  validates_inclusion_of :has_patent, :in => [true, false]
  
  
  accepts_nested_attributes_for :photos, :allow_destroy => true
  
  def add_admin user
    membership = project_memberships.find_or_initialize_by(:user_id=>user.id)
    membership.role_cd= 1
    membership.requested_at = membership.approved_at = Time.now
    membership.save!
  end

  
  def admins
    project_memberships.where(role_cd: 1).map(&:user)
  end
  
  def all_members
    project_memberships.where(:approved_at.ne=>nil).map(&:user)
  end
  
  def pending_applications
    project_memberships.where(approved_at: nil).where(declined_at: nil)
    
  end

   
  def quit user
    project_memberships.where(:user_id=>user.id).destroy_all 
  end
  
  def new_application user
    project_memberships.create!(user_id: user.id, role_cd: 2, requested_at: Time.now)
  end
  
  def status user
    memberships = project_memberships.where(:user_id=>user.id)
    if memberships.empty?
        'new'
    elsif memberships[0].approved_at.nil? && memberships[0].declined_at.nil?
        'pending'
    elsif memberships[0].approved_at.nil? && !memberships[0].declined_at.nil?
        'declined'
    elsif memberships[0].role_cd == 2
        'member'
    else
        'admin'
    end
  end
  
end
