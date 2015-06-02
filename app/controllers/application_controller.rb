class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  include GDS::SSO::ControllerMethods
  before_filter :require_signin_permission!

private

  helper_method :gds_editor?

  def gds_editor?
    current_user.has_permission? "GDS Editor"
  end

  def require_gds_editor_permissions!
    authorise_user!("GDS Editor")
  end

  def require_gds_editor_permissions_to_edit_browse_pages!
    require_gds_editor_permissions! if @tag.is_a?(MainstreamBrowsePage)
  end

  def find_tag
    @tag = Tag.find_by!(content_id: params[:tag_id])
  end
end
