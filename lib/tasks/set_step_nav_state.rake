namespace :step_by_step do
  desc "Add a status to all current step by step pages"
  task :set_state => :environment do
    StepByStepPage.all.each do |step_by_step_page|
      if step_by_step_page.scheduled_for_publishing?
        step_by_step_page.update_attributes(state: "scheduled")
      elsif step_by_step_page.unpublished_changes?
        step_by_step_page.update_attributes(state: "draft")
      elsif step_by_step_page.has_been_published?
        step_by_step_page.update_attributes(state: "published")
      else
        step_by_step_page.update_attributes(state: "draft")
      end
    end
  end
end
