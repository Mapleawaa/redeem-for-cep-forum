# frozen_string_literal: true

class CreateRedeemForCepForumRewards < ActiveRecord::Migration[7.0]
  def change
    create_table :redeem_for_cep_forum_rewards do |t|
      t.integer :user_id, null: false
      t.string :reward_key, null: false
      t.integer :cep_user_id, null: false
      t.integer :trial_days, null: false
      t.string :redeem_code, null: false
      t.boolean :shown_once, null: false, default: false
      t.datetime :issued_at, null: false
      t.datetime :shown_at
      t.string :error_code
      t.timestamps
    end

    add_index :redeem_for_cep_forum_rewards,
              %i[user_id reward_key],
              unique: true,
              name: "idx_redeem_for_cep_forum_rewards_user_reward"
    add_index :redeem_for_cep_forum_rewards, :reward_key
  end
end
