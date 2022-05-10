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
      maxlength_msg = ["メールアドレスは#{max}文字以内で入力してください"]
      expect(user.errors.full_messages).to eq(maxlength_msg)
    end

    it '正しい書式は保存できているか' do
      ok_emails = %w[
        A@EX.COM
        a-_@e-x.c-o_m.j_p
        a.a@ex.com
        a@e.co.js
        1.1@ex.com
        a.a+a@ex.com
      ]
      ok_emails.each do |email|
        user.email = email
        # assert user.save
        expect(user).to be_valid
      end
    end
    it '間違った書式はエラーを吐いているか' do
      ng_emails = %w[
        aaa
        a.ex.com
        メール@ex.com
        a~a@ex.com
        a@|.com
        a@ex.
        .a@ex.com
        a＠ex.com
        Ａ@ex.com
        a@?,com
        １@ex.com
        "a"@ex.com
        a@ex@co.jp
      ]
      ng_emails.each do |email|
        user.email = email
        user.save
        format_msg = ['メールアドレスは不正な値です']
        expect(user.errors.full_messages).to eq(format_msg)
      end
    end

    it 'email小文字化テスト' do
      email = 'USER@EXAMPLE.COM'
      user = User.new(email:)
      user.save
      expect(user.email).to eq('user@example.com')
    end
  end
end
# rubocop:enable Metrics/BlockLength
