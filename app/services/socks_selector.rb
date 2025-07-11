require 'new_relic/agent/method_tracer'
class SocksSelector
  include Service

  def initialize(tags, pageNum, pageSize, order)
    @tags = tags
    @pageNum = pageNum
    @pageSize = pageSize
    @order = order
  end

  def call
    @socks = [];
    if @tags.length > 0
      @socks = Sock.joins(sock_tags: :tag).where(tag: { name: @tags}).distinct
    else
      @socks = Sock.all
    end
    if !@pageSize.nil?
      @socks = @socks.slice((@pageNum - 1) * @pageSize.to_i, @pageSize) || []
    end
    return @socks.map { |sock| {
      "id": sock.sock_id,
      "name": sock.name,
      "description": sock.description,
      "price": sock.price,
      "count": sock.count,
      "imageUrl": [sock.image_url_1, sock.image_url_2]
    } }
  end

  class << self
    include ::NewRelic::Agent::MethodTracer
    add_method_tracer :call, 'SocksSelector/call'
  end
end