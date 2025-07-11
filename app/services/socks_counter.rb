class SocksCounter
  include Service

  def initialize(tags)
    @tags = tags
  end

  def call
    @socks = [];
    if @tags.length > 0
      @socks = Sock.joins(sock_tags: :tag).where(tag: { name: @tags.map { |tag| tag.strip! ? tag.strip! : tag }}).distinct
    else
      @socks = Sock.all
    end
    return { size: @socks.size }
  end

end