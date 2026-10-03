const http=require('node:http');
const fs=require('node:fs');
const path=require('node:path');
const root=path.resolve(__dirname,'../dist-web');
const types={'.html':'text/html','.js':'text/javascript','.ttf':'font/ttf','.ico':'image/x-icon','.json':'application/json'};
http.createServer((req,res)=>{
  try {
    const pathname=decodeURIComponent(new URL(req.url,'http://localhost').pathname);
    const file=path.resolve(root,'.'+(pathname==='/'?'/index.html':pathname));
    if(!file.startsWith(root+path.sep)){res.writeHead(403);res.end();return;}
    fs.readFile(file,(error,data)=>{res.writeHead(error?404:200,{'Content-Type':types[path.extname(file)]||'application/octet-stream'});res.end(error?'Not found':data);});
  } catch {res.writeHead(400);res.end();}
}).listen(8083,'127.0.0.1',()=>process.stdout.write('ProTip365 web preview: http://127.0.0.1:8083/\n'));
