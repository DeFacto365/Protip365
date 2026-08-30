const { withAppBuildGradle } = require('expo/config-plugins');

const SENTINEL = '// PROTIP365_EXTERNAL_RELEASE_SIGNING';

module.exports = function withExternalReleaseSigning(config) {
  return withAppBuildGradle(config, (mod) => {
    if (mod.modResults.language !== 'groovy') return mod;
    let contents = mod.modResults.contents;
    if (contents.includes(SENTINEL)) return mod;

    const signingConfig = `        release {
            def uploadStoreFile = System.getenv('PROTIP365_UPLOAD_STORE_FILE')
            def uploadStorePassword = System.getenv('PROTIP365_UPLOAD_STORE_PASSWORD')
            def uploadKeyAlias = System.getenv('PROTIP365_UPLOAD_KEY_ALIAS')
            def uploadKeyPassword = System.getenv('PROTIP365_UPLOAD_KEY_PASSWORD')
            if (uploadStoreFile && uploadStorePassword && uploadKeyAlias && uploadKeyPassword) {
                storeFile file(uploadStoreFile)
                storePassword uploadStorePassword
                keyAlias uploadKeyAlias
                keyPassword uploadKeyPassword
            }
        }
`;
    contents = contents.replace('    signingConfigs {\n', `    signingConfigs {\n${signingConfig}`);
    contents = contents.replace(
      '            signingConfig signingConfigs.debug\n            def enableShrinkResources',
      '            signingConfig signingConfigs.release\n            def enableShrinkResources'
    );
    contents += `

${SENTINEL}
gradle.taskGraph.whenReady { graph ->
    def releaseRequested = graph.allTasks.any { task ->
        task.name == 'bundleRelease' || task.name == 'assembleRelease'
    }
    if (releaseRequested) {
        def required = [
            System.getenv('PROTIP365_UPLOAD_STORE_FILE'),
            System.getenv('PROTIP365_UPLOAD_STORE_PASSWORD'),
            System.getenv('PROTIP365_UPLOAD_KEY_ALIAS'),
            System.getenv('PROTIP365_UPLOAD_KEY_PASSWORD')
        ]
        if (required.any { !it }) {
            throw new GradleException('ProTip365 release signing environment is not configured.')
        }
    }
}
`;
    mod.modResults.contents = contents;
    return mod;
  });
};
