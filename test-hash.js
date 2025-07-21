// Test hash generation
const password = '@Dopeboi24';
const salt = 'Db2';
const combinedString = password + salt;
console.log('Hash input:', combinedString);
console.log('Generated hash:', CryptoJS.SHA256(combinedString).toString());
