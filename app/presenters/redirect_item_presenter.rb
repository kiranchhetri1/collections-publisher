class RedirectItemPresenter
  attr_reader :item

  def initialize(item)
    @item = item
  end

  def content_id
    item.content_id
  end

  def base_path
    item.from_base_path
  end

  def redirect_routes
    [ item ]
  end

  def draft?
    false
  end

  def archived?
    true
  end

  def render_for_publishing_api
    {
      content_id: content_id,
      base_path: base_path,
      format: 'redirect',
      publishing_app: 'collections-publisher',
      redirects: RedirectRoutePresenter.new(self).routes,
    }
  end
end