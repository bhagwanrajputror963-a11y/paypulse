module Api
  module V1
    class SalaryAnalyticsController < ApplicationController
      before_action -> { require_param!(:country) }, only: %i[stats_by_country]

      def stats_by_country
        render_resource(SalaryAnalyticsService.stats_by_country(analytics_params[:country]))
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
