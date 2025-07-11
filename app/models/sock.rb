class Sock < ApplicationRecord
  self.primary_key = :sock_id
  has_many :sock_tags
end