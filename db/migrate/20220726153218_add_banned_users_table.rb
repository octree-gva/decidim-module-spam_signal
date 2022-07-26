# frozen_string_literal: true

class AddBannedUsersTable < ActiveRecord::Migration[5.2]
  def change
    create_table :decidim_banned_users do |t|
      t.references :banned_user, foreign_key: { to_table: :decidim_users, on_delete: :nullify }
      t.references :admin_reporter, foreign_key: { to_table: :decidim_users }
      t.datetime :notified_at
      t.datetime :removed_at
      t.string :banned_email, index: true
      t.timestamps
    end
  end
end
