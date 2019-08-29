class AddStatusToStepByStepPage < ActiveRecord::Migration[5.2]
  def change
    add_column :step_by_step_pages, :state, :string, default: "draft", null: false
  end
end
