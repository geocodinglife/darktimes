const fs = require('fs')
let app_name = process.argv[2]

const someFile = `${app_name}/${app_name}_web/src/index.js`
// const someFile = `suso4/suso4_web/src/index.js`

fs.readFile(someFile, 'utf8', function (err, data) {
 if (err) {
   return console.log(err);
 }
 let result = data.replace('./App', './views/App');
 // let result1 = data.replace('./index.css', './stylesheets/index.css');

 fs.writeFile(someFile, result, 'utf8', function (err) {
    if (err) return console.log(err);
 });

 // fs.writeFile(someFile, result1, 'utf8', function (err) {
 //    if (err) return console.log(err);
 // });
});
