class AddIsProjectAdministratorToProjectMembers < ActiveRecord::Migration[4.2]
  def change
    add_column :project_members, :is_project_administrator, :boolean
  end
end
