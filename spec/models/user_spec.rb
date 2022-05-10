# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'バリデーション' do
    let(:user) { active_user }
    it '名前入力必須である事を検証する' do
      user = User.new(email: 'test@example.com', password: 'password')
      user.save
      required_msg = ['名前を入力してください']
      expect(required_msg).to eq(user.errors.full_messages)
    end

    it '文字数制限は30文字まで' do
      max = 30
      name = 'a' * (max + 1)
      user.name = name
      user.save
      maxlength_msg = ['名前は30文字以内で入力してください']
      expect(maxlength_msg).to eq(user.errors.full_messages)
    end
  end
end
