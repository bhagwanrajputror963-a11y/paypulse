module Api
  module V1
    class EmployeesController < ApplicationController
      before_action :set_employee, only: %i[show]

      def index
        render_resource(Employee.order(:id), key: :employees, paginate: true)
      end

      def show
        render_employee(@employee)
      end

      private

      def set_employee
        @employee = Employee.find(params[:id])
      end

      def render_employee(employee, status: :ok)
        render_resource(employee, key: :employee, status: status)
      end
    end
  end
end
