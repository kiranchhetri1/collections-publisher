class TagPresenter
  delegate :legacy_tag_type, :base_path, :draft?, :archived?, to: :tag

  def self.presenter_for(tag)
    case tag
    when MainstreamBrowsePage
      case tag.state
      when 'published', 'draft'
        MainstreamBrowsePagePresenter.new(tag)
      when 'archived'
        ArchivedTagPresenter.new(tag)
      end
    when Topic
      case tag.state
      when 'published', 'draft'
        TopicPresenter.new(tag)
      when 'archived'
        ArchivedTagPresenter.new(tag)
      end
    else
      raise ArgumentError, "Unexpected tag type #{tag.class}"
    end
  end

  def initialize(tag)
    @tag = tag
  end


  def content_id
    tag.content_id
  end

  def render_for_rummager
    {
      content_id: tag.content_id,
      format: rummager_format,
      title: tag.title,
      description: tag.description,
      link: tag.base_path,
      slug: tag.full_slug,
    }
  end

  def render_for_publishing_api
    {
      base_path: base_path,
      document_type: format,
      schema_name: format,
      title: @tag.title,
      description: @tag.description,
      locale: 'en',
      need_ids: [],
      public_updated_at: @tag.updated_at.iso8601,
      publishing_app: "collections-publisher",
      rendering_app: "collections",
      routes: routes,
      redirects: RedirectRoutePresenter.new(@tag).routes,
      details: details,
    }.merge(phase_state)
  end


  def render_links_for_publishing_api
    {
      links: links
    }
  end

  def render_for_panopticon
    {
      content_id: tag.content_id,
      description: tag.description,
      parent_id: parent.slug,
      tag_id: tag_id,
      tag_type: legacy_tag_type,
      title: tag.title,
    }
  end

  def routes
    [{ path: base_path, type: "exact" }] + subroutes
  end

private

  def phase_state
    return {} unless @tag.beta?
    { phase: "beta" }
  end

  def format
    raise "Need to subclass"
  end

  def subroutes
    @tag.subroutes.map do |suffix|
      { path: "#{base_path}#{suffix}", type: "exact" }
    end
  end

  # potentially extended in subclasses
  def details
    {
      :groups => categorized_groups,
      :internal_name => tag.title_including_parent,
    }
  end

  # Groups aren't calculated each time we publish the item, we use a rendered
  # hash from the tags instead. This allows us to independently update the
  # item, without having to publish these groups.
  def categorized_groups
    tag.published_groups
  end

  def links
    if @tag.has_parent?
      {
        "parent" => [@tag.parent.content_id],
      }
    else
      {
        "children" => @tag.children.order(:title).map(&:content_id),
      }
    end
  end

  attr_reader :tag

  def parent
    tag.parent || NullParent.new
  end

  def tag_id
    parent.present? ? "#{parent.slug}/#{tag.slug}" : tag.slug
  end

  class NullParent
    def present?
      false
    end

    def slug
      nil
    end
  end
end
