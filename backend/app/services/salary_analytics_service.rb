class SalaryAnalyticsService
  def self.stats_by_country(country)
    result = Employee.by_country(country)
                     .pick(Arel.sql('MIN(salary), MAX(salary), AVG(salary), COUNT(*)'))

    { min: result[0]&.to_f, max: result[1]&.to_f, average: result[2]&.to_f&.round(2), count: result[3] || 0 }
  end

  def self.average_by_job_title(country, job_title = nil)
    titles = Employee.by_country(country)
                     .group(:job_title)
                     .average(:salary)
                     .sort_by { |_k, v| -v }
                     .map { |job, avg| { job_title: job, average_salary: avg.to_f.round(2) } }

    average = job_title.present? ? titles.find { |t| t[:job_title] == job_title }&.dig(:average_salary) : nil

    { average: average, titles: titles }
  end
end
