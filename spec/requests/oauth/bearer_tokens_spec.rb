require 'rails_helper'

RSpec.describe 'OAuth bearer token requests', type: :request do
  let(:request_path) { '/example.json' }
  context 'with valid access token' do
    with :access_token
    let(:headers) do
      {
        'Authorization' => "Bearer #{access_token.token}"
      }
    end
    let(:params) { {} }
    before do
      @original_timestamp = User.find(access_token.resource_owner_id).last_sign_in_at
      get request_path, params, headers
    end
    it { expect(response.status).to eq 200 }
    it 'does not send Set-Cookie headers' do
      expect(response.headers).to_not include 'Set-Cookie'
    end
    it 'does not update the user last_signin_at timestamp' do
      new_timestamp = User.find(access_token.resource_owner_id).last_sign_in_at
      expect(new_timestamp).to eq @original_timestamp
    end
  end
  context 'with expired access token' do
    with :access_token, expires_in: 0
    let(:headers) do
      {
        'Authorization' => "Bearer #{access_token.token}"
      }
    end
    let(:params) { {} }
    before do
      get request_path, params, headers
    end
    it { expect(response.status).to eq 401 }
    it { expect(response.headers['WWW-Authenticate']).to eq 'Bearer realm="DeviseDoorkeeperApp", error="invalid_token", error_description="The access token is invalid"' }
    it { expect(response.body).to eq '{"error":"invalid_token","error_description":"The access token is invalid","state":"unauthorized"}' }
  end
  context 'with revoked access token' do
    with :access_token, revoked_at: 1.year.ago
    let(:headers) do
      {
        'Authorization' => "Bearer #{access_token.token}"
      }
    end
    let(:params) { {} }
    before do
      get request_path, params, headers
    end
    it { expect(response.status).to eq 401 }
  end
  context 'with invalid access token' do
    let(:access_token) { double(:fake_token, token: 'invalid') }
    let(:headers) do
      {
        'Authorization' => "Bearer #{access_token.token}"
      }
    end
    let(:params) { {} }
    before do
      get request_path, params, headers
    end
    it { expect(response.status).to eq 401 }
  end
end
