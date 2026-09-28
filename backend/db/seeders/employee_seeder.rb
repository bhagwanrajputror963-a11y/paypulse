class EmployeeSeeder
  BATCH_SIZE = 1_000
  TOTAL = 10_000
  DATA_PATH = Rails.root.join('db/data/fixtures').freeze

  def call
    countries = read_json('countries.json')
    job_titles = read_json('job_titles.json')
    first_names = read_lines('first_names.txt')
    last_names = read_lines('last_names.txt')

    fn_size = first_names.size
    ln_size = last_names.size
    job_size = job_titles.size

    now = Time.current

    puts("[EmployeeSeeder] Starting — target #{TOTAL} employees, batch #{BATCH_SIZE}")
    Employee.delete_all if Rails.env.development?

    TOTAL.times.each_slice(BATCH_SIZE).with_index do |batch, batch_index|
      country, currency = countries[batch_index].values
      ActiveRecord::Base.transaction do
        records = batch.map do |i|
          job_title = job_titles[i % job_size]

          {
            full_name: "#{first_names[i % fn_size]} #{last_names[i % ln_size]}",
            email: "employee_#{i}@paypulse.com",
            job_title: job_title,
            country: country,
            salary: rand(30_000..250_000).round(2),
            currency: currency,
            employment_status: 'active',
            date_of_joining: Date.today - rand(1..1825),
            created_at: now,
            updated_at: now
          }
        end

        Employee.upsert_all(records, unique_by: :index_employees_on_lower_email)
        puts("[EmployeeSeeder] Upserted batch #{batch_index + 1} (#{records.size} records)")
      end
    end

    puts("[EmployeeSeeder] Done — #{Employee.count} employees seeded")
  end

  private

  def read_lines(filename)
    File.readlines(DATA_PATH.join(filename)).map(&:strip)
  end

  def read_json(filename)
    JSON.parse(File.read(DATA_PATH.join(filename)))
  end
end
