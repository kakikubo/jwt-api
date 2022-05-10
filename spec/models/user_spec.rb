# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe User, type: :model do
  describe 'バリデーション' do
    let(:user) { active_user }
    it '名前入力必須である事を検証する' do
      user = User.new(email: 'test@example.com', password: 'password')
      user.save
      required_msg = ['名前を入力してください']
      expect(user.errors.full_messages).to eq(required_msg)
    end

    it '文字数制限は30文字まで' do
      max = 30
      name = 'a' * (max + 1)
      user.name = name
      user.save
      maxlength_msg = ['名前は30文字以内で入力してください']
      expect(user.errors.full_messages).to eq(maxlength_msg)
    end

    it '30文字以内のユーザは保存できている' do
      max = 30
      user.name = 'あ' * max
      # expect {
      #   user.save
      # }.to change(User, :count).by(1)

      user.save
      expect(user).to be_valid
    end
  end

  describe 'emailのバリデーション' do
    let(:user) { active_user }
    it '入力必須' do
      user = User.new(name: 'test', password: 'password')
      user.save
      required_msg = ['メールアドレスを入力してください']
      expect(user.errors.full_messages).to eq(required_msg)
    end
    it '文字数制限は255文字まで' do
      max = 255
      domain = '@example.com'
      email = 'a' * (max + 1 - domain.length) + domain
      assert max < email.length
      user.email = email
      user.save
      maxlength_msg = ['メールアドレスは255文字以内で入力してください']
      expect(user.errors.full_messages).to eq(maxlength_msg)
    end
  end
end
# rubocop:enable Metrics/BlockLength
