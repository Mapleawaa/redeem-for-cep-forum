# frozen_string_literal: true

RedeemForCepForum::Engine.routes.draw do
  get "/rewards" => "rewards#index"
  post "/rewards/:reward_key/redeem" => "rewards#redeem"
end

Discourse::Application.routes.draw do
  mount ::RedeemForCepForum::Engine, at: "redeem-for-cep-forum"
end
