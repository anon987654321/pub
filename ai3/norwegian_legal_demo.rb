#!/usr/bin/env ruby
# frozen_string_literal: true

# Norwegian Legal Document Processing Demo
# This script demonstrates the enhanced lawyer assistant capabilities

require_relative 'assistants/lawyer_assistant'

puts "🏛️ Norwegian Legal Document Processing Demo\n\n"

# Sample case data
target = { name: 'Klient AS' }
case_data = {
  case_type: 'employment contract dispute',
  key_facts: ['Potential breach of employment contract', 'Termination without proper notice'],
  communication_history: [
    { id: 1, text: 'I am concerned about this employment issue' },
    { id: 2, text: 'The employer seems to be acting unfairly' }
  ]
}

puts "Creating Norwegian Legal Assistant..."
ENV['TEST_ENV'] = 'true' # Use mock implementations for demo
lawyer = LawyerAssistant.new(target, case_data)

puts "\n📋 Case Overview:"
puts "Client: #{target[:name]}"
puts "Case Type: #{case_data[:case_type]}"
puts "Key Facts: #{case_data[:key_facts].join(', ')}"

puts "\n🏛️ Norwegian Legal System Features:"
puts "Courts: #{LawyerAssistant::NORWEGIAN_COURTS[:supreme_court]} (Supreme), #{LawyerAssistant::NORWEGIAN_COURTS[:appeal_courts].first} (Appeal)"
puts "Law Areas: #{LawyerAssistant::NORWEGIAN_LAW_AREAS.keys.join(', ')}"

puts "\n📄 Document Processing Capabilities:"
begin
  # Process documents from docs directory
  docs_results = lawyer.process_legal_documents_from_docs
  puts "Found #{docs_results.size} legal documents"
  
  docs_results.each do |doc|
    puts "- #{File.basename(doc[:path])}: #{doc[:type]} (#{doc[:risk_assessment]&.size || 0} risks)"
  end
rescue StandardError => e
  puts "Document processing demo: #{e.message}"
end

puts "\n🔍 Norwegian Legal Research:"
begin
  research = lawyer.research_norwegian_law('employment dispute')
  puts "Query: #{research[:query]}"
  puts "Relevant Laws: #{research[:relevant_laws]&.join(', ')}"
  puts "Recommendations: #{research[:recommendations]&.size || 0} recommendations"
rescue StandardError => e
  puts "Legal research demo: #{e.message}"
end

puts "\n⚖️ Norwegian Legal Citations:"
statute_ref = {
  type: :statute,
  law_name: 'Arbeidsmiljøloven',
  date: '2005-06-17',
  number: '62'
}

court_ref = {
  type: :court_decision,
  court: 'Høyesterett',
  year: '2023',
  page: '456'
}

puts "Statute Citation: #{lawyer.generate_norwegian_citation(statute_ref)}"
puts "Court Citation: #{lawyer.generate_norwegian_citation(court_ref)}"

puts "\n💡 Legal Analysis Sample:"
sample_content = "arbeidskontrakt med ansvar og erstatning ved mislighold"
terms = lawyer.extract_legal_terms(sample_content)
puts "Legal Terms Found: #{terms.join(', ')}"

risks = lawyer.assess_legal_risks(sample_content)
puts "Risk Assessment: #{risks.join(', ')}" if risks.any?

puts "\n📊 Full Norwegian Legal Report:"
puts "=" * 60
begin
  report = lawyer.generate_full_report
  puts report[0..500] + "..." # Show first 500 characters
rescue StandardError => e
  puts "Report generation demo: #{e.message}"
end

puts "\n✅ Demo completed successfully!"
puts "\nThis demo showcases:"
puts "• Norwegian law specialization"
puts "• Legal document processing from docs/ directory"
puts "• Lovdata.no integration capabilities"
puts "• Norwegian legal citation system"
puts "• Risk assessment and compliance checking"
puts "• Comprehensive legal reporting"