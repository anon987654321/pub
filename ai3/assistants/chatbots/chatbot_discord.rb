# frozen_string_literal: true

# encoding: utf-8

require_relative 'main'
module Assistants
  class DiscordAssistant < ChatbotAssistant
    def initialize(openai_api_key)
      super(openai_api_key)
      @browser = Ferrum::Browser.new
    end
    def fetch_user_info(user_id)
      profile_url = 'https://discord.com/users/#{user_id}'
      super(user_id, profile_url)
    def send_message(user_id, message, message_type)
      @browser.goto(profile_url)
      css_classes = fetch_dynamic_css_classes(@browser.body, @browser.screenshot(base64: true), 'send_message')
      if message_type == :text
        @browser.at_css(css_classes['textarea']).send_keys(message)
        @browser.at_css(css_classes['submit_button']).click
      else
        puts 'Sending media is not supported in this implementation.'
      end
    def engage_with_new_friends
      @browser.goto('https://discord.com/channels/@me')
      css_classes = fetch_dynamic_css_classes(@browser.body, @browser.screenshot(base64: true), 'new_friends')
      new_friends = @browser.css(css_classes['friend_card'])
      new_friends each do |friend|
        add_friend(friend[:id])
        engage_with_user(friend[:id], 'https://discord.com/users/#{friend[:id]}')
    def fetch_dynamic_css_classes(html, screenshot, action)
      prompt = 'Given the following HTML and screenshot, identify the CSS classes used for the #{action} action: #{html} #{screenshot}'
      response = @langchain_openai.generate_answer(prompt)
      JSON.parse(response)
  end
end