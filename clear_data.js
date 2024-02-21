// 利用 iso-4 标准检查 ./src/modules/data.js 中的数据, 
// 如果 iso-4 标准得出的数据与 ./src/modules/data.js 中的数据不一致,则保留 ./src/modules/data.js 中的数据
// 如果 iso-4 标准得出的数据与 ./src/modules/data.js 中的数据一致,则清空 ./src/modules/data.js 中的数据
// 这样做的目的是减少 ./src/modules/data.js 中的数据量, 以便减少内存占用


const fs = require('fs');
// const path = require('path');

// 0.查看工作目录
console.log("当前工作目录" + process.cwd());



// 1. 把 data_new.ts 复制到 data_new.js, 并在末位添加 module.exports = { journal_abbr };
file = './data_new.ts' 
destFile = './data_new.js';
fs.copyFileSync(file, destFile);
fs.appendFileSync(destFile, '\n module.exports = { journal_abbr };', 'utf8');


// 1.加载 data.js
let { journal_abbr } = require('./data_new.js');


// 2. 加载 iso4 标准

let AbbrevIso = require('./iso4/nodeBundle.js');
let ltwa = fs.readFileSync('./iso4/LTWA_20170914-modified.csv', 'utf8');
let shortWords = fs.readFileSync('./iso4/shortwords.txt', 'utf8');
let abbrevIso = new AbbrevIso.AbbrevIso(ltwa, shortWords);



// let s = 'International Journal of Geographical Information Science';
// console.log(abbrevIso.makeAbbreviation(s));
// s = "autonomous robots"; 
// console.log(abbrevIso.makeAbbreviation(s));
// 3. 对比数据 
const keys = Object.keys(journal_abbr);
const toDelete = [];
const klength = keys.length;

for (let i = 0; i < klength; i++) {
  const key = keys[i];
  let value = journal_abbr[key];
  value = value.toLowerCase().trim();
  let abbr = abbrevIso.makeAbbreviation(key).toLowerCase().trim();
  
  if (abbr === value) {
    toDelete.push(key);
  }
  
  // 显示一个进度条
  if (i % 1000 === 0) {
    console.log(`进度: ${i} / ${klength}`);
  }
}

// 删除条目
for (let i = 0; i < toDelete.length; i++) {
  delete journal_abbr[toDelete[i]];
}

console.log(`已删除${toDelete.length}个条目。`);






// 4. 保存数据

let jsContent = `const journal_abbr = ${JSON.stringify(journal_abbr, null, 2)}; \n 
export { journal_abbr };
`;
fs.writeFileSync('datanew.js', jsContent, 'utf8');



