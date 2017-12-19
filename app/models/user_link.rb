class UserLink < ApplicationRecord
  belongs_to :user
  belongs_to :customer
  belongs_to :link_user, class_name: "User"
  belongs_to :link_customer, class_name: "Customer", inverse_of: :origin_user_links

  scope :active, -> { where(active: true) }

  after_initialize do
    if self.new_record?
      self.active = true
    end
  end
end
