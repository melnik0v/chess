class CreatePasskeys < ActiveRecord::Migration[8.0]
  def change
    create_table :passkeys do |t|
      t.references :user, null: false, foreign_key: true
      t.binary :external_id
      t.binary :public_key
      t.string :nickname
      t.integer :sign_count
      t.datetime :last_used_at

      t.timestamps
    end
  end
end
