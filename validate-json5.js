#!/usr/bin/env node

const fs = require('fs');
const JSON5 = require('json5');

function validateJSON5File(filePath) {
    try {
        const content = fs.readFileSync(filePath, 'utf8');
        const parsed = JSON5.parse(content);
        
        console.log('✅ JSON5 file is valid');
        console.log(`📊 Found ${Object.keys(parsed).length} top-level properties`);
        
        // Check for key sections
        const requiredSections = [
            'meta', 'universal_standards', 'behavioral_rules', 'principles', 
            'web_development', 'design_system', 'business_strategy', 
            'autonomous_completion', 'core', 'execution', 'formatting'
        ];
        
        const missingSections = requiredSections.filter(section => !parsed[section]);
        if (missingSections.length > 0) {
            console.log('❌ Missing required sections:', missingSections);
            return false;
        }
        
        console.log('✅ All required sections present');
        
        // Check that behavioral rules exist
        if (parsed.behavioral_rules && parsed.behavioral_rules.core_rules) {
            const coreRulesCount = Object.keys(parsed.behavioral_rules.core_rules).length;
            console.log(`✅ Found ${coreRulesCount} behavioral rules`);
        }
        
        // Check that universal standards exist
        if (parsed.universal_standards) {
            const standardsCount = Object.keys(parsed.universal_standards).length - 1; // minus description
            console.log(`✅ Found ${standardsCount} universal standard categories`);
        }
        
        // Check for comments (JSON5 allows comments)
        const commentCount = (content.match(/\/\//g) || []).length + (content.match(/\/\*/g) || []).length;
        console.log(`✅ Found ${commentCount} comments in JSON5 format`);
        
        // Check that no comment properties remain (but allow "comments" as config)
        const commentProps = content.match(/"[^"]*_.*comment[^"]*":/g);
        if (commentProps && commentProps.length > 0) {
            console.log('⚠️  Found remaining comment properties:', commentProps);
        } else {
            console.log('✅ No comment properties remain - all converted to JSON5 comments');
        }
        
        return true;
        
    } catch (error) {
        console.log('❌ JSON5 file is invalid');
        console.log('Error:', error.message);
        return false;
    }
}

if (process.argv.length < 3) {
    console.log('Usage: node validate-json5.js <file-path>');
    process.exit(1);
}

const filePath = process.argv[2];
const isValid = validateJSON5File(filePath);
process.exit(isValid ? 0 : 1);