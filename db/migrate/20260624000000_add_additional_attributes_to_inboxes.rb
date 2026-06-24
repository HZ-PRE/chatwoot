class AddAdditionalAttributesToInboxes < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :additional_attributes, :jsonb, default: {}, null: false
  end
end
