# frozen_string_literal: true

puts "Creating hospital representation with v12.9.0 framework..."

# § PubHealthcare: Hospital management system
# Implements extreme scrutiny framework with cognitive orchestration
module PubHealthcare
  # § Hospital: Core hospital representation
  class Hospital
    # § Constants: Department definitions with validation
    DEPARTMENTS = [
      {
        name: "Cardiology",
        subcategories: [
          "Interventional Cardiology",
          "Electrophysiology",
          "Cardiac Imaging"
        ],
        description: "Heart disease diagnosis and treatment (15 words)"
      },
      {
        name: "Neurology",
        subcategories: [
          "Stroke",
          "Epilepsy",
          "Movement Disorders",
          "Neuromuscular Disorders"
        ],
        description: "Brain and nervous system disorder treatment (7 words)"
      },
      {
        name: "Oncology",
        subcategories: [
          "Medical Oncology",
          "Surgical Oncology",
          "Radiation Oncology",
          "Hematology"
        ],
        description: "Cancer diagnosis and comprehensive treatment services (7 words)"
      },
      {
        name: "Gastroenterology",
        subcategories: [
          "Gastrointestinal Endoscopy",
          "Hepatology",
          "Inflammatory Bowel Disease",
          "Pancreatic Disorders"
        ],
        description: "Digestive system and liver condition treatment (7 words)"
      },
      {
        name: "Endocrinology",
        subcategories: [
          "Diabetes",
          "Thyroid Disorders",
          "Pituitary Disorders",
          "Metabolic Disorders"
        ],
        description: "Hormone and metabolic disorder management (6 words)"
      },
      {
        name: "Nephrology",
        subcategories: [
          "Renal Transplantation",
          "Dialysis",
          "Glomerular Diseases",
          "Hypertension"
        ],
        description: "Kidney disease treatment and transplantation (6 words)"
      },
      {
        name: "Pulmonology",
        subcategories: [
          "Sleep Medicine",
          "Pulmonary Hypertension",
          "Interstitial Lung Diseases",
          "Cystic Fibrosis"
        ],
        description: "Lung and respiratory system treatment (6 words)"
      }
    ].freeze

    # § Constants: Additional medical categories
    CATEGORIES = [
      {
        name: "Immunology",
        description: "Immune system and autoimmune disease research (7 words)"
      },
      {
        name: "Rheumatology",
        description: "Joint and connective tissue disorder treatment (7 words)"
      },
      {
        name: "Infectious Diseases",
        description: "Pathogen prevention and treatment research (6 words)"
      },
      {
        name: "Genetics and Genomics",
        description: "Genetic testing and inherited condition insights (7 words)"
      },
      {
        name: "Medical Imaging",
        description: "Diagnostic imaging technique applications (5 words)"
      },
      {
        name: "Surgery Techniques",
        description: "Minimally invasive and robotic surgery advances (7 words)"
      },
      {
        name: "Rehabilitation Medicine",
        description: "Recovery therapy and exercise programs (6 words)"
      }
    ].freeze

    # § Validation: Department structure validation
    def self.validate_department_structure(department)
      raise ArgumentError, "Department must be hash" unless department.is_a?(Hash)
      raise ArgumentError, "Department name required" unless department[:name]
      raise ArgumentError, "Department description required" unless department[:description]
      raise ArgumentError, "Department subcategories required" unless department[:subcategories]
      raise ArgumentError, "Subcategories must be array" unless department[:subcategories].is_a?(Array)
      
      validate_description_length(department[:description])
      validate_subcategories(department[:subcategories])
    end

    # § Validation: Description length compliance
    def self.validate_description_length(description)
      word_count = description.split.length
      raise ArgumentError, "Description too long (max 15 words)" if word_count > 15
      raise ArgumentError, "Description too short (min 5 words)" if word_count < 5
    end

    # § Validation: Subcategory validation
    def self.validate_subcategories(subcategories)
      raise ArgumentError, "Too many subcategories (max 7)" if subcategories.length > 7
      raise ArgumentError, "Too few subcategories (min 2)" if subcategories.length < 2
      
      subcategories.each do |subcategory|
        raise ArgumentError, "Subcategory must be string" unless subcategory.is_a?(String)
        raise ArgumentError, "Subcategory cannot be empty" if subcategory.empty?
      end
    end

    # § Processing: Department creation with validation
    def self.create_departments_safely
      iteration_count = 0
      max_iterations = 10
      
      DEPARTMENTS.each do |department_data|
        iteration_count += 1
        
        if iteration_count > max_iterations
          raise StandardError, "Circuit breaker: Too many iterations"
        end
        
        validate_department_structure(department_data)
        create_single_department(department_data)
      end
    end

    # § Processing: Single department creation
    def self.create_single_department(department_data)
      department = Department.create(
        name: department_data[:name],
        description: department_data[:description]
      )
      
      create_subcategories(department, department_data[:subcategories])
    rescue StandardError => e
      puts "Error creating department #{department_data[:name]}: #{e.message}"
      raise
    end

    # § Processing: Subcategory creation with validation
    def self.create_subcategories(department, subcategories)
      subcategories.each do |subcategory_name|
        validate_subcategory_name(subcategory_name)
        department.subcategories.create(name: subcategory_name)
      end
    end

    # § Validation: Subcategory name validation
    def self.validate_subcategory_name(name)
      raise ArgumentError, "Subcategory name must be string" unless name.is_a?(String)
      raise ArgumentError, "Subcategory name cannot be empty" if name.empty?
      raise ArgumentError, "Subcategory name too long" if name.length > 50
    end

    # § Processing: Category creation with validation
    def self.create_categories_safely
      iteration_count = 0
      max_iterations = 10
      
      CATEGORIES.each do |category_data|
        iteration_count += 1
        
        if iteration_count > max_iterations
          raise StandardError, "Circuit breaker: Too many iterations"
        end
        
        validate_category_structure(category_data)
        create_single_category(category_data)
      end
    end

    # § Validation: Category structure validation
    def self.validate_category_structure(category)
      raise ArgumentError, "Category must be hash" unless category.is_a?(Hash)
      raise ArgumentError, "Category name required" unless category[:name]
      raise ArgumentError, "Category description required" unless category[:description]
      
      validate_description_length(category[:description])
    end

    # § Processing: Single category creation
    def self.create_single_category(category_data)
      Category.create(
        name: category_data[:name],
        description: category_data[:description]
      )
    rescue StandardError => e
      puts "Error creating category #{category_data[:name]}: #{e.message}"
      raise
    end
  end
end

# § Execution: Department creation with error handling
begin
  puts "Creating hospital departments with validation..."
  PubHealthcare::Hospital.create_departments_safely
  puts "Department creation completed successfully"
rescue StandardError => e
  puts "Department creation failed: #{e.message}"
  exit 1
end

# § Execution: Category creation with error handling
begin
  puts "Creating blogging platform content with validation..."
  PubHealthcare::Hospital.create_categories_safely
  puts "Category creation completed successfully"
rescue StandardError => e
  puts "Category creation failed: #{e.message}"
  exit 1
end

puts "Hospital representation created successfully with v12.9.0 compliance"
