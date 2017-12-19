class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :origin_user_links, -> { where link_customer_id: Customer.current.id }, class_name: "UserLink", foreign_key: :link_user_id
end
