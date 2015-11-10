class RedirectPresenter
  attr_reader :redirect

  def initialize(redirect)
    @redirect = redirect
  end

  def render_for_publishing_api
    {
      content_id: redirect.content_id,
      format: 'redirect',
      publishing_app: 'collections-publisher',
      update_type: 'major',
      redirects: redirect_routes,
      links: {
        replaced_content_item: [redirect.tag.content_id]
      }
    }
  end

  def base_path
    redirect.original_tag_base_path
  end

private

  def redirect_routes
    redirect.redirect_routes.map do |redirect_route|
      {
        path: redirect_route.from_base_path,
        destination: redirect_route.to_base_path,
        type: 'exact',
      }
    end
  end
end
