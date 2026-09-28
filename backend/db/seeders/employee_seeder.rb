class EmployeeSeeder
  BATCH_SIZE = 1_000
  TOTAL = 10_000
  DATA_PATH = Rails.root.join('db/data/fixtures').freeze

  # Uneven headcount per country so Headcount/Workforce-Distribution charts
  # aren't a flat 1,000-per-country line. Must sum to TOTAL.
  COUNTRY_WEIGHTS = {
    'India' => 2200,
    'USA' => 1600,
    'UK' => 1100,
    'Brazil' => 850,
    'Germany' => 900,
    'Canada' => 800,
    'Japan' => 750,
    'Australia' => 700,
    'Singapore' => 600,
    'France' => 500
  }.freeze

  # Salary hierarchy by job title so "Average Salary by Job Title" isn't flat
  # random noise. Every entry in job_titles.json must have a range here.
  JOB_TITLE_SALARY_RANGES = {
    'Intern' => 20_000..40_000,
    'Coordinator' => 35_000..55_000,
    'Analyst' => 45_000..75_000,
    'Designer' => 55_000..100_000,
    'Engineer' => 60_000..110_000,
    'Consultant' => 70_000..130_000,
    'Lead' => 90_000..150_000,
    'Manager' => 100_000..170_000,
    'Architect' => 120_000..190_000,
    'Director' => 150_000..250_000
  }.freeze

  def call
    countries = read_json('countries.json')
    job_titles = read_json('job_titles.json')
    first_names = read_lines('first_names.txt')
    last_names = read_lines('last_names.txt')
    currency_by_country = countries.each_with_object({}) { |c, h| h[c['name']] = c['currency'] }

    raise "COUNTRY_WEIGHTS must sum to #{TOTAL}" unless COUNTRY_WEIGHTS.values.sum == TOTAL
    unless (job_titles - JOB_TITLE_SALARY_RANGES.keys).empty?
      raise "JOB_TITLE_SALARY_RANGES missing entries for: #{job_titles - JOB_TITLE_SALARY_RANGES.keys}"
    end

    fn_size = first_names.size
    ln_size = last_names.size
    job_size = job_titles.size

    now = Time.current

    puts("[EmployeeSeeder] Starting — target #{TOTAL} employees, batch #{BATCH_SIZE}")
    Employee.delete_all if Rails.env.development?

    global_index = 0
    batch_number = 0

    COUNTRY_WEIGHTS.each do |country, headcount|
      currency = currency_by_country.fetch(country)

      headcount.times.each_slice(BATCH_SIZE) do |batch|
        batch_number += 1

        ActiveRecord::Base.transaction do
          records = batch.map do
            i = global_index
            global_index += 1
            job_title = job_titles[i % job_size]

            {
              full_name: "#{first_names[i % fn_size]} #{last_names[i % ln_size]}",
              email: "employee_#{i}@paypulse.com",
              job_title: job_title,
              country: country,
              salary: rand(JOB_TITLE_SALARY_RANGES.fetch(job_title)).round(2),
              currency: currency,
              employment_status: 'active',
              date_of_joining: Date.today - rand(1..1825),
              created_at: now,
              updated_at: now
            }
          end

          Employee.upsert_all(records, unique_by: :index_employees_on_lower_email)
          puts("[EmployeeSeeder] Upserted batch #{batch_number} (#{records.size} records, #{country})")
        end
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
