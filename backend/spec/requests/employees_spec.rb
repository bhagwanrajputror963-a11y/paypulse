require 'rails_helper'

RSpec.describe 'Api::V1::Employees', type: :request do
  let(:body) { JSON.parse(response.body) }

  describe 'GET /api/v1/employees' do
    context 'with employees' do
      before do
        create(:employee, full_name: 'Amit Sharma', country: 'India', salary: 50_000)
        create(:employee, full_name: 'Priya Patel', country: 'India', salary: 60_000)
        create(:employee, full_name: 'John Smith', country: 'USA', salary: 90_000)
      end

      it 'returns paginated employees with meta information' do
        get '/api/v1/employees'

        expect(response).to have_http_status(:ok)
        expect(body['data']['employees'].length).to eq(3)
        expect(body['meta']).to include('total_count', 'total_pages', 'current_page', 'per_page')
      end

      it 'caps per_page at 100 regardless of requested value' do
        get '/api/v1/employees', params: { per_page: 999 }

        expect(body['meta']['per_page']).to be <= 100
      end

      it 'respects page and per_page parameters' do
        get '/api/v1/employees', params: { page: 1, per_page: 2 }

        expect(body['data']['employees'].length).to eq(2)
        expect(body['meta']['current_page']).to eq(1)
        expect(body['meta']['per_page']).to eq(2)
      end
    end

    context 'with no employees' do
      it 'returns empty list with valid meta when no results match' do
        get '/api/v1/employees'

        expect(body['data']['employees']).to eq([])
        expect(body['meta']['total_count']).to eq(0)
      end
    end
  end

  describe 'GET /api/v1/employees/:id' do
    it 'returns the employee' do
      employee = create(:employee, full_name: 'Jane Doe')

      get "/api/v1/employees/#{employee.id}"

      expect(response).to have_http_status(:ok)
      expect(body['data']['employee']['full_name']).to eq('Jane Doe')
    end

    it 'returns 404 for non-existent employee' do
      get '/api/v1/employees/999999'

      expect(response).to have_http_status(:not_found)
      expect(response.content_type).to include('application/json')
    end
  end
end
