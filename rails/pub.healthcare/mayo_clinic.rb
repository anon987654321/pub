# frozen_string_literal: true

puts "Creating hospital representation..."

module PubHealthcare
  class Hospital
    DEPARTMENTS = [
      {
        name: "Cardiology",
        subcategories: [
          "Interventional Cardiology",
          "Electrophysiology",
          "Cardiac Imaging"
        ],
        description: "Diagnosis, treatment, and management of heart diseases and abnormalities."
      },
      {
        name: "Neurology",
        subcategories: [
          "Stroke",
          "Epilepsy",
          "Movement Disorders",
          "Neuromuscular Disorders"
        ],
        description: "Diagnosis and treatment of disorders affecting the brain, spinal cord, and nervous system."
      },
      {
        name: "Oncology",
        subcategories: [
          "Medical Oncology",
          "Surgical Oncology",
          "Radiation Oncology",
          "Hematology"
        ],
        description: "Diagnosis and treatment of cancer, including medical, surgical, and radiation therapies."
      },
      {
        name: "Gastroenterology",
        subcategories: [
          "Gastrointestinal Endoscopy",
          "Hepatology",
          "Inflammatory Bowel Disease",
          "Pancreatic Disorders"
        ],
        description: "Diagnosis and treatment of diseases and disorders of the digestive system, including liver conditions."
      },
      {
        name: "Endocrinology",
        subcategories: [
          "Diabetes",
          "Thyroid Disorders",
          "Pituitary Disorders",
          "Metabolic Disorders"
        ],
        description: "Diagnosis and management of hormone-related disorders, including diabetes, thyroid conditions, and metabolic disorders."
      },
      {
        name: "Nephrology",
        subcategories: [
          "Renal Transplantation",
          "Dialysis",
          "Glomerular Diseases",
          "Hypertension"
        ],
        description: "Diagnosis and treatment of kidney diseases and conditions, including transplantation and dialysis."
      },
      {
        name: "Pulmonology",
        subcategories: [
          "Sleep Medicine",
          "Pulmonary Hypertension",
          "Interstitial Lung Diseases",
          "Cystic Fibrosis"
        ],
        description: "Diagnosis and treatment of lung and respiratory disorders, including sleep-related conditions."
      },
      {
        name: "Orthopedics",
        subcategories: [
          "Joint Replacement",
          "Sports Medicine",
          "Spine Surgery",
          "Pediatric Orthopedics"
        ],
        description: "Diagnosis and treatment of musculoskeletal conditions, injuries, and disorders, including joint replacement and sports-related injuries."
      },
      {
        name: "Dermatology",
        subcategories: [
          "Mohs Surgery",
          "Cosmetic Dermatology",
          "Dermatopathology",
          "Pediatric Dermatology"
        ],
        description: "Diagnosis and treatment of skin conditions, including surgical procedures and cosmetic dermatology."
      },
      {
        name: "Ophthalmology",
        subcategories: [
          "Cornea and External Diseases",
          "Retina and Vitreous",
          "Glaucoma",
          "Pediatric Ophthalmology"
        ],
        description: "Diagnosis and treatment of eye diseases and disorders, including surgeries and pediatric ophthalmology."
      },
      {
        name: "Otorhinolaryngology",
        subcategories: [
          "Head and Neck Surgery",
          "Otology and Neurotology",
          "Rhinology",
          "Laryngology"
        ],
        description: "Diagnosis and treatment of ear, nose, and throat conditions, including surgeries for head and neck disorders."
      }
    ].freeze

    CATEGORIES = [
      {
        name: "Immunology",
        description: "Information about the immune system, autoimmune diseases, allergies, and the latest research in immunology."
      },
      {
        name: "Rheumatology",
        description: "Articles on rheumatic diseases, arthritis, lupus, gout, and other conditions affecting the joints and connective tissues."
      },
      {
        name: "Infectious Diseases",
        description: "Information about infectious diseases, including prevention, treatment, and the latest research on viruses, bacteria, and other pathogens."
      },
      {
        name: "Genetics and Genomics",
        description: "Insights into the field of genetics and genomics, including genetic testing, inherited conditions, and the latest research on genes and DNA."
      },
      {
        name: "Medical Imaging",
        description: "Information about medical imaging techniques like X-rays, MRI, CT scans, and ultrasound, and how they are used in diagnosis and treatment."
      },
      {
        name: "Surgery Techniques",
        description: "Articles on different types of surgery, including minimally invasive procedures, robotic surgery, and the latest advancements in surgical techniques."
      },
      {
        name: "Rehabilitation Medicine",
        description: "Information about physical medicine and rehabilitation, including therapies and exercises for patients recovering from injuries, surgery, or chronic conditions."
      }
    ].freeze
  end
end

PubHealthcare::DEPARTMENTS.each do |department_data|
  department = Department.create(name: department_data[:name], description: department_data[:description])

  department_data[:subcategories].each do |subcategory_name|
    department.subcategories.create(name: subcategory_name)
  end
end

puts "Creating blogging platform content..."

PubHealthcare::CATEGORIES.each do |category_data|
  Category.create(name: category_data[:name], description: category_data[:description])
end
