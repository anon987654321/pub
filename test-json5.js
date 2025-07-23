#!/usr/bin/env node

const fs = require('fs');
const JSON5 = require('json5');

function testJSON5(filePath) {
    try {
        const content = fs.readFileSync(filePath, 'utf8');
        const parsed = JSON5.parse(content);
        console.log('✅ JSON5 file is valid');
        console.log(`📊 Found ${Object.keys(parsed).length} top-level properties`);
        return true;
    } catch (error) {
        console.log('❌ JSON5 file is invalid');
        console.log('Error:', error.message);
        return false;
    }
}

if (process.argv.length < 3) {
    console.log('Usage: node test-json5.js <file-path>');
    process.exit(1);
}

const filePath = process.argv[2];
testJSON5(filePath);