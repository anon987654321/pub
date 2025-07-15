# frozen_string_literal: true

require "replicate"
require "aws-sdk-s3"
require "open-uri"
require "fileutils"

# § Run Real Esrgan

S3_BUCKET_NAME = "la2"
AWS_REGION = "eu-north-1"
AWS_ACCESS_KEY_ID = ENV["AWS_ACCESS_KEY_ID"]
AWS_SECRET_ACCESS_KEY = ENV["AWS_SECRET_ACCESS_KEY"]

REPLICATE_API_KEY = ENV["REPLICATE_API_KEY"]
REPLICATE_MODEL_NAME = "nightmareai/real-esrgan"

s3 =
  Aws::S3::Resource.new(
    region: AWS_REGION,
    access_key_id: AWS_ACCESS_KEY_ID,
    secret_access_key: AWS_SECRET_ACCESS_KEY
  )
bucket = s3.bucket(S3_BUCKET_NAME)

Replicate.configure { |config| config.api_token = REPLICATE_API_KEY }

def upload_to_s3(file, bucket)
  begin
    name = File.basename(file)
    object = bucket.object(name)
    obj.upload_file(file)
    obj.public_url
  rescue StandardError => e
    # TODO: Add proper error handling
    raise e
  end
end

def fetch_prediction(prediction)
  begin
    loop do
      prediction.refetch
      break if prediction.finished?
  
      puts "Sleeping 30 seconds while waiting for image..."
      sleep 30
    end
  rescue StandardError => e
    # TODO: Add proper error handling
    raise e
  end
end

def download_file(uri_str, output_file)
  begin
    URI.open(uri_str) do |uri|
      File.open(output_file, "wb") { |file| file.write(uri.read) }
    end
  rescue StandardError => e
    # TODO: Add proper error handling
    raise e
  end
end

puts "Retrieving model #{ REPLICATE_MODEL_NAME }..."
model = Replicate.client.retrieve_model(REPLICATE_MODEL_NAME)
version = model.latest_version
puts "Model retrieved."

input_folder = ARGV[0] || Dir.pwd
output_folder = ARGV[1] || Dir.pwd

FileUtils.mkdir_p(output_folder) unless File.directory?(output_folder)

Dir.glob(File.join(input_folder, "*.png")) do |file|
  puts "Processing file: #{ file } ..."
  image_url = upload_to_s3(file, bucket)
  puts "Uploaded to S3: #{ image_url }"

  prediction = version.predict(image: image_url)
  puts "Predicting..."
  fetch_prediction(prediction)
  puts "Prediction finished."

  output_file =
    File.join(output_folder, "#{ File.basename(file, '.png') }_output.png")
  download_file(prediction.output, output_file)
  puts "Output file saved as: #{ output_file }"
end