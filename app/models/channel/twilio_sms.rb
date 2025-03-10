# == Schema Information
#
# Table name: channel_twilio_sms
#
#  id           :bigint           not null, primary key
#  account_sid  :string           not null
#  auth_token   :string           not null
#  medium       :integer          default("sms")
#  phone_number :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :integer          not null
#
# Indexes
#
#  index_channel_twilio_sms_on_account_id_and_phone_number  (account_id,phone_number) UNIQUE
#

class Channel::TwilioSms < ApplicationRecord
  self.table_name = 'channel_twilio_sms'

  validates :account_id, presence: true
  validates :account_sid, presence: true
  validates :auth_token, presence: true
  validates :phone_number, uniqueness: { scope: :account_id }, presence: true

  enum medium: { sms: 0, whatsapp: 1 }

  belongs_to :account

  has_one :inbox, as: :channel, dependent: :destroy

  def name
    'Twilio SMS'
  end
end
