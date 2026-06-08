Cloudinary.config do |config|
  config.cloud_name = "dzraqjvp9"
  config.api_key    = Rails.application.credentials.cloudinary[:api_key]
  config.api_secret = Rails.application.credentials.cloudinary[:api_secret]
  config.secure     = true
end
