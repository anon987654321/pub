# frozen_string_literal: true

# encoding: utf-8

require_relative 'main'
module Assistants
  class TinderAssistant < ChatbotAssistant
    def initialize(openai_api_key)
      super(openai_api_key)
      @browser = Ferrum::Browser.new
      puts '💖 TinderAssistant initialized. Swipe right to success!'
    end
    def fetch_user_info(user_id)
      profile_url = 'https://tinder.com/@#{user_id}'
      puts '🔍 Checking out #{profile_url}. It’s a digital love fest!'
      super(user_id, profile_url)
    def send_message(user_id, message, message_type)
      puts '🌟 Visiting #{profile_url} to send a message. Let’s make sparks fly!'
      @browser.goto(profile_url)
      css_classes = fetch_dynamic_css_classes(@browser.body, @browser.screenshot(base64: true), 'send_message')
      if message_type == :text
        puts '✍️ Sending a love note: #{message}'
        @browser.at_css(css_classes['textarea']).send_keys(message)
        @browser.at_css(css_classes['submit_button']).click
      else
        puts '📸 Media? That’s not in my Tinder repertoire. Swipe left on media!'
      end
    def engage_with_new_friends
      @browser.goto('https://tinder.com/app/recs')
      css_classes = fetch_dynamic_css_classes(@browser.body, @browser.screenshot(base64: true), 'new_friends')
      new_friends = @browser.css(css_classes['rec_card'])
      new_friends.each do |friend|
        engage_with_user(friend[:id], 'https://tinder.com/@#{friend[:id]}')
    def fetch_dynamic_css_classes(html, screenshot, action)
      puts '🎨 Discovering CSS classes for #{action}. Fashion week for code!'
      prompt = 'Given the following HTML and screenshot, identify the CSS classes used for the #{action} action: #{html} #{screenshot}'
      response = @langchain_openai.generate_answer(prompt)
      JSON.parse(response)
  end
end