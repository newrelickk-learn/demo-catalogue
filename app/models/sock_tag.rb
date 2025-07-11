class SockTag < ApplicationRecord
      belongs_to :sock, primary_key: :sock_id
      belongs_to :tag, primary_key: :tag_id
end
