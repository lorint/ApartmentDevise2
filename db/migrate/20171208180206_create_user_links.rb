class CreateUserLinks < ActiveRecord::Migration[5.0]
  def change
    create_table :user_links do |t|
      t.references :user
      t.references :customer, foreign_key: true
      t.references :link_user
      t.references :link_customer
      t.boolean :active

      t.timestamps
    end
  end
end
