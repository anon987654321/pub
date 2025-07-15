# frozen_string_literal: true

require 'replicate'
require 'aws-sdk-s3'
require 'open-uri'
require 'fileutils'

S3_BUCKET_NAME = 'la2'
AWS_REGION = 'eu-north-1'
AWS_ACCESS_KEY_ID = ENV.fetch('AWS_ACCESS_KEY_ID', nil)
AWS_SECRET_ACCESS_KEY = ENV.fetch('AWS_SECRET_ACCESS_KEY', nil)

REPLICATE_API_KEY = ENV.fetch('REPLICATE_API_KEY', nil)
REPLICATE_MODEL_NAME = 'nightmareai/real-esrgan'

s3 =
  Aws::S3::Resource.new(
    region: AWS_REGION,
    access_key_id: AWS_ACCESS_KEY_ID,
    secret_access_key: AWS_SECRET_ACCESS_KEY
  )
bucket = s3.bucket(S3_BUCKET_NAME)

Replicate.configure { |config| config.api_token = REPLICATE_API_KEY }

def upload_to_s3(file, bucket)
  name = File.basename(file)
  obj = bucket.object(name)
  obj.upload_file(file)
  obj.public_url
end

def fetch_prediction(prediction)
  loop do
    prediction.refetch
    break if prediction.finished?

    puts 'Sleeping 30 seconds while waiting for image...'
    sleep 30
  end
end

def download_file(uri_str, output_file)
  URI.open(uri_str) do |uri|
    File.binwrite(output_file, uri.read)
  end
end

puts "Retrieving model #{REPLICATE_MODEL_NAME}..."
model = Replicate.client.retrieve_model(REPLICATE_MODEL_NAME)
version = model.latest_version
puts 'Model retrieved.'

input_folder = ARGV[0] || Dir.pwd
output_folder = ARGV[1] || Dir.pwd

FileUtils.mkdir_p(output_folder) unless File.directory?(output_folder)

Dir.glob(File.join(input_folder, '*.png')) do |file|
  puts "Processing file: #{file} ..."
  image_url = upload_to_s3(file, bucket)
  puts "Uploaded to S3: #{image_url}"

  prediction = version.predict(image: image_url)
  puts 'Predicting...'
  fetch_prediction(prediction)
  puts 'Prediction finished.'

  output_file =
    File.join(output_folder, "#{File.basename(file, '.png')}_output.png")
  download_file(prediction.output, output_file)
  puts "Output file saved as: #{output_file}"
end
