# Pagy initializer file
require 'pagy/extras/bootstrap'
require 'pagy/extras/overflow'

# Pagy vars
Pagy::DEFAULT[:items] = 10
Pagy::DEFAULT[:size] = [1, 4, 4, 1]
Pagy::DEFAULT[:overflow] = :last_page

# Enable responsive CSS
Pagy::DEFAULT[:bootstrap_responsive_css] = true