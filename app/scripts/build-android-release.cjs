// Local upload-key build. Credentials are read outside Git and passed only through the child environment.
const fs = require('fs'), path = require('path'), {spawnSync} = require('child_process');
const root = path.resolve(__dirname,'..'), env = {...process.env};
const keystore = env.PROTIP_UPLOAD_KEYSTORE, note = env.PROTIP_UPLOAD_CREDENTIAL_NOTE;
if (!keystore || !note) throw Error('Set PROTIP_UPLOAD_KEYSTORE and PROTIP_UPLOAD_CREDENTIAL_NOTE to the recovered files outside the repository.');
const lines = fs.readFileSync(note,'utf8').split(/\r?\n/), label = lines.findIndex(x=>x.trim()==='Store password (same as key password):');
const password = label < 0 ? null : lines.slice(label+1).find(x=>x.trim())?.trim();
if (!password) throw Error('The credential note does not contain the documented password label.');
Object.assign(env,{PROTIP_STORE_FILE:path.resolve(keystore),PROTIP_STORE_PASSWORD:password,PROTIP_KEY_ALIAS:'protip365-upload',PROTIP_KEY_PASSWORD:password});
function run(cmd,args,cwd=root){const p=spawnSync(cmd,args,{cwd,env,stdio:'inherit'}); if(p.status!==0)throw Error(`${cmd} failed (${p.status})`);}
if (process.argv.includes('--reuse-native')) {
  const config = JSON.parse(fs.readFileSync(path.join(root, 'app.json'), 'utf8')).expo;
  const generated = fs.readFileSync(path.join(root, 'android/app/build.gradle'), 'utf8');
  if (!generated.includes(`applicationId '${config.android.package}'`) || !generated.includes(`versionCode ${config.android.versionCode}`)) throw Error('Native package/version differs from app.json; run without --reuse-native.');
} else run('npx',['expo','prebuild','--platform','android','--no-install']);
const gradlePath=path.join(root,'android/app/build.gradle');let gradle=fs.readFileSync(gradlePath,'utf8');
const sign=`upload {\n            storeFile file(System.getenv('PROTIP_STORE_FILE'))\n            storePassword System.getenv('PROTIP_STORE_PASSWORD')\n            keyAlias System.getenv('PROTIP_KEY_ALIAS')\n            keyPassword System.getenv('PROTIP_KEY_PASSWORD')\n        }`;
if (gradle.includes("System.getenv('PROTIP_STORE_FILE')") && gradle.includes('signingConfig signingConfigs.upload')) {
  // Expo retains generated native customizations on repeated local builds.
} else {
if (!gradle.includes('signingConfigs {') || !/release\s*\{[\s\S]*?signingConfig signingConfigs\.debug/.test(gradle)) throw Error('Unexpected generated signing configuration.');
gradle=gradle.replace('signingConfigs {',`signingConfigs {\n        ${sign}`).replace(/(release\s*\{[\s\S]*?signingConfig signingConfigs\.)debug/,'$1upload');fs.writeFileSync(gradlePath,gradle);
}
run('./gradlew',['bundleRelease','--max-workers=2','-Dorg.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=1536m'],path.join(root,'android'));
const artifact=path.join(root,'android/app/build/outputs/bundle/release/app-release.aab');
run(path.join(env.JAVA_HOME,'bin/jarsigner'),['-verify',artifact]);
const cert=spawnSync(path.join(env.JAVA_HOME,'bin/keytool'),['-printcert','-jarfile',artifact],{env,encoding:'utf8'});
const fingerprint='2E:A5:53:BD:B0:15:31:C4:D3:D6:AE:EA:08:68:B6:C3:0C:5A:F3:DF:EA:B4:AA:40:80:96:EB:4F:47:98:6F:16';
if(cert.status!==0 || !cert.stdout.includes(fingerprint)) throw Error('Built AAB does not match the registered upload certificate.');
console.log('Signed Android bundle verified against the registered upload certificate:', artifact);
