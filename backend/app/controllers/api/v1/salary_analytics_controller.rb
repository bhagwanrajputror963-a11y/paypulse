module Api
  module V1
    class SalaryAnalyticsController < ApplicationController
      before_action -> { require_param!(:country) }, only: %i[stats_by_country average_by_job_title]

      def stats_by_country
        render_resource(SalaryAnalyticsService.stats_by_country(analytics_params[:country]))
      end

      def average_by_job_title
        result = SalaryAnalyticsService.average_by_job_title(
          analytics_params[:country],
          analytics_params[:job_title]
        )

        render_resource(result)
      end

      def salary_summary_by_country
        render_resource(SalaryAnalyticsService.salary_summary_by_country, key: :countries)
      end

      private

      def analytics_params
        params.permit(:country, :job_title)
      end

      def require_param!(key)
        return if params[key].present?

        render_error("#{key} param is required", status: :bad_request)
      end
    end
  end
end
