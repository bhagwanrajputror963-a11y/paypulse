require 'rails_helper'

RSpec.describe 'Api::V1::Employees', type: :request do
  let(:body) { JSON.parse(response.body) }
  let(:headers) { { 'CONTENT_TYPE' => 'application/json' } }
  let(:valid_params) do
    {
      employee: {
        full_name: 'John Doe',
        email: 'john@example.com',
        job_title: 'Software Engineer',
        country: 'India',
        salary: 75_000.00,
        currency: 'USD',
        employment_status: 'active',
        date_of_joining: '2023-01-15'
      }
    }
  end

  describe 'POST /api/v1/employees' do
    it 'creates an employee with valid data and returns 201' do
      post '/api/v1/employees', params: valid_params.to_json, headers: headers

      expect(response).to have_http_status(:created)
      expect(body['success']).to be(true)
      expect(body['data']['employee']['full_name']).to eq('John Doe')
      expect(body['data']['employee']['email']).to eq('john@example.com')
      expect(body['data']['employee']['id']).to be_present
    end

    it 'returns 422 with validation errors when required fields are missing' do
      post '/api/v1/employees', params: { employee: { currency: 'USD' } }.to_json, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(body['success']).to be(false)
      expect(body['errors']).to include(/full name/i)
      expect(body['errors']).to include(/salary/i)
    end

    it 'returns 422 when email is already taken' do
      create(:employee, email: 'john@example.com')

      post '/api/v1/employees', params: valid_params.to_json, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(body['errors']).to include(/email/i)
    end

    it 'returns 422 when email format is invalid' do
      invalid = valid_params.deep_merge(employee: { email: 'not-an-email' })

      post '/api/v1/employees', params: invalid.to_json, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 400 when params are empty' do
      post '/api/v1/employees', params: {}.to_json, headers: headers

      expect(response).to have_http_status(:bad_request)
      expect(response.content_type).to include('application/json')
    end
  end

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

  describe 'PATCH /api/v1/employees/:id' do
    let!(:employee) { create(:employee, full_name: 'Old Name') }

    it 'updates the employee and returns the updated record' do
      patch "/api/v1/employees/#{employee.id}", params: { employee: { full_name: 'New Name' } }.to_json, headers: headers

      expect(response).to have_http_status(:ok)
      expect(body['data']['employee']['full_name']).to eq('New Name')
    end

    it 'returns 422 when update violates validation' do
      patch "/api/v1/employees/#{employee.id}", params: { employee: { salary: -1 } }.to_json, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 422 when updating email to one already taken' do
      create(:employee, email: 'taken@example.com')

      patch "/api/v1/employees/#{employee.id}", params: { employee: { email: 'taken@example.com' } }.to_json, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 404 for non-existent employee' do
      patch '/api/v1/employees/999999', params: { employee: { full_name: 'Ghost' } }.to_json, headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE /api/v1/employees/:id' do
    it 'deletes the employee and returns 204' do
      employee = create(:employee)

      expect { delete "/api/v1/employees/#{employee.id}" }.to change(Employee, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it 'returns 404 for non-existent employee' do
      delete '/api/v1/employees/999999'

      expect(response).to have_http_status(:not_found)
    end
  end
end
