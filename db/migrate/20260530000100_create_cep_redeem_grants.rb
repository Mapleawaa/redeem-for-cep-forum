# frozen_string_literal: true

class CreateCepRedeemGrants < ActiveRecord::Migration[6.1]
  def change
    create_table :cep_redeem_grants do |t|
      t.integer :user_id, null: false
      t.string :username, null: false
      t.integer :cep_user_id
      t.integer :reward_level, null: false
      t.integer :user_trust_level, null: false
      t.integer :total_trial_days, null: false
      t.string :status, null: false, default: "pending"
      t.jsonb :redeem_codes, null: false, default: []
      t.string :error_code
      t.text :error_message
      t.integer :attempts, null: false, default: 0
      t.datetime :issued_at
      t.datetime :delivered_at
      t.datetime :failed_at

      t.timestamps
    end

    add_index :cep_redeem_grants, %i[user_id reward_level], unique: true
    add_index :cep_redeem_grants, :status
    add_index :cep_redeem_grants, :cep_user_id
  end
end
