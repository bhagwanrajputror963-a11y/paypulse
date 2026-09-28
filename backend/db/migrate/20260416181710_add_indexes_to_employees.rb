class AddIndexesToEmployees < ActiveRecord::Migration[8.0]
  def change
    add_index :employees, :country
    add_index :employees, :job_title
    add_index :employees, %i[country job_title]
    add_index :employees, %i[country job_title salary]
    add_index :employees, :employment_status
    add_index :employees, %i[email country job_title employment_status],
              name: 'idx_employees_email_country_title_status'
  end
end
