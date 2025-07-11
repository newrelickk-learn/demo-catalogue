class Tag < ApplicationRecord
      self.primary_key = :tag_id
      has_many :sock_tags
end
