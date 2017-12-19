class Customer < ApplicationRecord
  has_many :user_links,
    dependent: :destroy
  has_many :origin_user_links, class_name: "UserLink", foreign_key: :link_customer_id, inverse_of: :link_customer,
    dependent: :destroy
  before_validation :downcase_subdomain
  after_create :create_customer_tenant

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  after_initialize :set_defaults

  def set_defaults
    self.active ||= true if self.new_record?
  end

  def self.current
    Customer.active.find_by(subdomain: Apartment::Tenant.current)
  end

  # Find any destination links for a given user in this customer
  def destination_user_links(user)
    return nil if self.subdomain == Apartment::Tenant.current
    UserLink.where(link_customer_id: self.id, link_user_id: user.id)
  end

  private
  def create_customer_tenant
    Apartment::Tenant.create(subdomain)
  end

  def downcase_subdomain
    if self.subdomain
      self.subdomain.downcase!
    end
  end
end
